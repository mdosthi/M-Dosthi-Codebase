"""
agents/longitudinal/profile_update_agent.py
---------------------------------------------
Final node in the longitudinal pipeline. Runs after delta_agent and
longitudinal_sanity_agent.

Responsibilities:
  1. Enrich the DatasetRow with longitudinal metadata
  2. Build the LongitudinalAnnotation (full multi-session output)
  3. Create a SessionRecord from the completed DatasetRow
  4. Append the SessionRecord to the PatientProfile
  5. Persist the updated PatientProfile via PatientMemory
"""
from __future__ import annotations

from typing import Dict, Any

from annotate.agents.memory import PatientMemory
from annotate.utils.logger import log, warning, log_data
from annotate.schemas.longitudinal_schema import LongitudinalAnnotation


def profile_update_agent(
    state: Dict[str, Any],
    patient_memory: PatientMemory,
) -> Dict[str, Any]:
    profile      = state.get("patient_profile")
    dataset_row  = state.get("dataset_row", {})
    delta        = state.get("session_delta")
    long_sanity  = state.get("longitudinal_sanity", {})
    conversation = state.get("chat", "")
    conv_id      = state.get("conversation_id")

    if profile is None:
        log("profile_update_agent: no patient_profile in state — skipping.")
        return {}

    session_number = profile.session_count + 1
    log(f"profile_update_agent: finalising session {session_number} for '{profile.patient_id}'")

    # Merge pre-session and sanity flags into the DatasetRow
    all_flags = state.get("longitudinal_flags", []) + long_sanity.get("flags", [])
    dataset_row["session_number"]             = session_number
    dataset_row["longitudinal_flags"]         = all_flags
    dataset_row["longitudinal_sanity_passed"] = long_sanity.get("passed", False)  # fail-safe default

    if delta:
        dataset_row["stage_direction"]          = delta.get("stage_direction", "unknown")
        dataset_row["new_triggers"]             = delta.get("new_triggers", [])
        dataset_row["resolved_triggers"]        = delta.get("resolved_triggers", [])
        dataset_row["new_concerns"]             = delta.get("new_concerns", [])
        dataset_row["resolved_concerns"]        = delta.get("resolved_concerns", [])
        dataset_row["new_interventions"]        = delta.get("new_interventions", [])
        dataset_row["continuing_interventions"] = delta.get("continuing_interventions", [])
        dataset_row["dropped_interventions"]    = delta.get("dropped_interventions", [])
        dataset_row["clinical_summary"]         = delta.get("clinical_summary", "")

    # _overall_progress reads pre-update profile history — must run before append_session
    overall_progress = _overall_progress(profile, delta)

    # delta_agent may have corrected an "unknown" stage; prefer its stage_after
    resolved_stage = (
        delta.get("stage_after", dataset_row.get("stage_of_change", "unknown"))
        if delta else dataset_row.get("stage_of_change", "unknown")
    )

    long_output = LongitudinalAnnotation(
        patient_id=profile.patient_id,
        session_number=session_number,
        current_annotation=dataset_row,
        delta=delta,
        stage_trajectory=profile.stage_trajectory + [resolved_stage],
        persistent_triggers=profile.persistent_triggers,
        persistent_concerns=profile.persistent_concerns,
        interventions_tried=profile.interventions_tried,
        relapse_detected=delta.get("relapse_detected", False) if delta else False,
        stagnation_detected=delta.get("stagnation_detected", False) if delta else False,
        overall_progress=overall_progress,
        longitudinal_flags=all_flags,
    )

    record = PatientMemory.build_session_record(
        dataset_row=dataset_row,
        conversation=conversation,
        conversation_id=conv_id,
        all_triggers=state.get("triggers", {}).get("triggers", []),
        all_concerns=state.get("concern", {}).get("concerns", []),
    )

    profile = patient_memory.append_session(profile, record)

    try:
        patient_memory.save(profile)
    except Exception as exc:
        warning(f"profile_update_agent: save failed — {exc}")

    log(
        f"profile_update_agent: done | trajectory={profile.stage_trajectory} | "
        f"stagnation={profile.stagnation_count} | overall={overall_progress}"
    )

    payload = {
        "dataset_row":         dataset_row,
        "longitudinal_output": long_output.model_dump(),
        "patient_profile":     profile,
    }
    log_data("profile_update_agent.output", {
        "dataset_row":          dataset_row,
        "longitudinal_output":  long_output.model_dump(),
        "patient_id":           profile.patient_id,
        "session_count":        profile.session_count,
    })
    return payload


def _overall_progress(profile, delta) -> str:
    """Classify the patient's overall trajectory across all sessions to date."""
    history = list(profile.stage_direction_history)
    if delta:
        history.append(delta.get("stage_direction", "stable"))

    if not history:
        return "unknown"

    # "relapse" is a stage name, not a direction label — detect it via session records
    recent_sessions = profile.sessions[-3:] if profile.sessions else []
    recent_relapse  = any(getattr(s, "stage_of_change", "") == "relapse" for s in recent_sessions)
    if recent_relapse or (delta and delta.get("relapse_detected", False)):
        return "relapse"

    recent           = history[-3:]
    progress_count   = recent.count("progress") + recent.count("recovery")
    regression_count = recent.count("regression")
    stable_count     = recent.count("stable")

    if progress_count > regression_count:
        return "improving"
    if regression_count > progress_count:
        return "regression"
    if stable_count == len(recent):
        return "stable"
    return "mixed"

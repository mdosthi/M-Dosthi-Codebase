"""
agents/longitudinal/delta_agent.py
----------------------------------
Computes the ``SessionDelta`` between the previous session (N-1) and the
current session (N).

The agent uses a two-phase approach:

1. **Structural diff** — deterministic Python that compares stages, triggers,
   concerns, quit-attempt history, and interventions. This phase is always
   correct, even if phase 2 fails.
2. **Clinical narrative** — an LLM call that interprets the structural diff
   into a human-readable clinical summary. On failure, a deterministic
   fallback narrative is produced instead.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from annotate.agents.longitudinal.delta_helpers import (
    _compute_delta,
    _fallback_narrative,
    _normalise_set,
)
from annotate.llm.json_parser import repair_json
from annotate.llm.router import call_llm
from annotate.schemas.longitudinal_schema import (
    STAGE_ORDER,
    SessionDelta,
    stage_direction,
)
from annotate.utils.logger import log, log_data, warning
from annotate.utils.prompt_loader import format_prompt, load_prompt

# Quit-history values treated as "no information".
_EMPTY_QUIT_VALUES = ("", "unknown")


def delta_agent(state: Dict[str, Any]) -> Dict[str, Any]:
    """Compute the longitudinal delta between the previous and current session.

    Args:
        state: Pipeline state. Relevant keys:
            - ``patient_profile``: ``PatientProfile`` holding all prior
              sessions, cumulative signals, and stage trajectory.
            - ``dataset_row``: dict for the current session
              (``stage_of_change``, ``all_concerns``, ``all_triggers``,
              ``quit_attempt_history``, ``recommended_intervention``, ...).
            - ``chat``: current session transcript.
            - ``trigger`` / ``concern``: extracted signals for this session.

    Returns:
        A payload containing the serialised ``session_delta`` plus
        carried-forward ``cumulative_triggers`` and ``cumulative_concerns``
        for the profile-update step. ``session_delta`` is ``None`` when there
        is no prior session to compare against.
    """
    profile = state.get("patient_profile")
    current_row: Dict[str, Any] = state.get("dataset_row", {})

    # A delta requires at least one prior session.
    if profile is None or profile.session_count == 0:
        log("delta_agent: no prior session — skipping.")
        return {"session_delta": None}

    prev = profile.sessions[-1]
    current_n = profile.session_count + 1
    transcript: str = state.get("chat", "")
    log(f"delta_agent: session {prev.session_number} → {current_n}")

    # ------------------------------------------------------------------ #
    # Phase 1 — structural diff                                          #
    # ------------------------------------------------------------------ #
    stage_before, stage_after = _resolve_stages(prev.stage_of_change, current_row)
    direction = stage_direction(stage_before, stage_after)

    new_triggers, persistent_triggers, resolved_triggers = _compute_delta(
        signal_type="trigger",
        prev=list(_normalise_set(prev.all_triggers)),
        curr=list(_normalise_set(state.get("trigger", {}).get("triggers", []))),
        transcript=transcript,
    )

    new_concerns, persistent_concerns, resolved_concerns = _compute_delta(
        signal_type="concern",
        prev=list(_normalise_set(prev.all_concerns)),
        curr=list(_normalise_set(state.get("concern", {}).get("concerns", []))),
        transcript=transcript,
    )

    new_quit_attempts, cumulative_quit_history = _diff_quit_history(
        prev_quit=prev.quit_attempt_history or "",
        curr_quit=current_row.get("quit_attempt_history", "") or "",
    )

    # The transcript lets the helper drop an intervention only when the
    # session explicitly indicates it is no longer required;
    # ``continuing_interventions`` is the updated cumulative list.
    new_interventions, continuing_interventions, dropped_interventions = _compute_delta(
        signal_type="intervention",
        prev=list(_normalise_set(prev.recommended_intervention)),
        curr=list(_normalise_set(current_row.get("recommended_intervention", []))),
        transcript=transcript,
    )

    relapse_detected, rapid_progress, stagnation = _detect_clinical_flags(
        stage_before=stage_before,
        stage_after=stage_after,
        direction=direction,
        stagnation_count=profile.stagnation_count,
    )

    # ------------------------------------------------------------------ #
    # Phase 2 — clinical narrative                                       #
    # ------------------------------------------------------------------ #
    clinical_summary = _generate_narrative(
        prev_session=prev,
        current_row=current_row,
        current_n=current_n,
        stage_before=stage_before,
        stage_after=stage_after,
        direction=direction,
        new_triggers=new_triggers,
        resolved_triggers=resolved_triggers,
        new_concerns=new_concerns,
        resolved_concerns=resolved_concerns,
        new_interventions=new_interventions,
        cumulative_quit_history=cumulative_quit_history,
    )

    # ------------------------------------------------------------------ #
    # Assemble output                                                    #
    # ------------------------------------------------------------------ #
    delta = SessionDelta(
        from_session=prev.session_number,
        to_session=current_n,
        from_date=prev.session_date,
        stage_before=stage_before,
        stage_after=stage_after,
        stage_changed=(stage_before != stage_after),
        stage_direction=direction,
        new_triggers=new_triggers,
        resolved_triggers=resolved_triggers,
        persistent_triggers=persistent_triggers,
        new_concerns=new_concerns,
        resolved_concerns=resolved_concerns,
        persistent_concerns=persistent_concerns,
        new_quit_attempts=new_quit_attempts,
        cumulative_quit_history=cumulative_quit_history,
        new_interventions=new_interventions,
        continuing_interventions=continuing_interventions,
        dropped_interventions=dropped_interventions,
        relapse_detected=relapse_detected,
        rapid_progress_detected=rapid_progress,
        stagnation_detected=stagnation,
        concern_shift_detected=bool(new_concerns or resolved_concerns),
        trigger_resolved=bool(resolved_triggers),
        clinical_summary=clinical_summary,
    )

    log(
        f"delta_agent: {stage_before} → {stage_after} ({direction}) | "
        f"new_triggers={new_triggers} | resolved={resolved_triggers} | "
        f"relapse={relapse_detected}"
    )

    payload = {
        "session_delta": delta.model_dump(),
        # Carried-forward signal lists for the profile-update step:
        # everything still active this session (persistent + newly observed).
        "cumulative_triggers": persistent_triggers + new_triggers,
        "cumulative_concerns": persistent_concerns + new_concerns,
    }
    log_data("delta_agent.output", payload)
    return payload


# ---------------------------------------------------------------------- #
# Helpers                                                                #
# ---------------------------------------------------------------------- #
def _resolve_stages(
    stage_before: str,
    current_row: Dict[str, Any],
) -> Tuple[str, str]:
    """Resolve the (before, after) stage pair for the diff.

    Falls back to the previous stage when the current one is missing or
    "unknown", so ``stage_direction`` always compares two real stages.
    """
    stage_after = current_row.get("stage_of_change") or stage_before
    if stage_after == "unknown":
        stage_after = stage_before
    return stage_before, stage_after


def _diff_quit_history(prev_quit: str, curr_quit: str) -> Tuple[List[str], str]:
    """Diff quit-attempt history and accumulate new information.

    Both histories are "; "-separated lists of discrete attempts (per the
    consensus prompt). Everything already known is carried forward; only
    genuinely new information is appended.

    Returns:
        ``(new_quit_attempts, cumulative_quit_history)``
    """
    prev_list = (
        [item.strip().lower() for item in prev_quit.split("; ") if item.strip()]
        if prev_quit not in _EMPTY_QUIT_VALUES else []
    )
    curr_list = (
        [item.strip().lower() for item in curr_quit.split("; ") if item.strip()]
        if curr_quit not in _EMPTY_QUIT_VALUES else []
    )

    new_quit_attempts, persistent, _ = _compute_delta(
        signal_type="quit_attempt",
        prev=prev_list,
        curr=curr_list,
        transcript="",
    )

    cumulative = "; ".join(persistent) if persistent else "unknown"

    return new_quit_attempts, cumulative


def _detect_clinical_flags(
    stage_before: str,
    stage_after: str,
    direction: str,
    stagnation_count: int,
) -> Tuple[bool, bool, bool]:
    """Derive clinical alert flags from the stage transition.

    Returns:
        ``(relapse_detected, rapid_progress_detected, stagnation_detected)``
    """
    relapse_detected = stage_after == "relapse"

    before_order = STAGE_ORDER.get(stage_before, -2)
    after_order = STAGE_ORDER.get(stage_after, -2)
    rapid_progress = (
        direction == "progress"
        and before_order >= 0
        and after_order >= 0
        and (after_order - before_order) > 1
    )

    stagnation = direction == "stable" and stagnation_count >= 2

    return relapse_detected, rapid_progress, stagnation


def _generate_narrative(
    *,
    prev_session: Any,
    current_row: Dict[str, Any],
    current_n: int,
    stage_before: str,
    stage_after: str,
    direction: str,
    new_triggers: List[str],
    resolved_triggers: List[str],
    new_concerns: List[str],
    resolved_concerns: List[str],
    new_interventions: List[str],
    cumulative_quit_history: str,
) -> str:
    """Generate the LLM clinical narrative, falling back deterministically.

    The structural diff (phase 1) is never affected by a failure here.
    """
    try:
        prompt = format_prompt(
            load_prompt("longitudinal.delta_narrative"),
            n_minus_1=prev_session.session_number,
            n=current_n,
            stage_before=stage_before,
            stage_after=stage_after,
            concerns_before=_join_or_none(prev_session.all_concerns),
            concerns_after=_join_or_none(current_row.get("all_concerns", [])),
            triggers_before=_join_or_none(prev_session.all_triggers),
            triggers_after=_join_or_none(current_row.get("all_triggers", [])),
            interventions_before=_join_or_none(prev_session.recommended_intervention),
            interventions_after=_join_or_none(
                current_row.get("recommended_intervention", [])
            ),
            stage_direction=direction,
            new_triggers=_join_or_none(new_triggers),
            resolved_triggers=_join_or_none(resolved_triggers),
            new_concerns=_join_or_none(new_concerns),
            resolved_concerns=_join_or_none(resolved_concerns),
            new_interventions=_join_or_none(new_interventions),
            cumulative_quit_history=cumulative_quit_history or "none",
        )
        return repair_json(call_llm(prompt)).get("clinical_summary", "")
    except Exception as exc:  # noqa: BLE001 — narrative must never break the diff
        warning(f"delta_agent: narrative call failed — {exc}.")
        return _fallback_narrative(
            stage_before,
            stage_after,
            direction,
            new_triggers,
            resolved_triggers,
            new_concerns,
        )


def _join_or_none(items: Optional[List[str]]) -> str:
    """Join a list for prompt interpolation, or return ``"none"`` if empty."""
    return ", ".join(items) if items else "none"
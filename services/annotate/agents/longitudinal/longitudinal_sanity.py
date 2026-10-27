"""
agents/longitudinal/longitudinal_sanity.py
--------------------------------------------
Cross-session consistency checker. Runs after delta_agent.

Rules:
  1. Stage skip > 1 step forward (likely extraction error)
  2. Relapse annotated but no relapse language in conversation
  3. Previously tried intervention re-recommended without acknowledgment
  4. Prolonged stagnation: 4+ consecutive stable sessions
  5. Severe regression: action/maintenance → contemplation or earlier
  6. Trigger unaddressed for 3+ sessions without targeted intervention
  7. Concern contradicts annotated stage
"""
from __future__ import annotations

from typing import Dict, Any, List

from annotate.utils.logger import log, log_data
from annotate.schemas.longitudinal_schema import STAGE_ORDER


def longitudinal_sanity_agent(state: Dict[str, Any]) -> Dict[str, Any]:
    profile      = state.get("patient_profile")
    delta        = state.get("session_delta")
    current_row  = state.get("dataset_row", {})
    conversation = state.get("chat", "").lower()

    if profile is None or profile.session_count == 0 or delta is None:
        log("longitudinal_sanity: first session — skipping.")
        return _result(flags=[], passed=True)

    flags: List[str] = []

    before_order = STAGE_ORDER.get(delta.get("stage_before", "unknown"), -2)
    after_order  = STAGE_ORDER.get(delta.get("stage_after",  "unknown"), -2)

    # Rule 1: Stage skip
    if before_order >= 0 and after_order >= 0 and (after_order - before_order) > 1:
        flags.append(
            f"STAGE_SKIP: jumped from '{delta['stage_before']}' to "
            f"'{delta['stage_after']}' in one session "
            f"(skipped {after_order - before_order - 1} stage(s)). "
            f"Verify extraction accuracy."
        )

    # Rule 2: Silent relapse
    if delta.get("relapse_detected"):
        relapse_keywords = [
            "relapse", "started smoking again", "gave up", "went back",
            "smoking again", "failed", "slipped",
        ]
        if not any(kw in conversation for kw in relapse_keywords):
            flags.append(
                "SILENT_RELAPSE: stage annotated as 'relapse' but no relapse "
                "language found in conversation. Check extraction."
            )

    # Rule 3: Repeated previously tried intervention
    if profile.session_count >= 2:
        tried = {i.lower().strip() for i in profile.interventions_tried}
        repeated = [i for i in delta.get("new_interventions", []) if i.lower().strip() in tried]
        if repeated:
            flags.append(
                f"REPEATED_INTERVENTION: {repeated} previously tried and recommended "
                f"again. Consider noting outcome of prior use."
            )

    # Rule 4: Prolonged stagnation
    if profile.stagnation_count >= 4:
        flags.append(
            f"PROLONGED_STAGNATION: patient in '{profile.current_stage}' for "
            f"{profile.stagnation_count} consecutive sessions. "
            f"Consider escalating or changing approach."
        )

    # Rule 5: Severe regression
    if (before_order >= STAGE_ORDER.get("action", 3)
            and 0 <= after_order <= STAGE_ORDER.get("contemplation", 1)):
        flags.append(
            f"SEVERE_REGRESSION: dropped from '{delta['stage_before']}' to "
            f"'{delta['stage_after']}' in one session. "
            f"Assess for crisis or significant life event."
        )

    # Rule 6: Trigger unaddressed across sessions
    trigger_counts: Dict[str, int] = {}
    for session in profile.sessions:
        for t in session.all_triggers:
            key = t.lower().strip()
            trigger_counts[key] = trigger_counts.get(key, 0) + 1

    current_interventions = {i.lower() for i in current_row.get("recommended_intervention", [])}
    for trigger, count in trigger_counts.items():
        if count >= 3:
            addressed = any(trigger in iv or iv in trigger for iv in current_interventions)
            if not addressed:
                flags.append(
                    f"UNADDRESSED_PERSISTENT_TRIGGER: '{trigger}' present for "
                    f"{count} sessions without a targeted intervention."
                )

    # Rule 7: Concern contradicts stage
    stage = current_row.get("stage_of_change", "unknown")
    if stage in ("action", "maintenance"):
        not_ready_phrases = ["not ready", "don't want", "not considering", "no interest"]
        for concern in (c.lower() for c in current_row.get("all_concerns", [])):
            if any(phrase in concern for phrase in not_ready_phrases):
                flags.append(
                    f"CONCERN_STAGE_MISMATCH: stage is '{stage}' but a concern "
                    f"suggests ambivalence: '{concern}'"
                )
                break

    passed   = len(flags) == 0
    severity = "none" if passed else ("high" if len(flags) >= 3 else "medium")

    if flags:
        log(f"longitudinal_sanity: {len(flags)} flag(s) (severity={severity})")
        for f in flags:
            log(f"  FLAG: {f}")
    else:
        log("longitudinal_sanity: all checks passed.")

    return _result(flags=flags, passed=passed, severity=severity)


def _result(
    flags: List[str],
    passed: bool,
    severity: str = "none",
) -> Dict[str, Any]:
    payload = {"longitudinal_sanity": {"passed": passed, "flags": flags, "severity": severity}}
    log_data("longitudinal_sanity.output", payload)
    return payload

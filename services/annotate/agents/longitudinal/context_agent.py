"""
agents/longitudinal/context_agent.py
--------------------------------------
Pre-session warning flag computation derived from the patient profile.
"""
from __future__ import annotations


def _compute_flags(profile) -> list[str]:
    flags = []

    if profile.stagnation_count >= 3:
        flags.append(
            f"STAGNATION: patient has been '{profile.current_stage}' for "
            f"{profile.stagnation_count} consecutive sessions"
        )

    if profile.relapse_count > 0:
        flags.append(
            f"RELAPSE_HISTORY: {profile.relapse_count} relapse(s) in history — "
            f"watch for relapse indicators in current session"
        )

    if profile.current_stage in ("action", "maintenance") and profile.relapse_count > 0:
        flags.append(
            "HIGH_RELAPSE_RISK: patient in post-action stage with prior relapse(s)"
        )

    if profile.stage_direction_history and profile.stage_direction_history[-1] == "regression":
        flags.append(
            f"RECENT_REGRESSION: last session showed regression from "
            f"'{profile.previous_stage}' to '{profile.current_stage}'"
        )

    if len(profile.persistent_triggers) > 3:
        flags.append(
            f"PERSISTENT_TRIGGERS: {len(profile.persistent_triggers)} triggers "
            f"unresolved across multiple sessions"
        )

    return flags

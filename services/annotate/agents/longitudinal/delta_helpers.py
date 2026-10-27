"""
agents/longitudinal/delta_helpers.py
--------------------------------------
Helper functions used by delta_agent:
  _compute_delta      : diffs prev vs. curr items for a signal (trigger, concern, intervention, quit_attempt) into (new, persistent, resolved) lists.
  _normalise_set      : lowercases/strips a list of strings into a set, used to normalise prev/curr items before diffing.
  _fallback_narrative : builds a deterministic clinical_summary string when the LLM narrative call fails.
"""
from __future__ import annotations

from typing import List, Set, Tuple

from annotate.llm.router import call_llm
from annotate.llm.json_parser import repair_json
from annotate.utils.logger import warning
from annotate.utils.prompt_loader import format_prompt, load_prompt


def _compute_delta(
    signal_type: str,
    prev: List[str],
    curr: List[str],
    transcript: str,
) -> Tuple[List[str], List[str], List[str]]:
    """
    Cumulative carry-forward semantics. Returns (new, persistent, resolved):
      - new        : curr items judged genuinely new vs. prev (semantic LLM check)
      - resolved   : prev items the transcript explicitly marks as no longer
                     applicable — the ONLY way an item leaves the list
      - persistent : the updated cumulative list — (prev minus resolved) plus new.
                     Store this directly on the profile for the next session.
    """
    if not prev and not curr:
        return [], [], []

    prev_set: Set[str] = set(prev)
    curr_set: Set[str] = set(curr)

    # 1) Genuinely new items — semantic equivalence diff so rephrasings of an
    #    existing signal ("work stress" vs "stress at work") are NOT re-added.
    new: List[str] = []
    try:
        sem_prompt = format_prompt(
            load_prompt("longitudinal.semantic_diff"),
            signal=signal_type,
            prev_items="\n".join(f"- {t}" for t in prev) or "(none)",
            curr_items="\n".join(f"- {t}" for t in curr) or "(none)",
        )
        parsed = repair_json(call_llm(sem_prompt))
        new = [t.strip().lower() for t in parsed.get(f"new_{signal_type}s", []) if t.strip()]
        # A "new" item must actually exist in the current session's items —
        # except for "quit_attempt", where the LLM may extract a short
        # sub-phrase (e.g. "relapsed at a party") describing what's new
        # *within* a longer curr item (e.g. "quit for 8 months then
        # relapsed at a party"), so an exact match against curr_set
        # is too strict.
        if signal_type != "quit_attempt":
            new = [t for t in new if t in curr_set]
    except Exception as exc:
        warning(f"_compute_delta({signal_type}): semantic diff failed — {exc}. Using set diff.")
        new = sorted(curr_set - prev_set)

    # 2) Explicitly resolved items — removal requires the transcript to state
    #    the signal is no longer present/required. Absence from the current
    #    session alone is NOT removal; on any failure nothing is removed.
    #    "quit_attempt" history is purely additive — past attempts are never
    #    removed, so this check never runs for that signal type.
    resolved: List[str] = []
    if signal_type != "quit_attempt" and prev and transcript:
        try:
            res_prompt = format_prompt(
                load_prompt("longitudinal.resolved_validation"),
                signal=signal_type,
                prev_items="\n".join(f"- {t}" for t in prev),
                transcript=transcript[:6000],
            )
            parsed = repair_json(call_llm(res_prompt))
            resolved = [t.strip().lower() for t in parsed.get(f"resolved_{signal_type}s", []) if t.strip()]
            # Can only resolve items that were actually on the carried list.
            resolved = [t for t in resolved if t in prev_set]
        except Exception as exc:
            warning(f"_compute_delta({signal_type}): resolution check failed — {exc}.")

    # 3) New persistent list = everything carried forward (prev minus
    #    explicitly resolved) plus the genuinely new items.
    persistent = sorted((prev_set - set(resolved)) | set(new))

    return sorted(new), persistent, sorted(resolved)


def _normalise_set(items: List[str]) -> Set[str]:
    return {item.strip().lower() for item in items if item.strip()}


def _fallback_narrative(
    stage_before: str,
    stage_after: str,
    direction: str,
    new_triggers: List[str],
    resolved_triggers: List[str],
    new_concerns: List[str],
) -> str:
    parts = []
    if stage_before != stage_after:
        parts.append(f"Stage changed from {stage_before} to {stage_after} ({direction}).")
    else:
        parts.append(f"Stage remained at {stage_after}.")
    if new_triggers:
        parts.append(f"New triggers identified: {', '.join(new_triggers)}.")
    if resolved_triggers:
        parts.append(f"Patient resolved: {', '.join(resolved_triggers)}.")
    if new_concerns:
        parts.append(f"New concerns: {', '.join(new_concerns)}.")
    return " ".join(parts) or "No significant changes detected between sessions."

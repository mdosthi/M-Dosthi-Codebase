"""
examples/test_delta_agent.py
------------------------------
Unit tests for delta_agent using data/test/test_delta_agent.json.

Each case in the JSON defines:
  profile        — PatientProfile fields (loaded via Pydantic)
  state          — additional state keys (dataset_row, triggers, concern, chat)
  llm_responses  — ordered mock responses for each call_llm invocation
  expected       — fields to assert on the returned session_delta

Usage:
    python -m examples.test_delta_agent
    pytest examples/test_delta_agent.py -v
"""
import sys
import json
from pathlib import Path
from unittest.mock import patch

# Ensure the local source tree takes priority over any installed package,
# regardless of how this script is invoked (directly or via -m).
_PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

import annotate.agents.longitudinal.delta_agent    # ensure module is loaded into sys.modules
import annotate.agents.longitudinal.delta_helpers  # _compute_delta calls call_llm via this module
from annotate.schemas.longitudinal_schema import PatientProfile
from annotate.agents.longitudinal.delta_agent import delta_agent

# __init__.py re-exports the function under the same name, masking the submodule
# attribute on the package. Retrieve the real module objects from sys.modules.
_delta_module   = sys.modules["annotate.agents.longitudinal.delta_agent"]
_helpers_module = sys.modules["annotate.agents.longitudinal.delta_helpers"]

DATA_FILE = Path(__file__).parent.parent / "data" / "test" / "test_delta_agent.json"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _load_cases():
    return json.loads(DATA_FILE.read_text())["cases"]


def _build_state(case: dict) -> dict:
    profile = PatientProfile(**case["profile"])
    return {
        "patient_profile": profile,
        **case["state"],
    }


def _make_mock(responses: list):
    """Return a side_effect function that pops responses in order."""
    queue = [json.dumps(r) for r in responses]
    def _call(prompt, **kwargs):
        if not queue:
            return json.dumps({})
        return queue.pop(0)
    return _call


def _run_case(case: dict) -> dict:
    state = _build_state(case)
    mock  = _make_mock(case["llm_responses"])
    with patch.object(_delta_module, "call_llm", side_effect=mock), \
         patch.object(_helpers_module, "call_llm", side_effect=mock):
        return delta_agent(state)


# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

def _assert_case(case: dict, result: dict):
    expected = case["expected"]

    # Explicit null — only when the key is present AND its value is null
    if "session_delta" in expected and expected["session_delta"] is None:
        assert result["session_delta"] is None, (
            f"[{case['id']}] expected session_delta=None, got {result['session_delta']}"
        )
        return

    delta = result["session_delta"]
    assert delta is not None, f"[{case['id']}] expected a delta but got None"

    for field, value in expected.items():
        actual = delta.get(field)
        assert actual == value, (
            f"[{case['id']}] {field}: expected {value!r}, got {actual!r}"
        )


# ---------------------------------------------------------------------------
# Test functions (one per case)
# ---------------------------------------------------------------------------

def test_no_prior_session():
    case   = next(c for c in _load_cases() if c["id"] == "no_prior_session")
    result = _run_case(case)
    _assert_case(case, result)
    print("PASS test_no_prior_session")


def test_stage_progress():
    case   = next(c for c in _load_cases() if c["id"] == "stage_progress")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    assert delta["trigger_resolved"] is True
    assert "social situations" in delta["resolved_triggers"]
    assert delta["new_interventions"] == ["nrt patch"]
    assert "tried nrt patch briefly in 2023" in delta["new_quit_attempts"]
    assert "tried nrt patch briefly in 2023" in delta["cumulative_quit_history"]
    assert "2020" in delta["cumulative_quit_history"]
    print("PASS test_stage_progress")


def test_stage_regression():
    case   = next(c for c in _load_cases() if c["id"] == "stage_regression")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    assert "work deadlines" in delta["new_triggers"]
    assert "stress at work"  in delta["new_concerns"]
    print("PASS test_stage_regression")


def test_relapse():
    case   = next(c for c in _load_cases() if c["id"] == "relapse")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    assert "social event"       in delta["new_triggers"]
    assert "shame"              in delta["new_concerns"]
    assert "relapsed at a party" in delta["new_quit_attempts"]
    assert "relapsed at a party" in delta["cumulative_quit_history"]
    print("PASS test_relapse")


def test_rapid_progress():
    case   = next(c for c in _load_cases() if c["id"] == "rapid_progress")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    assert "boredom"             in delta["resolved_triggers"]
    assert "withdrawal symptoms" in delta["new_concerns"]
    print("PASS test_rapid_progress")


def test_stable_stagnation():
    case   = next(c for c in _load_cases() if c["id"] == "stable_stagnation")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    assert "stress"    in delta["persistent_triggers"]
    assert "not ready" in delta["persistent_concerns"]
    print("PASS test_stable_stagnation")


def test_unknown_stage_fallback():
    case   = next(c for c in _load_cases() if c["id"] == "unknown_stage_fallback")
    result = _run_case(case)
    _assert_case(case, result)
    delta  = result["session_delta"]
    # An "unknown" current-session stage falls back to the previous stage,
    # so the transition reads as stable rather than unknown.
    assert delta["stage_after"]    == "contemplation"
    assert delta["stage_direction"] == "stable"
    print("PASS test_unknown_stage_fallback")


def test_clinical_summary_populated():
    """Narrative LLM response is written into the delta."""
    case   = next(c for c in _load_cases() if c["id"] == "stage_progress")
    result = _run_case(case)
    delta  = result["session_delta"]
    assert delta["clinical_summary"], "clinical_summary should not be empty"
    print("PASS test_clinical_summary_populated")


def test_llm_failure_falls_back_to_narrative():
    """If LLM fails for narrative, fallback narrative is used instead."""
    case  = next(c for c in _load_cases() if c["id"] == "stage_progress")
    state = _build_state(case)

    def _fail_on_narrative(prompt, **kwargs):
        if "clinical narrative" in prompt.lower() or "delta_narrative" in prompt.lower():
            raise RuntimeError("LLM unavailable")
        return json.dumps({
            "new_triggers": [], "persistent_triggers": ["stress"],
            "resolved_triggers": [],
            "new_concerns": [], "persistent_concerns": ["withdrawal symptoms"],
            "resolved_concerns": [],
            "new_interventions": ["nrt patch"], "persistent_interventions": ["counseling"],
        })

    with patch.object(_delta_module, "call_llm", side_effect=_fail_on_narrative), \
         patch.object(_helpers_module, "call_llm", side_effect=_fail_on_narrative):
        result = delta_agent(state)

    delta = result["session_delta"]
    assert delta is not None
    assert delta["clinical_summary"], "fallback narrative should be non-empty"
    assert "preparation" in delta["clinical_summary"] or "contemplation" in delta["clinical_summary"]
    print("PASS test_llm_failure_falls_back_to_narrative")


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    tests = [
        test_no_prior_session,
        test_stage_progress,
        test_stage_regression,
        test_relapse,
        test_rapid_progress,
        test_stable_stagnation,
        test_unknown_stage_fallback,
        test_clinical_summary_populated,
        test_llm_failure_falls_back_to_narrative,
    ]

    passed = 0
    for t in tests:
        try:
            t()
            passed += 1
        except Exception as exc:
            print(f"FAIL {t.__name__}: {exc}")
            import traceback; traceback.print_exc()

    print(f"\n{'='*50}")
    print(f"{passed}/{len(tests)} delta_agent tests passed.")
    print(f"{'='*50}")
    if passed < len(tests):
        sys.exit(1)

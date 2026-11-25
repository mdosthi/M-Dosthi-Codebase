"""
examples/test_confidence.py
----------------------------
Simple test for run_confidence_check() with enable_rag=True
(agents/confidence/confidence.py).

Cases for every signal type (readiness, concern, trigger, attempt, advice)
live in data/test/test_confidence_data.json — nothing is mocked besides the
enable_rag flag, so each case makes a real LLM call grounded by real
ontology RAG retrieval.

Usage:
    python -m examples.test_confidence
    pytest examples/test_confidence.py -v
"""
import json
from pathlib import Path
from unittest.mock import patch

import annotate.agents.confidence.confidence as confidence

_DATA_PATH = (
    Path(__file__).resolve().parent.parent / "data" / "test" / "test_confidence_data.json"
)


def _load_cases():
    return json.loads(_DATA_PATH.read_text(encoding="utf-8"))["cases"]


def test_run_confidence_check_with_rag_enabled():
    for case in _load_cases():
        with patch("annotate.agents.confidence.confidence.enable_rag", True):
            result = confidence.run_confidence_check(
                signal_name=case["signal_name"],
                extracted_signal=case["extracted_signal"],
                conversation=case["conversation"],
            )

        # Real LLM call returns a usable, normalized ConfidenceResult.
        assert 0.0 <= result.confidence <= 1.0, case["id"]
        assert isinstance(result.issues, list), case["id"]
        print(f"PASS test_run_confidence_check_with_rag_enabled[{case['id']}] "
              f"confidence={result.confidence}")


if __name__ == "__main__":
    test_run_confidence_check_with_rag_enabled()
    print("\n" + "=" * 50)
    print("All tests passed.")
    print("=" * 50)

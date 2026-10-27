"""
examples/run_bengali_sessions.py
---------------------------------
Run the annotation pipeline on Bengali smoking-cessation chat sessions and
save a detailed output JSON with every extraction stage logged per session.

The script invokes the LangGraph workflow directly (not run_pipeline) so that
all intermediate extractor outputs — advice, attempt, readiness, concern,
triggers, consensus, confidence_results, sanity_check — are captured in the
output alongside the final dataset_row.

Usage:
    python -m examples.run_bengali_sessions
    python -m examples.run_bengali_sessions data/raw/bengali_sessions.json data/processed/bengali_output.json
"""

import sys
import json
import time
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

# Force Python to load annotate from the local source tree, not the installed
# package. __file__ is .../annotate/examples/run_bengali_sessions.py so
# going two levels up lands at .../api/ which contains the annotate package.
_SRC_ROOT = str(Path(__file__).resolve().parent.parent.parent)
if _SRC_ROOT not in sys.path:
    sys.path.insert(0, _SRC_ROOT)

from annotate.graph.workflow import build_graph
from annotate.config.settings import CONFIDENCE_DEBATE_THRESHOLD, MAX_REVISION_ROUNDS
from annotate.utils.logger import log, error

# ── Defaults ─────────────────────────────────────────────────────────────────

DEFAULT_INPUT  = "data/raw/bengali_sessions.json"
DEFAULT_OUTPUT = "data/processed/bengali_output.json"

# Fields from the graph state to capture per session
_EXTRACTION_FIELDS = [
    "advice",
    "attempt",
    "readiness",
    "concern",
    "trigger",
    "consensus",
    "confidence_results",
    "longitudinal_sanity",
    "longitudinal_flags",
    "cross_signal_disagreement",
    "revision_count",
    "session_delta",
    "dataset_row",
    "longitudinal_output",
]

# Clinical summary fields surfaced at the top level of each output record
_SUMMARY_FIELDS = [
    "stage_of_change",
    "all_concerns",
    "all_triggers",
    "quit_attempt_history",
    "recommended_intervention",
    "reasoning_summary",
    "confidence_score",
    "debate_rounds_used",
    "vote_agreement",
]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _build_initial_state(chat: str, conversation_id: str) -> Dict[str, Any]:
    return {
        "chat": chat,
        "patient_profile": None,
        "longitudinal_flags": [],
        "advice": {}, "attempt": {}, "readiness": {}, "concern": {}, "trigger": {},
        "consensus": {}, "confidence_results": {},
        "longitudinal_sanity": {},
        "revision_count": 0,
        "session_delta": None,
        "dataset_row": {}, "longitudinal_output": {},
        "conversation_id": conversation_id,
        "confidence_threshold": CONFIDENCE_DEBATE_THRESHOLD,
        "max_revision_rounds": MAX_REVISION_ROUNDS,
    }


def _capture_extractions(graph_result: Dict[str, Any]) -> Dict[str, Any]:
    """Pull every logged extraction field out of the raw graph state."""
    return {field: graph_result.get(field) for field in _EXTRACTION_FIELDS}


def _capture_summary(dataset_row: Dict[str, Any]) -> Dict[str, Any]:
    """Top-level clinical summary extracted from dataset_row for quick reading."""
    return {field: dataset_row.get(field) for field in _SUMMARY_FIELDS}


def _run_session(
    graph: Any,
    session_id: str,
    conversation: str,
    description: str,
) -> Dict[str, Any]:
    """Run one session through the graph and return a fully-annotated record."""
    log(f"Running session: {session_id} — {description}")
    start = time.perf_counter()

    initial_state = _build_initial_state(conversation, session_id)
    graph_result  = graph.invoke(initial_state)
    elapsed       = time.perf_counter() - start

    extractions = _capture_extractions(graph_result)
    dataset_row = extractions.get("dataset_row") or {}
    summary     = _capture_summary(dataset_row)

    log(
        f"  Done in {elapsed:.1f}s | stage={summary.get('stage_of_change')} "
        f"| debate_rounds={summary.get('debate_rounds_used')} "
        f"| vote_agreement={summary.get('vote_agreement')}"
    )

    return {
        "session_id":   session_id,
        "description":  description,
        "input_conversation": conversation,
        "elapsed_seconds": round(elapsed, 2),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "summary":      summary,
        "extractions":  extractions,
    }


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    input_path  = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_INPUT
    output_path = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUTPUT

    input_file  = Path(input_path)
    output_file = Path(output_path)

    if not input_file.exists():
        error(f"Input file not found: {input_file}")
        sys.exit(1)

    sessions: List[Dict[str, Any]] = json.loads(input_file.read_text(encoding="utf-8"))
    total = len(sessions)
    log(f"Loaded {total} Bengali session(s) from {input_file}")

    log("Building annotation graph …")
    graph = build_graph()

    results:  List[Dict[str, Any]] = []
    failed:   List[Dict[str, Any]] = []
    batch_start = time.perf_counter()

    for i, item in enumerate(sessions, 1):
        session_id  = item.get("id", f"bengali_{i:02d}")
        description = item.get("description", "")
        conversation = item.get("conversation", "")

        print(f"\n{'─'*60}")
        print(f"[{i}/{total}] {session_id}  {description}")
        print(f"{'─'*60}")

        try:
            record = _run_session(graph, session_id, conversation, description)
            results.append(record)

            # Print a concise per-session summary to console
            s = record["summary"]
            print(f"  Stage of Change   : {s.get('stage_of_change')}")
            print(f"  All Concerns      : {s.get('all_concerns')}")
            print(f"  All Triggers      : {s.get('all_triggers')}")
            print(f"  Quit History      : {s.get('quit_attempt_history')}")
            print(f"  Confidence Score  : {s.get('confidence_score')}")
            print(f"  Vote Agreement    : {s.get('vote_agreement')}")
            print(f"  Debate Rounds     : {s.get('debate_rounds_used')}")

        except Exception as exc:
            error(f"[{i}/{total}] FAILED {session_id}: {exc}")
            traceback.print_exc()
            failed.append({"session_id": session_id, "error": str(exc)})

    # ── Aggregate report ──────────────────────────────────────────────────────
    batch_elapsed = time.perf_counter() - batch_start
    print(f"\n{'='*60}")
    print(f"Batch complete: {len(results)}/{total} succeeded  ({batch_elapsed:.1f}s total)")

    if results:
        stages       = [r["summary"].get("stage_of_change", "unknown") for r in results]
        mean_conf    = sum((r["summary"].get("confidence_score") or 0) for r in results) / len(results)
        agree_vals   = [r["summary"]["vote_agreement"] for r in results
                        if r["summary"].get("vote_agreement") is not None]
        mean_agree   = sum(agree_vals) / len(agree_vals) if agree_vals else None

        print(f"  Mean confidence   : {mean_conf:.3f}")
        if mean_agree is not None:
            print(f"  Mean vote agree   : {mean_agree:.3f}")
        print(f"  Stage distribution:")
        from collections import Counter
        for stage, count in Counter(stages).most_common():
            print(f"    {stage:30s} {count}")

    if failed:
        print(f"\n  {len(failed)} session(s) failed:")
        for f in failed:
            print(f"    {f['session_id']}: {f['error']}")

    # ── Save output ───────────────────────────────────────────────────────────
    output_file.parent.mkdir(parents=True, exist_ok=True)

    output = {
        "metadata": {
            "input_file":      str(input_file),
            "total_sessions":  total,
            "succeeded":       len(results),
            "failed":          len(failed),
            "batch_elapsed_seconds": round(batch_elapsed, 2),
            "generated_at":    datetime.now(timezone.utc).isoformat(),
        },
        "results": results,
        "errors":  failed,
    }

    output_file.write_text(
        json.dumps(output, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    log(f"Saved output to {output_file}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()

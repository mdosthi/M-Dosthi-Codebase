"""
db/run_store.py
---------------
Accumulates all agent outputs for a single pipeline run in memory.
Callers retrieve the data via to_dict() and are responsible for persisting it.

Round numbering:
  Round 1 — initial extraction + confidence (+ revision if signals fail)
  Round 2+ — confidence re-check + revision for still-failing signals
"""
from typing import Any, Dict, List, Optional
from uuid import uuid4

from annotate.utils.logger import log


class RunStore:
    """Accumulates per-run agent data in memory. Reset at the start of each run."""

    def __init__(self) -> None:
        self._reset()

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start_run(self, conversation_id: Optional[str], patient_id: Optional[str] = None) -> None:
        self._reset()
        self._run_id          = str(uuid4())
        self._conversation_id = conversation_id
        self._patient_id      = patient_id
        log(f"run_store: started run {self._run_id}")

    def _reset(self) -> None:
        self._run_id:              str                  = ""
        self._conversation_id:     Optional[str]        = None
        self._patient_id:          Optional[str]        = None
        self._rounds:              List[Dict[str, Any]] = []
        self._current_round:       Dict[str, Any]       = {}
        self._consensus:           Optional[Dict]       = None
        self._dataset_row:         Optional[Dict]       = None
        self._session_delta:       Optional[Dict]       = None
        self._longitudinal_sanity: Optional[Dict]       = None
        self._longitudinal_output: Optional[Dict]       = None

    # ------------------------------------------------------------------
    # Per-round recording
    # ------------------------------------------------------------------

    def record_extraction(self, signals: Dict[str, Any]) -> None:
        """Called once after run_extractors (always round 1)."""
        self._current_round = {"round_number": 1, "extraction": signals}

    def record_confidence(self, round_number: int, confidence_results: Dict[str, Any]) -> None:
        """Called after each run_confidence_check. Closes the previous round if needed."""
        if self._current_round and self._current_round.get("round_number") != round_number:
            self._rounds.append(self._current_round)
            self._current_round = {"round_number": round_number}
        elif not self._current_round:
            self._current_round = {"round_number": round_number}
        self._current_round["confidence"] = confidence_results

    def record_revision(self, revised: Dict[str, Any]) -> None:
        """Called after run_revision. Always belongs to the current round."""
        self._current_round["revision"] = revised

    # ------------------------------------------------------------------
    # Post-loop recording
    # ------------------------------------------------------------------

    def record_consensus(self, consensus: Dict[str, Any]) -> None:
        self._consensus = consensus

    def record_reasoning(self, dataset_row: Dict[str, Any]) -> None:
        self._dataset_row = dataset_row

    def record_delta(self, session_delta: Optional[Dict]) -> None:
        self._session_delta = session_delta

    def record_longitudinal_sanity(self, result: Dict[str, Any]) -> None:
        self._longitudinal_sanity = result

    def record_longitudinal_output(self, result: Dict[str, Any]) -> None:
        self._longitudinal_output = result

    # ------------------------------------------------------------------
    # Export
    # ------------------------------------------------------------------

    def to_dict(self) -> Dict[str, Any]:
        """Return the complete run data. Caller is responsible for persisting it."""
        rounds = list(self._rounds)
        if self._current_round:
            rounds.append(self._current_round)
        return {
            "run_id":              self._run_id,
            "conversation_id":     self._conversation_id,
            "patient_id":          self._patient_id,
            "total_rounds":        len(rounds),
            "rounds":              rounds,
            "consensus":           self._consensus,
            "dataset_row":         self._dataset_row,
            "session_delta":       self._session_delta,
            "longitudinal_sanity": self._longitudinal_sanity,
            "longitudinal_output": self._longitudinal_output,
        }

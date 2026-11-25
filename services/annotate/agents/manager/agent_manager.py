"""
agents/manager/agent_manager.py
---------------------------------
Central coordinator for the full annotation pipeline.

Flow:
  1. run_extractors()       — parallel fan-out, returns raw extractor outputs
  2. run_confidence_check() — evaluate every signal; called by the graph node
  3. run_revision()         — revise only signals below threshold; called by graph node
  Steps 2-3 repeat (workflow loop) until all signals pass the threshold
  or max revision rounds is reached. The threshold and max-rounds are pulled
  from state (set by run_pipeline based on enable_debate) with a fallback to
  config defaults.
  4. run_consensus()        — multi-voter consensus + arbitration
  5. run_reasoning()        — final reasoning pass, produces DatasetRow
"""
from typing import Dict, Any, List, Optional

from annotate.agents.registry import get_registry
from annotate.agents.memory import AgentMemory, PatientMemory
from annotate.agents.confidence import run_confidence_check
from annotate.agents.revision import run_revision as revise_signal
from annotate.agents.consensus.consensus_agent import consensus_agent
from annotate.agents.reasoning import reasoning_agent
from annotate.agents.longitudinal import delta_agent, longitudinal_sanity_agent, profile_update_agent
from annotate.db.run_store import RunStore
from annotate.utils.logger import log, warning, log_data
from annotate.schemas.clinical_schema import DatasetRow
from annotate.config.settings import (
    CONFIDENCE_DEBATE_THRESHOLD,
    Trigger, Concern, Advice, Readiness, Attempt,
    Confidence_and_Revision, Consensus, Reasoning, Delta,
)


_SIGNALS = ["attempt", "readiness", "concern", "trigger", "advice"]

# Maps each extractor signal to its ablation flag (config/settings.py).
_SIGNAL_ENABLED = {
    "attempt": Attempt,
    "readiness": Readiness,
    "concern": Concern,
    "trigger": Trigger,
    "advice": Advice,
}


def active_signals() -> List[str]:
    """Signal keys whose extractor is enabled under the current ablation settings."""
    return [s for s in _SIGNALS if _SIGNAL_ENABLED.get(s, True)]

class AgentManager:
    """
    Coordinates extractor agents with confidence-aware routing and optional debate escalation.
    """

    def __init__(self, memory: Optional[AgentMemory] = None) -> None:
        self.registry = get_registry()
        self.memory = memory or AgentMemory()
        self.patient_memory = PatientMemory()
        self.run_store = RunStore()

    # ------------------------------------------------------------------
    # Step 1 — Parallel extraction (no confidence logic here)
    # ------------------------------------------------------------------

    def run_extractors(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Fan out all registered extractors in parallel.
        Returns raw extractor outputs merged into a single dict.
        Confidence checking and revision are done in separate graph nodes
        (the workflow's confidence ↔ revision loop).
        """
        log("agent_manager: running parallel extractors ...")
        self.run_store.start_run(
            conversation_id=state.get("conversation_id"),
            patient_id=state.get("patient_profile") and getattr(state["patient_profile"], "patient_id", None),
        )

        signals = active_signals()
        selected = [f"{s}_agent" for s in signals]
        raw_outputs = self.registry.run_all_parallel(state, max_workers=5, selected=selected)

        final_outputs: Dict[str, Any] = {}
        for state_key in signals:
            output = raw_outputs.get(state_key)
            if not output:
                continue
            log_data(f"agent_manager.extractor_output.{state_key}", output)
            final_outputs[state_key] = output

        self.run_store.record_extraction(final_outputs)

        # confidence_results starts empty; will be filled by run_confidence_check()
        final_outputs["confidence_results"] = {}
        return final_outputs

    # ------------------------------------------------------------------
    # Step 2 — Confidence check (called by graph confidence_check node)
    # ------------------------------------------------------------------

    def run_confidence_check(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Evaluate the confidence of every extracted signal.
        Signals that already passed the threshold in a previous round are carried
        forward without an additional LLM call.
        Returns {'confidence_results': {signal: {'confidence': float, 'issues': list}}}.
        Called directly by the graph confidence_check node.
        """
        log("agent_manager: running confidence checks ...")

        if not Confidence_and_Revision:
            log("agent_manager: confidence/revision loop disabled by ablation setting — "
                "treating all signals as fully confident.")
            confidence_results = {s: {"confidence": 1.0, "issues": []} for s in active_signals()}
            round_number = state.get("revision_count", 0) + 1
            self.run_store.record_confidence(round_number, confidence_results)
            return {"confidence_results": confidence_results}

        confidence_results: Dict[str, Any] = {}
        prev_confidence = state.get("confidence_results", {})
        threshold = state.get("confidence_threshold", CONFIDENCE_DEBATE_THRESHOLD)

        for state_key in active_signals():
            # Skip re-evaluation if this signal already passed in a prior round
            prev = prev_confidence.get(state_key, {})
            if prev.get("confidence", 0.0) >= threshold:
                log(f"agent_manager: confidence[{state_key}] already passed "
                    f"({prev['confidence']:.3f}) — skipping re-evaluation.")
                confidence_results[state_key] = prev
                continue

            output = state.get(state_key)
            if not output:
                # Signal missing — treat as zero confidence so revision will be triggered
                confidence_results[state_key] = {"confidence": 0.0, "issues": ["signal not extracted"]}
                continue

            result = self._run_signal_confidence(state, state_key, output)
            confidence_results[state_key] = result
            log(f"agent_manager: confidence[{state_key}]={result['confidence']:.3f} "
                f"issues={result['issues']}")

        log_data("agent_manager.confidence_results", confidence_results)
        round_number = state.get("revision_count", 0) + 1
        self.run_store.record_confidence(round_number, confidence_results)
        return {"confidence_results": confidence_results}

    # ------------------------------------------------------------------
    # Step 3 — Revision (called by graph revision node)
    # ------------------------------------------------------------------

    def run_revision(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Revise every signal whose confidence is below the threshold.
        Returns partial state update with revised signal values.
        Called directly by the graph revision node.
        """
        log("agent_manager: running revisions for low-confidence signals ...")

        if not Confidence_and_Revision:
            # Should not normally be reached (confidence_router skips straight to
            # consensus when the loop is disabled), but guard against it anyway.
            log("agent_manager: confidence/revision loop disabled by ablation setting — skipping.")
            return {}

        confidence_results = state.get("confidence_results", {})
        threshold = state.get("confidence_threshold", CONFIDENCE_DEBATE_THRESHOLD)
        revised_outputs: Dict[str, Any] = {}

        for state_key in active_signals():
            conf_entry = confidence_results.get(state_key, {})
            confidence = conf_entry.get("confidence", 0.0)
            issues = conf_entry.get("issues", [])

            if confidence >= threshold:
                log(f"agent_manager: '{state_key}' confidence={confidence:.3f} >= threshold "
                    f"— skipping revision.")
                continue

            log(f"agent_manager: '{state_key}' confidence={confidence:.3f} < threshold "
                f"— running revision ...")

            current_output = state.get(state_key, {})

            try:
                revised = revise_signal(
                    signal_name=state_key,
                    current_output=current_output,
                    conversation=state.get("chat", ""),
                    feedback="\n".join(str(issue) for issue in issues) if issues else "No issues provided.",
                )
                if isinstance(revised, dict) and state_key in revised and isinstance(revised[state_key], dict):
                    revised = revised[state_key]

                if isinstance(revised, dict) and revised:
                    revised_outputs[state_key] = revised
                    log_data(f"agent_manager.revised_output.{state_key}", revised)
                else:
                    warning(f"agent_manager: revision for '{state_key}' returned unexpected keys: "
                            f"{list(revised.keys()) if isinstance(revised, dict) else type(revised)} — keeping original.")
                    revised_outputs[state_key] = current_output
            except Exception as exc:
                warning(f"agent_manager: revision for '{state_key}' failed: {exc}. Keeping original output.")
                revised_outputs[state_key] = current_output

        self.run_store.record_revision(revised_outputs)
        return revised_outputs


    # ------------------------------------------------------------------
    # Step 4 — Consensus (called by graph multi_consensus node)
    # ------------------------------------------------------------------

    def run_consensus(self, state: Dict[str, Any]) -> Dict[str, Any]:
        log("agent_manager: running consensus ...")
        if not Consensus:
            log("agent_manager: consensus disabled by ablation setting — "
                "merging extractor outputs directly (no voting).")
            result = self._no_op_consensus(state)
        else:
            result = consensus_agent(state)
        self.run_store.record_consensus(result.get("consensus", {}))
        return result

    # ------------------------------------------------------------------
    # Step 5 — Reasoning (called by graph reasoning node)
    # ------------------------------------------------------------------

    def run_reasoning(self, state: Dict[str, Any]) -> Dict[str, Any]:
        log("agent_manager: running reasoning ...")
        if not Reasoning:
            log("agent_manager: reasoning disabled by ablation setting — "
                "building dataset row directly from consensus (no LLM call).")
            result = self._no_op_reasoning(state)
        else:
            result = reasoning_agent(state)
        self.run_store.record_reasoning(result.get("dataset_row", {}))
        return result

    # ------------------------------------------------------------------
    # Step 6 — Longitudinal (called by graph longitudinal nodes)
    # ------------------------------------------------------------------

    def run_delta(self, state: Dict[str, Any]) -> Dict[str, Any]:
        log("agent_manager: running delta ...")
        if not Delta:
            log("agent_manager: delta computation disabled by ablation setting — skipping.")
            result = {"session_delta": None}
        else:
            result = delta_agent(state)
        self.run_store.record_delta(result.get("session_delta"))
        return result

    def run_longitudinal_sanity(self, state: Dict[str, Any]) -> Dict[str, Any]:
        log("agent_manager: running longitudinal sanity ...")
        result = longitudinal_sanity_agent(state)
        self.run_store.record_longitudinal_sanity(result.get("longitudinal_sanity"))
        return result

    def run_profile_update(self, state: Dict[str, Any]) -> Dict[str, Any]:
        log("agent_manager: running profile update ...")
        result = profile_update_agent(state, self.patient_memory)
        self.run_store.record_longitudinal_output(result.get("longitudinal_output", {}))
        return result

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _no_op_consensus(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Deterministic stand-in for consensus_agent() when Consensus is disabled:
        merges extractor outputs directly instead of running multi-voter LLM calls.
        """
        readiness = state.get("readiness", {}) or {}
        concern = state.get("concern", {}) or {}
        trigger = state.get("trigger", {}) or {}
        attempt = state.get("attempt", {}) or {}
        advice = state.get("advice", {}) or {}
        attempts = attempt.get("attempts", [])

        consensus = {
            "stage_of_change": readiness.get("readiness_stage", "unknown"),
            "all_concerns": concern.get("concerns", []),
            "all_triggers": trigger.get("triggers", []),
            "quit_attempt_history": "; ".join(attempts) if attempts else "unknown",
            "recommended_intervention": advice.get("advice", []),
            "suicidal_ideation": False,
            "vote_agreement": 1.0,
            "dissenting_fields": [],
        }
        return {"consensus": consensus}

    def _no_op_reasoning(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Deterministic stand-in for reasoning_agent() when Reasoning is disabled:
        builds the DatasetRow directly from consensus instead of an LLM call.
        """
        consensus = state.get("consensus", {}) or {}
        validated = DatasetRow(
            stage_of_change=consensus.get("stage_of_change", "unknown"),
            all_concerns=consensus.get("all_concerns", []) or [],
            all_triggers=consensus.get("all_triggers", []) or [],
            quit_attempt_history=consensus.get("quit_attempt_history", "unknown"),
            recommended_intervention=consensus.get("recommended_intervention", []) or [],
            suicidal_ideation=consensus.get("suicidal_ideation", False),
            debate_rounds_used=state.get("revision_count", 0),
            vote_agreement=consensus.get("vote_agreement", 0.0),
        )
        return {"dataset_row": validated.model_dump()}

    def _run_signal_confidence(
        self,
        state: Dict[str, Any],
        state_key: str,
        output: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Run the confidence check for a single signal.
        Returns {'confidence': float, 'issues': list}.
        Falls back to {'confidence': 0.5, 'issues': []} on error.
        """
        try:
            chat_text = state.get("chat", "")
            result = run_confidence_check(
                signal_name=state_key,
                extracted_signal=output,
                conversation=chat_text
            )
            return {"confidence": result.confidence, "issues": result.issues}
        except Exception as exc:
            warning(f"agent_manager: confidence check for '{state_key}' failed: {exc}. "
                    f"Defaulting to 0.5.")
            return {"confidence": 0.5, "issues": [str(exc)]}

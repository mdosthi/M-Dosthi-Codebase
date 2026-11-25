"""
graph/parallel_workflow.py
---------------------------
Alternative entry point that bypasses LangGraph and calls the AgentManager
directly. Useful for testing or environments where LangGraph is unavailable.
Single-pass: no confidence/revision loop is run here — for that path use
run_pipeline() which drives the full graph.
"""
from typing import Dict, Any

from annotate.agents.manager import AgentManager
from annotate.utils.logger import log


def run_parallel_pipeline(chat: str, conversation_id: str = "") -> Dict[str, Any]:
    manager = AgentManager()

    state: Dict[str, Any] = {
        "chat": chat,
        "advice": {}, "attempt": {}, "readiness": {}, "concern": {}, "trigger": {},
        "consensus": {}, "confidence_results": {},
        "dataset_row": {},
    }
    if conversation_id:
        state["conversation_id"] = conversation_id

    log("parallel_workflow: fan-out extraction ...")
    state.update(manager.run_extractors(state))

    log("parallel_workflow: multi-voter consensus ...")
    state.update(manager.run_consensus(state))

    log("parallel_workflow: reasoning ...")
    state.update(manager.run_reasoning(state))

    return state["dataset_row"]

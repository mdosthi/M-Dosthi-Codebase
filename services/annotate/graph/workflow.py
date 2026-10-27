"""
graph/workflow.py
------------------
Adaptive LangGraph workflow with full longitudinal coherence support.

Topology
--------
                    parallel_extract            ← AgentManager fanout
                           │
                    confidence_check            ← evaluate all signal confidences
                           │
              ┌────────────┴────────────┐
         (< threshold)              (>= threshold)
              │                          │
              │                    multi_consensus   ← 3 voters + arbitration
           revision                     │
              │                      reasoning      ← final DatasetRow
              └──────→ confidence_check    │
                         (loop back)   delta_compute
                                          │
                                   longitudinal_sanity
                                          │
                                   profile_update     ← persist PatientProfile
                                          │
                                         END
"""
from typing import Dict, Any

from langgraph.graph import StateGraph, END

from annotate.graph.state import GraphState
from annotate.agents.manager import AgentManager, active_signals
from annotate.config.settings import CONFIDENCE_DEBATE_THRESHOLD, MAX_REVISION_ROUNDS
from annotate.utils.logger import log


_manager = AgentManager()


def get_manager() -> AgentManager:
    return _manager


# ---------------------------------------------------------------------------
# Node wrappers
# Each function is a thin graph node that delegates to AgentManager and handles any graph-level bookkeeping (e.g. loop counters) that the manager should not own.
# ---------------------------------------------------------------------------


def parallel_extract_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [parallel_extract] ...")
    return _manager.run_extractors(state)


def confidence_check_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [confidence_check] ...")
    results = _manager.run_confidence_check(state)
    # Initialise the revision counter on the first pass so confidence_router
    # always has a valid integer to compare against max_revision_rounds.
    if state.get("revision_count") is None:
        results["revision_count"] = 0
    return results


def revision_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [revision] ...")
    revised = _manager.run_revision(state)
    # Increment here so confidence_router can enforce the max-rounds ceiling.
    revised["revision_count"] = state.get("revision_count", 0) + 1
    return revised


def multi_consensus_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [multi_consensus] ...")
    return _manager.run_consensus(state)


def reasoning_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [reasoning] ...")
    return _manager.run_reasoning(state)


def delta_compute_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [delta_compute] ...")
    return _manager.run_delta(state)


def longitudinal_sanity_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [longitudinal_sanity] ...")
    return _manager.run_longitudinal_sanity(state)


def profile_update_node(state: GraphState) -> Dict[str, Any]:
    log("workflow: [profile_update] ...")
    return _manager.run_profile_update(state)


# ---------------------------------------------------------------------------
# Confidence router
# Drives the confidence → revision loop. Returns the name of the next node.
# ---------------------------------------------------------------------------

def confidence_router(state: GraphState) -> str:
    revision_count = state.get("revision_count", 0)
    confidence_results = state.get("confidence_results", {})
    threshold = state.get("confidence_threshold", CONFIDENCE_DEBATE_THRESHOLD)
    max_rounds = state.get("max_revision_rounds", MAX_REVISION_ROUNDS)

    # Hard exit: avoid infinite loops when signals persistently fail.
    if revision_count >= max_rounds:
        log(
            f"workflow: confidence_router → max revision rounds reached "
            f"({max_rounds}); proceeding to consensus."
        )
        return "multi_consensus"

    # Only signals whose extractor is enabled (per ablation settings) can
    # gate the loop — a disabled signal has no extracted output to revise.
    for sig in active_signals():
        conf = confidence_results.get(sig, {}).get("confidence", 0.0)
        if conf < threshold:
            log(f"workflow: confidence_router → '{sig}' confidence={conf:.3f} "
                f"< {threshold} (revision {revision_count + 1})")
            return "revision"

    log("workflow: confidence_router → all signals above threshold, proceeding to consensus.")
    return "multi_consensus"


# ---------------------------------------------------------------------------
# Graph builder
# ---------------------------------------------------------------------------

def build_graph():
    workflow = StateGraph(GraphState)

    # ── Nodes ──────────────────────────────────────────────────────────────
    workflow.add_node("parallel_extract",          parallel_extract_node)
    workflow.add_node("confidence_check",          confidence_check_node)
    workflow.add_node("revision",                  revision_node)
    workflow.add_node("multi_consensus",           multi_consensus_node)
    workflow.add_node("reasoning",                 reasoning_node)
    workflow.add_node("delta_compute",             delta_compute_node)
    workflow.add_node("longitudinal_sanity_check", longitudinal_sanity_node)
    workflow.add_node("profile_update",            profile_update_node)

    # ── Entry ──────────────────────────────────────────────────────────────
    workflow.set_entry_point("parallel_extract")

    # ── Linear prefix ──────────────────────────────────────────────────────
    workflow.add_edge("parallel_extract",     "confidence_check")

    # ── Confidence → revision loop ─────────────────────────────────────────
    # confidence_check branches: low-confidence → revision, else → multi_consensus
    workflow.add_conditional_edges(
        "confidence_check",
        confidence_router,
        {
            "revision":      "revision",
            "multi_consensus": "multi_consensus",
        },
    )
    # After revision, re-evaluate confidence (closing the loop)
    workflow.add_edge("revision", "confidence_check")

    # ── Synthesis chain ────────────────────────────────────────────────────
    workflow.add_edge("multi_consensus", "reasoning")

    # ── Longitudinal chain ─────────────────────────────────────────────────
    workflow.add_edge("reasoning",                "delta_compute")
    workflow.add_edge("delta_compute",            "longitudinal_sanity_check")
    workflow.add_edge("longitudinal_sanity_check", "profile_update")
    workflow.add_edge("profile_update",           END)

    return workflow.compile()

"""
examples/test_ontology_rag.py
--------------------------------
Tests for the embedding-based ontology RAG used by confidence agents when
enable_rag=True (agents/confidence/ontology_rag.py, agents/confidence/confidence.py).

No live Ollama server is required — embed_text() is mocked throughout with a
small deterministic fake embedding model so similarity rankings are
predictable and assertable.

Usage:
    python -m examples.test_ontology_rag
    pytest examples/test_ontology_rag.py -v
"""
import json
from unittest.mock import patch

import annotate.agents.confidence.ontology_rag as ontology_rag
import annotate.agents.confidence.confidence as confidence


# ============================================================================
# Fake embedding model
# ----------------------------------------------------------------------------
# Maps text onto 4 hand-picked "axes" (stress / social / routine / exclusion)
# so cosine similarity against the real `trigger` ontology entries is
# predictable: each axis lights up only when its associated keywords appear,
# and the ontology entry text always contains its own keyword list, so the
# correct entry should score highest for a matching query.
# ============================================================================

_AXES = {
    "stress": ["stress", "pressure", "deadline", "overwhelmed"],
    "social": ["party", "social", "friends", "peer pressure"],
    "routine": ["coffee", "morning", "routine", "driving"],
    "exclusion": ["expensive", "health", "children", "future goal"],
}


def _fake_embed(text: str, model: str = None):
    text_l = text.lower()
    return [
        1.0 if any(kw in text_l for kw in kws) else 0.0
        for kws in _AXES.values()
    ] or [0.0, 0.0, 0.0, 0.0]


def _reset_caches():
    """Ontology entry embeddings are cached at module level — clear between tests."""
    ontology_rag._ontology_cache.clear()
    ontology_rag._entry_embedding_cache.clear()


# ============================================================================
# load_ontology()
# ============================================================================

def test_load_ontology_has_all_signal_types():
    _reset_caches()
    onto = ontology_rag.load_ontology()
    for signal in ("readiness", "concern", "trigger", "attempt", "advice"):
        assert signal in onto
        assert len(onto[signal]) > 0
        for entry in onto[signal]:
            assert "term" in entry and "definition" in entry and "keywords" in entry
    print("PASS test_load_ontology_has_all_signal_types")


# ============================================================================
# retrieve_ontology_context() — ranking behavior
# ============================================================================

def test_retrieve_ranks_habitual_routine_for_coffee_trigger():
    _reset_caches()
    with patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed):
        context = ontology_rag.retrieve_ontology_context(
            signal_name="trigger",
            extracted_signal={"triggers": ["morning coffee"]},
            conversation="Patient: I smoke with my coffee every morning.",
        )
    assert "habitual_routine" in context.splitlines()[0]
    print("PASS test_retrieve_ranks_habitual_routine_for_coffee_trigger")


def test_retrieve_ranks_stress_for_work_stress_trigger():
    _reset_caches()
    with patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed):
        context = ontology_rag.retrieve_ontology_context(
            signal_name="trigger",
            extracted_signal={"triggers": ["work stress"]},
            conversation="Patient: Deadline pressure at work makes me crave a cigarette.",
        )
    assert "stress" in context.splitlines()[0]
    print("PASS test_retrieve_ranks_stress_for_work_stress_trigger")


def test_retrieve_respects_top_k():
    _reset_caches()
    with patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed):
        context = ontology_rag.retrieve_ontology_context(
            signal_name="trigger",
            extracted_signal={"triggers": []},
            conversation="Patient: nothing relevant here.",
            top_k=2,
        )
    assert len(context.splitlines()) == 2
    print("PASS test_retrieve_respects_top_k")


def test_retrieve_unknown_signal_returns_empty_without_embedding_call():
    _reset_caches()
    with patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed) as mock_embed:
        context = ontology_rag.retrieve_ontology_context(
            signal_name="not_a_real_signal",
            extracted_signal={},
            conversation="irrelevant",
        )
    assert context == ""
    mock_embed.assert_not_called()
    print("PASS test_retrieve_unknown_signal_returns_empty_without_embedding_call")


# ============================================================================
# Entry embeddings are cached (embedded once per signal, not per query)
# ============================================================================

def test_entry_embeddings_are_cached_across_queries():
    _reset_caches()
    with patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed) as mock_embed:
        ontology_rag.retrieve_ontology_context("trigger", {"triggers": ["coffee"]}, "Patient: coffee.")
        calls_after_first = mock_embed.call_count

        ontology_rag.retrieve_ontology_context("trigger", {"triggers": ["party"]}, "Patient: party.")
        calls_after_second = mock_embed.call_count

    n_trigger_entries = len(ontology_rag.load_ontology()["trigger"])
    # First call: N entry embeddings + 1 query embedding.
    assert calls_after_first == n_trigger_entries + 1
    # Second call: entries are cached, only the new query gets embedded.
    assert calls_after_second == calls_after_first + 1
    print("PASS test_entry_embeddings_are_cached_across_queries")


# ============================================================================
# Graceful degradation when the embedding model is unreachable
# ============================================================================

def test_retrieve_returns_empty_on_embedding_failure():
    _reset_caches()
    with patch(
        "annotate.agents.confidence.ontology_rag.embed_text",
        side_effect=RuntimeError("Ollama embeddings unreachable"),
    ):
        context = ontology_rag.retrieve_ontology_context(
            signal_name="trigger",
            extracted_signal={"triggers": ["coffee"]},
            conversation="Patient: coffee.",
        )
    assert context == ""
    print("PASS test_retrieve_returns_empty_on_embedding_failure")


# ============================================================================
# Integration with confidence.py — enable_rag gates ontology grounding
# ============================================================================

def test_confidence_check_includes_ontology_block_when_rag_enabled():
    _reset_caches()
    captured_prompt = {}

    def fake_call_llm(prompt, **kwargs):
        captured_prompt["value"] = prompt
        return json.dumps({"confidence": 9, "issues": []})

    with patch("annotate.agents.confidence.confidence.enable_rag", True), \
         patch("annotate.agents.confidence.confidence.call_llm", fake_call_llm), \
         patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed):
        result = confidence.run_confidence_check(
            signal_name="trigger",
            extracted_signal={"triggers": ["morning coffee"], "evidence": ["I smoke with my coffee"]},
            conversation="Patient: I smoke with my coffee every morning.",
        )

    assert "ONTOLOGY REFERENCE" in captured_prompt["value"]
    assert result.confidence == 0.9
    print("PASS test_confidence_check_includes_ontology_block_when_rag_enabled")


def test_confidence_check_omits_ontology_block_when_rag_disabled():
    _reset_caches()
    captured_prompt = {}

    def fake_call_llm(prompt, **kwargs):
        captured_prompt["value"] = prompt
        return json.dumps({"confidence": 9, "issues": []})

    with patch("annotate.agents.confidence.confidence.enable_rag", False), \
         patch("annotate.agents.confidence.confidence.call_llm", fake_call_llm), \
         patch("annotate.agents.confidence.ontology_rag.embed_text", side_effect=_fake_embed) as mock_embed:
        confidence.run_confidence_check(
            signal_name="trigger",
            extracted_signal={"triggers": ["morning coffee"]},
            conversation="Patient: I smoke with my coffee every morning.",
        )

    assert "ONTOLOGY REFERENCE" not in captured_prompt["value"]
    mock_embed.assert_not_called()
    print("PASS test_confidence_check_omits_ontology_block_when_rag_disabled")


# ============================================================================
# Runner
# ============================================================================

if __name__ == "__main__":
    test_load_ontology_has_all_signal_types()

    test_retrieve_ranks_habitual_routine_for_coffee_trigger()
    test_retrieve_ranks_stress_for_work_stress_trigger()
    test_retrieve_respects_top_k()
    test_retrieve_unknown_signal_returns_empty_without_embedding_call()

    test_entry_embeddings_are_cached_across_queries()
    test_retrieve_returns_empty_on_embedding_failure()

    test_confidence_check_includes_ontology_block_when_rag_enabled()
    test_confidence_check_omits_ontology_block_when_rag_disabled()

    print("\n" + "=" * 50)
    print("All tests passed.")
    print("=" * 50)

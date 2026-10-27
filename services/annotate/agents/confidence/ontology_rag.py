"""
agents/confidence/ontology_rag.py
----------------------------------
Embedding-based retrieval over the clinical ontology
(data/ontology/clinical_ontology.json), used to ground confidence-check
audits when enable_rag=True.

Embeddings are produced by Ollama's `embeddinggemma` model (see
llm/ollama_client.embed_text). Ontology entry embeddings are computed once
per process and cached; only the query (extracted signal + conversation) is
embedded per call.
"""
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple
import numpy as np

from annotate.llm.ollama_client import embed_text
from annotate.utils.logger import log, warning

PACKAGE_ROOT = Path(__file__).resolve().parent.parent.parent
_ONTOLOGY_PATH = PACKAGE_ROOT / "data" / "ontology" / "clinical_ontology.json"

_ontology_cache: Dict[str, List[Dict[str, Any]]] = {}
_entry_embedding_cache: Dict[str, List[np.ndarray]] = {}

def _build_query_items(extracted_signal: Dict[str, Any]) -> List[Tuple[str, str]]:
    """Turn the extracted signal into (label, text) query items, one per field."""
    items: List[Tuple[str, str]] = []
    for key, value in extracted_signal.items():
        if value is None:
            continue
        if isinstance(value, (list, tuple)):
            text = ", ".join(str(v) for v in value)
        elif isinstance(value, dict):
            text = json.dumps(value, ensure_ascii=False)
        else:
            text = str(value)
        if text.strip():
            items.append((key, f"{key}: {text}"))
    return items

def load_ontology() -> Dict[str, List[Dict[str, Any]]]:
    global _ontology_cache
    if not _ontology_cache:
        _ontology_cache = json.loads(_ONTOLOGY_PATH.read_text(encoding="utf-8"))
    return _ontology_cache


def _entry_text(entry: Dict[str, Any]) -> str:
    return f"{entry['term']}: {entry['definition']} ({', '.join(entry.get('keywords', []))})"


def _entry_embeddings(signal_name: str, entries: List[Dict[str, Any]]) -> List[np.ndarray]:
    """Embed and cache every ontology entry for this signal, once per process."""
    if signal_name not in _entry_embedding_cache:
        log(f"ontology_rag: embedding {len(entries)} ontology entries for '{signal_name}' ...")
        _entry_embedding_cache[signal_name] = [
            np.array(embed_text(_entry_text(entry))) for entry in entries
        ]
    return _entry_embedding_cache[signal_name]


def _cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    denom = np.linalg.norm(a) * np.linalg.norm(b)
    return float(np.dot(a, b) / denom) if denom else 0.0


def retrieve_ontology_context(
    signal_name: str,
    extracted_signal: Dict[str, Any],
    conversation: str,
    top_k: int = 3,
) -> str:
    """
    Embed each extracted-signal field separately, score every ontology entry
    by its best similarity across those fields, and render the top matches as
    a reference block for the LLM prompt.
    """
    entries = load_ontology().get(signal_name, [])
    if not entries:
        return ""

    query_items = _build_query_items(extracted_signal)
    if not query_items:
        return ""

    try:
        query_vecs = [(label, np.array(embed_text(text))) for label, text in query_items]
        entry_vecs = _entry_embeddings(signal_name, entries)
    except Exception as exc:
        warning(f"ontology_rag: embedding call failed — {exc}. Skipping ontology grounding.")
        return ""

    # Each entry's score = its best similarity across all query items,
    # remembering which item produced that best match.
    scored = []
    for entry, vec in zip(entries, entry_vecs):
        best_label, best_score = max(
            ((label, _cosine_similarity(qv, vec)) for label, qv in query_vecs),
            key=lambda pair: pair[1],
        )
        scored.append((entry, best_score, best_label))

    ranked = sorted(scored, key=lambda t: t[1], reverse=True)
    selected = ranked[: max(top_k, 1)]

    _print_rag_flow(signal_name, query_items, ranked, selected)

    lines = [
        f"- {entry['term']} (similarity={score:.3f}, matched '{label}'): {entry['definition']} "
        f"(reference terms: {', '.join(entry.get('keywords', []))})"
        for entry, score, label in selected
    ]
    return "\n".join(lines)

def _print_rag_flow(
    signal_name: str,
    query_items: List[Tuple[str, str]],
    ranked: List[Any],
    selected: List[Any],
) -> None:
    """Print the full retrieval flow so it's visible in script output, not just logs."""
    selected_terms = {entry["term"] for entry, _, _ in selected}

    print(f"\n[ontology_rag] signal='{signal_name}'")
    print(f"[ontology_rag] query items ({len(query_items)}): "
          f"{', '.join(label for label, _ in query_items)}")
    print(f"[ontology_rag] ranked candidates ({len(ranked)} total):")
    for rank, (entry, score, label) in enumerate(ranked, start=1):
        marker = "✓ selected" if entry["term"] in selected_terms else ""
        print(f"[ontology_rag]   {rank}. {entry['term']:<20} "
              f"similarity={score:.3f} (via '{label}')  {marker}")
    print(f"[ontology_rag] top_{len(selected)} passed to confidence-check prompt: "
          f"{', '.join(e['term'] for e, _, _ in selected)}\n")
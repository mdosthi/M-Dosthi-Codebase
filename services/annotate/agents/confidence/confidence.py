"""
agents/confidence/confidence.py
-----------------------------
Evaluation logic to verify extraction accuracy against the source text.
"""
from typing import Dict, Any, List
from annotate.llm.router import call_llm
from annotate.llm.json_parser import repair_json
from annotate.utils.logger import log
from annotate.schemas.clinical_schema import ConfidenceResult
from annotate.utils.prompt_loader import format_prompt, load_prompt
from annotate.config.settings import enable_rag, rag_signals
from annotate.agents.confidence.ontology_rag import retrieve_ontology_context

def run_confidence_check(
    signal_name: str,
    extracted_signal: Dict[str, Any],
    conversation: str
) -> ConfidenceResult:
    """Evaluates the quality of an extraction to decide if debate is needed."""
    log(f"confidence_check: evaluating '{signal_name}'...")

    prompt = format_prompt(
        load_prompt(f"{signal_name}_confidence_check"),
        conversation=conversation[:4000],
        **{f"{signal_name}_output": extracted_signal},
    )

    if enable_rag and signal_name in rag_signals:
        context = retrieve_ontology_context(signal_name, extracted_signal, conversation)
        print(f"Retrieved ontology context for '{signal_name}': {context}")
        if context:
            prompt = (
                f"{prompt}\n\n"
                "ONTOLOGY REFERENCE (ground your audit against these clinically "
                "established definitions; this is reference material, not conversation evidence):\n"
                f"{context}\n"
            )
            log(f"confidence_check: '{signal_name}' grounded with ontology RAG context.")

    raw = call_llm(prompt)
    parsed = repair_json(raw)
    
    # Normalize confidence score from 0-10 to 0-1 if needed
    conf_score = float(parsed.get("confidence", 0.5))
    if conf_score > 1.0:
        conf_score = conf_score / 10.0
    conf_score = min(1.0, max(0.0, conf_score))  # Clamp to [0.0, 1.0]
    
    # Ensure issues are strings
    issues_raw = parsed.get("issues", [])
    issues: List[str] = []
    for issue in issues_raw:
        if isinstance(issue, dict):
            # Convert dict to string representation
            issues.append(str(issue))
        else:
            issues.append(str(issue))
    
    return ConfidenceResult(
        confidence=conf_score,
        issues=issues
    )
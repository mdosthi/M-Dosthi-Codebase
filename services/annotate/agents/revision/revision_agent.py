"""
agents/revision/revision_agent.py
---------------------------------
Revision logic to improve low-confidence extractions.
Uses signal-specific prompts from prompts/ folder.
"""
from typing import Dict, Any
from annotate.llm.router import call_llm
from annotate.llm.json_parser import repair_json
from annotate.utils.logger import log
from annotate.utils.prompt_loader import format_prompt, load_prompt

def run_revision(
    signal_name: str,
    current_output: Dict[str, Any],
    conversation: str,
    feedback: str,
) -> Dict[str, Any]:
    """Revises an extraction based on confidence feedback."""
    log(f"revision: revising '{signal_name}' based on feedback...")

    prompt = format_prompt(
        load_prompt(f"{signal_name}_revision"),
        conversation=conversation[:4000],
        original_output=current_output,
        reviewer_feedback=feedback,
    )
    raw = call_llm(prompt)
    return repair_json(raw)

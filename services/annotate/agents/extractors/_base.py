"""Factory for the per-signal extractor agents."""
import sys
from typing import Dict, Any, Callable, Type

from pydantic import BaseModel

from annotate.llm.router import call_llm  # noqa: F401  (patched in tests)
from annotate.llm.json_parser import repair_json
from annotate.utils.prompt_loader import format_prompt, load_prompt
from annotate.utils.logger import log
_MODULE = __name__


def make_extractor(
    name: str,
    schema: Type[BaseModel],
    state_key: str,
    summary: Callable[[BaseModel], str],
):
    def agent(state: Dict[str, Any]) -> Dict[str, Any]:
        log(f"{name}_agent: extracting …")
        prompt = format_prompt(load_prompt(name), conversation=state["chat"])
        response = sys.modules[_MODULE].call_llm(prompt)
        try:
            validated = schema(**repair_json(response))
        except Exception as exc:
            log(f"{name}_agent: validation warning — {exc}. Using defaults.")
            validated = schema()
        log(f"{name}_agent: {summary(validated)}")
        return {state_key: validated.model_dump()}

    agent.__name__ = f"{name}_agent"
    return agent

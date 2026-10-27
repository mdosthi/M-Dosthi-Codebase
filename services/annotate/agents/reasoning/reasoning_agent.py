"""
agents/reasoning/reasoning_agent.py
-------------------------------------
Produces the final training-ready DatasetRow.
"""
from typing import Dict, Any
from annotate.llm.router import call_llm
from annotate.llm.json_parser import repair_json
from annotate.utils.prompt_loader import format_prompt, load_prompt
from annotate.utils.logger import log, log_data
from annotate.schemas.clinical_schema import DatasetRow


def reasoning_agent(state: Dict[str, Any]) -> Dict[str, Any]:
    log("reasoning_agent: producing final dataset row ...")
    prompt = format_prompt(load_prompt("reasoning"),
        conversation=state["chat"],
        consensus=state["consensus"],
    )
    response = call_llm(prompt)
    parsed = repair_json(response)

    try:
        validated = DatasetRow(**parsed)
    except Exception as exc:
        log(f"reasoning_agent: validation warning — {exc}. Attempting partial construction.")
        fallback = {**state["consensus"], **parsed}
        try:
            validated = DatasetRow(**fallback)
        except Exception:
            consensus = state["consensus"]
            validated = DatasetRow(
                stage_of_change=parsed.get("stage_of_change", consensus.get("stage_of_change", "unknown")),
                all_concerns=parsed.get("all_concerns", consensus.get("all_concerns", [])) or [],
                all_triggers=parsed.get("all_triggers", consensus.get("all_triggers", [])) or [],
                quit_attempt_history=parsed.get("quit_attempt_history", consensus.get("quit_attempt_history", "unknown")),
                recommended_intervention=parsed.get("recommended_intervention", consensus.get("recommended_intervention", [])) or [],
            )

    row_dict = validated.model_dump()

    # Inject research metadata. debate_rounds_used now reflects how many
    # passes the workflow's confidence/revision loop took (0 when extractors
    # converged on the first try).
    revision_count = state.get("revision_count", 0)
    row_dict["debate_rounds_used"] = revision_count
    row_dict["vote_agreement"] = state.get("consensus", {}).get("vote_agreement")
    row_dict["suicidal_ideation"] = state.get("consensus", {}).get("suicidal_ideation", False)

    log(
        f"reasoning_agent: done | debate_rounds={revision_count} | "
        f"vote_agreement={row_dict.get('vote_agreement')} | "
        f"suicidal_ideation={row_dict.get('suicidal_ideation')}"
    )
    payload = {"dataset_row": row_dict}
    log_data("reasoning_agent.output", payload)
    return payload

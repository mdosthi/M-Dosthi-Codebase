from annotate.schemas.clinical_schema import (
    AdviceOutput, AttemptOutput, ConcernOutput, ReadinessOutput, TriggerOutput,
)
from annotate.agents.extractors._base import make_extractor

advice_agent = make_extractor(
    name="advice",
    schema=AdviceOutput,
    state_key="advice",
    summary=lambda v: f"found {len(v.advice)} advice item(s).",
)

attempt_agent = make_extractor(
    name="attempt",
    schema=AttemptOutput,
    state_key="attempt",
    summary=lambda v: f"found {len(v.attempts)} attempt(s).",
)

concern_agent = make_extractor(
    name="concern",
    schema=ConcernOutput,
    state_key="concern",
    summary=lambda v: f"found {len(v.concerns)} concern(s).",
)

readiness_agent = make_extractor(
    name="readiness",
    schema=ReadinessOutput,
    state_key="readiness",
    summary=lambda v: f"stage={v.readiness_stage}.",
)

trigger_agent = make_extractor(
    name="trigger",
    schema=TriggerOutput,
    state_key="trigger",
    summary=lambda v: f"found {len(v.triggers)} trigger(s).",
)

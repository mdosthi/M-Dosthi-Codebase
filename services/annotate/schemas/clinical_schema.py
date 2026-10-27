from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any

# ---------------------------------------------------------------------------
# Extractor outputs
# ---------------------------------------------------------------------------

class AdviceOutput(BaseModel):
    advice: List[str] = Field(default_factory=list)
    evidence: List[str] = Field(default_factory=list)


class AttemptOutput(BaseModel):
    attempts: List[str] = Field(default_factory=list)
    evidence: List[str] = Field(default_factory=list)

class ReadinessOutput(BaseModel):
    readiness_stage: str = Field(default="unknown")
    evidence: Optional[str] = None

    @field_validator("readiness_stage")
    @classmethod
    def validate_stage(cls, v: str) -> str:
        allowed = {"precontemplation", "contemplation", "preparation",
                   "action", "maintenance", "relapse", "unknown"}
        normalized = v.strip().lower()
        return normalized if normalized in allowed else "unknown"


class ConcernOutput(BaseModel):
    concerns: List[str] = Field(default_factory=list)
    evidence: List[str] = Field(default_factory=list)


class TriggerOutput(BaseModel):
    triggers: List[str] = Field(default_factory=list)
    evidence: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Evaluation & Confidence
# ---------------------------------------------------------------------------

class ConfidenceResult(BaseModel):
    """The output of the external judge verifying an extraction."""
    confidence: float = Field(..., ge=0.0, le=1.0)
    issues: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Multi-voter Consensus & Arbitration
# ---------------------------------------------------------------------------

class ConsensusVote(BaseModel):
    voter_id: str
    stage_of_change: str = "unknown"
    all_concerns: List[str] = Field(default_factory=list)
    all_triggers: List[str] = Field(default_factory=list)
    quit_attempt_history: str = "unknown"
    recommended_intervention: List[str] = Field(default_factory=list)
    suicidal_ideation: bool = False


class ArbitrationResult(BaseModel):
    stage_of_change: str = "unknown"
    all_concerns: List[str] = Field(default_factory=list)
    all_triggers: List[str] = Field(default_factory=list)
    quit_attempt_history: str = "unknown"
    recommended_intervention: List[str] = Field(default_factory=list)
    suicidal_ideation: bool = False
    vote_agreement: float = Field(default=0.0, ge=0.0, le=1.0)
    dissenting_fields: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Final dataset row (The output of reasoning_agent.py)
# ---------------------------------------------------------------------------
from typing import Dict, List


class ExtractionRound(BaseModel):
    """
    All LLM calls within one extract/revise → confidence cycle.

    Round 1: extractor fields are populated (5 calls); revised_* are None.
    Rounds 2+: extractor fields are None; revised_* are populated only for
               signals whose confidence fell below threshold (1–5 calls).
    Confidence fields are always populated (5 calls per round).
    """
    round_number: int

    # ── Round 1 only: initial extractor outputs ───────────────────────
    advice:    Optional[AdviceOutput]    = None
    attempt:   Optional[AttemptOutput]   = None
    readiness: Optional[ReadinessOutput] = None
    concern:   Optional[ConcernOutput]   = None
    triggers:  Optional[TriggerOutput]   = None

    # ── Rounds 2+: revision outputs (only signals that were revised) ──
    revised_advice:    Optional[AdviceOutput]    = None
    revised_attempt:   Optional[AttemptOutput]   = None
    revised_readiness: Optional[ReadinessOutput] = None
    revised_concern:   Optional[ConcernOutput]   = None
    revised_triggers:  Optional[TriggerOutput]   = None

    # ── Every round: confidence on the most recent output per signal ──
    advice_confidence:    Optional[ConfidenceResult] = None
    attempt_confidence:   Optional[ConfidenceResult] = None
    readiness_confidence: Optional[ConfidenceResult] = None
    concern_confidence:   Optional[ConfidenceResult] = None
    triggers_confidence:  Optional[ConfidenceResult] = None


class AllCalls(BaseModel):
    """
    Complete trace of every LLM call made during a single pipeline run.

    Pipeline call sequence
    ─────────────────────
    1. rounds[0]               — initial extraction + confidence (always present)
    2. rounds[1..N]            — revision rounds (only when confidence < threshold)
    3. consensus_votes         — 3 independent voter calls
    4. arbitration             — 1 call only when vote agreement < threshold
    5. reasoning_summary       — 1 final reasoning call
    6. delta_*                 — longitudinal calls (sessions 2+ only)
    """
    # Extraction + confidence rounds (index 0 = round 1, etc.)
    rounds: List[ExtractionRound] = Field(default_factory=list)

    # Multi-voter consensus (3 calls, always present)
    consensus_votes: List[ConsensusVote] = Field(default_factory=list)

    # Arbitration (1 call, only when voters disagree)
    arbitration: Optional[ArbitrationResult] = None

    # Final reasoning pass (1 call)
    reasoning_summary: Optional[str] = None

    # Longitudinal calls (sessions 2+ only)
    delta_narrative:           Optional[str]            = None
    delta_semantic_diff:       Optional[Dict[str, Any]] = None
    delta_resolved_validation: Optional[Dict[str, Any]] = None


class DatasetRow(BaseModel):
    # Clinical Fields
    stage_of_change: str = Field(default="unknown")
    all_concerns: List[str] = Field(default_factory=list)
    all_triggers: List[str] = Field(default_factory=list)
    quit_attempt_history: str = Field(default="unknown")
    recommended_intervention: List[str] = Field(default_factory=list)

    # Reasoning & Quality Metadata
    reasoning_summary: Optional[str] = None
    
    # Safety Flags
    suicidal_ideation: bool = False

    # Research Metadata (Longitudinal/MAS Trace)
    debate_rounds_used: int = 0
    vote_agreement: float = Field(default=0.0, ge=0.0, le=1.0)

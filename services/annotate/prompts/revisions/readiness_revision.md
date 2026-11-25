You are a clinical annotation reviser.

Task: Produce a corrected readiness stage classification that fully addresses all reviewer feedback.

ORIGINAL CONVERSATION:
{conversation}

ORIGINAL CLASSIFICATION:
{original_output}

REVIEWER FEEDBACK:
{reviewer_feedback}

Revision instructions:
- Re-evaluate the assigned TTM stage in light of the reviewer's contradicting evidence or boundary precision concerns.
- Select the single best-fitting stage from: precontemplation, contemplation, preparation, action, maintenance, relapse.
- Replace or supplement the evidence with patient statements that more unambiguously support the revised stage.
- If the reviewer identified contradicting statements, explain in your evidence selection why the revised stage is still preferred.
- Do not introduce claims or evidence not present in the conversation.
- Update the confidence score to reflect your certainty in the revised classification.

Respond ONLY with valid JSON:
{
  "readiness": "<one of the six TTM stages>",
  "evidence": "<one or two patient statements from the conversation that justify this classification>",
  "confidence": 0.0
}

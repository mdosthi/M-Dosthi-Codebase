You are a clinical annotation reviser.

Task: Produce a corrected quit-attempt extraction that fully addresses all reviewer feedback.

ORIGINAL CONVERSATION:
{conversation}

ORIGINAL EXTRACTION:
{original_output}

REVIEWER FEEDBACK:
{reviewer_feedback}

Revision instructions:
- Remove any hallucinated quit attempts that have no basis in the conversation.
- Add any omitted quit attempts that are genuinely present in the conversation.
- Correct method, duration, or relapse reason fields where the reviewer has flagged inaccuracies.
- Use "unknown" for any detail that is genuinely absent from the conversation — do not infer.
- Do not introduce new items not supported by the conversation or the reviewer feedback.
- Preserve the original JSON field structure.
- Update the confidence score to reflect your certainty in the revised extraction.

Respond ONLY with valid JSON:
{
  "attempts": ["<corrected attempt description 1>", "<corrected attempt description 2>"],
  "evidence": ["<supporting evidence 1>", "<supporting evidence 2>"],
  "confidence": 0.0
}

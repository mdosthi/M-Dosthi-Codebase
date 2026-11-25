You are a clinical annotation reviser.

Task: Produce a corrected concern extraction that fully addresses all reviewer feedback.

ORIGINAL CONVERSATION:
{conversation}

ORIGINAL EXTRACTION:
{original_output}

REVIEWER FEEDBACK:
{reviewer_feedback}

Revision instructions:
- Remove any hallucinated concerns that have no basis in the conversation.
- Add any omitted concerns that are genuinely present in the conversation.
- Correct the severity or intensity of any concern that was underrepresented or overstated (e.g., "terrified" must not be softened to "worried").
- Correct categorization errors (physiological, psychological, social/financial, situational) where flagged.
- Distinguish between active concerns and historical ones if the reviewer has flagged a temporal attribution error.
- Do not introduce new items not supported by the conversation or the reviewer feedback.
- Preserve the original JSON field structure.
- Update the confidence score to reflect your certainty in the revised extraction.

Respond ONLY with valid JSON:
{
  "concerns": ["<corrected concern 1>", "<corrected concern 2>"],
  "evidence": ["<supporting evidence 1>", "<supporting evidence 2>"],
  "confidence": 0.0
}

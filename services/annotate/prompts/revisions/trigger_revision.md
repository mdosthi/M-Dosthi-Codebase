You are a clinical annotation reviser.

Task: Produce a corrected trigger extraction that fully addresses all reviewer feedback.

ORIGINAL CONVERSATION:
{conversation}

ORIGINAL EXTRACTION:
{original_output}

REVIEWER FEEDBACK:
{reviewer_feedback}

Revision instructions:
- Remove any hallucinated triggers that have no basis in the conversation.
- Remove any item that is a motivation to quit, health concern, financial concern, family concern, consequence of smoking, or goal — unless the patient explicitly links it to smoking urges or behavior.
- Add any omitted triggers that are genuinely present in the PATIENT's statements.
- Update evidence entries to match revised triggers (one evidence item per trigger, PATIENT utterances only).
- Do not introduce new items not supported by the conversation or the reviewer feedback.
- If no valid triggers remain after revision, return ["unknown"] for triggers and [] for evidence.
- Update the confidence score to reflect your certainty in the revised extraction.

Respond ONLY with valid JSON:
{
  "triggers": ["<corrected trigger 1>", "<corrected trigger 2>"],
  "evidence": ["<patient utterance supporting trigger 1>", "<patient utterance supporting trigger 2>"],
  "confidence": 0.0
}

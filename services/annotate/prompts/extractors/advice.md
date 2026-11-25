You are a clinical NLP specialist extracting cessation advice from tobacco-cessation counseling transcripts.

CONVERSATION:
{conversation}

Task: Extract every piece of cessation advice or recommendation explicitly given by the COUNSELOR — not the patient.

Strict rules:
- Only include advice that is explicitly stated in the conversation. Do NOT infer, assume, or extrapolate.
- Each advice item must be traceable to a direct quote or close paraphrase.
- Do not include general conversational remarks that are not actionable advice.
- If no advice is present, return empty lists.

For each advice item, provide corresponding evidence (direct quote or close paraphrase from the counselor).

Respond ONLY with valid JSON:
{
  "advice": ["<advice item 1>", "<advice item 2>"],
  "evidence": ["<quote or paraphrase supporting advice 1>", "<quote or paraphrase supporting advice 2>"]
}

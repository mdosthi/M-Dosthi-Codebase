You are a clinical NLP specialist identifying prior smoking quit attempts from tobacco-cessation counseling transcripts.

CONVERSATION:
{conversation}

Task: Identify all prior quit attempts mentioned by the PATIENT.

Definition of a quit attempt: Any instance where the patient intentionally tried to stop or reduce smoking, regardless of outcome or duration. This includes:
- Cold turkey cessation
- Use of aids (nicotine patch, gum, varenicline, bupropion, e-cigarettes to quit, etc.)
- Gradual reduction with intent to quit
- Temporary abstinence (even hours or days)
- Structured or unstructured, self-initiated or guided efforts

Do NOT include:
- Thoughts, desires, or intentions to quit without any action taken
- Future quit plans
- Vague or hypothetical statements with no concrete attempt described

For each valid quit attempt, capture:
- Method used (use "unknown" if not mentioned)
- Duration (use "unknown" if not mentioned)
- Reason for relapse (use "unknown" if not mentioned)

Represent each attempt as a single concise natural-language sentence.
Provide corresponding evidence (exact quote or close paraphrase from the patient) for each attempt in the same order.

Additional rules:
- Focus only on patient statements, not the counselor's.
- Do not infer missing details; use "unknown" when information is absent.
- If a single sentence describes multiple attempts, split them into separate entries.
- If no attempts are found, return empty lists.

Respond ONLY with valid JSON:
{
  "attempts": ["<attempt description 1>", "<attempt description 2>"],
  "evidence": ["<supporting quote or paraphrase 1>", "<supporting quote or paraphrase 2>"]
}

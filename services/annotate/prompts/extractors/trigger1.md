You are a clinical NLP specialist extracting smoking triggers from tobacco-cessation counseling transcripts.

CONVERSATION:
{conversation}

Task: Identify all distinct triggers that prompt the PATIENT to smoke.

Definition of a trigger: Any situation, emotion, activity, or context — explicitly mentioned or clearly implied — that the patient associates with the urge or act of smoking.

Common trigger categories:
- Emotional: stress, anxiety, boredom, sadness, anger
- Situational: after meals, morning routine, work breaks, driving
- Social: drinking alcohol, being around other smokers, social gatherings
- Habitual: coffee or tea, waking up, end of a task

Rules:
- Extract only triggers with clear support in the conversation. Do not infer from general behavior patterns not mentioned.
- Avoid duplicate or near-duplicate entries.
- Keep each trigger concise (1–4 words).
- Provide corresponding evidence (direct quote or close paraphrase from the patient) for each trigger in the same order.
- If no triggers are found, return ["unknown"] for triggers and [] for evidence.

Respond ONLY with valid JSON:
{
  "triggers": ["<trigger 1>", "<trigger 2>"],
  "evidence": ["<quote or paraphrase supporting trigger 1>", "<quote or paraphrase supporting trigger 2>"]
}

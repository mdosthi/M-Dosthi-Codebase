You are a clinical NLP specialist extracting smoking triggers from tobacco-cessation counseling transcripts.

CONVERSATION:
{conversation}

TASK:
Identify all distinct smoking triggers mentioned by the PATIENT.

DEFINITION OF A TRIGGER:
A trigger is a situation, emotion, activity, social context, physical state, routine, or environmental cue that prompts the patient to smoke or feel the urge to smoke.

VALID TRIGGER TYPES:
- Emotional:
  stress, anxiety, sadness, boredom, anger, loneliness
- Situational:
  after meals, during work breaks, driving, studying
- Social:
  being around smokers, parties, drinking alcohol, friends smoking
- Habitual/Routine:
  morning tea, coffee, waking up, before sleep
- Physical/Craving:
  nicotine cravings, withdrawal discomfort

IMPORTANT NEGATIVE RULES:
Do NOT extract:
- reasons for quitting
- motivations to stop smoking
- health concerns
- financial concerns
- family concerns
- consequences of smoking
- goals or intentions
UNLESS they are explicitly described as causing smoking urges or smoking behavior.

EXTRACTION RULES:
- Extract triggers ONLY if clearly supported by the PATIENT's statements.
- Use only PATIENT utterances as evidence.
- Do NOT use BOT paraphrases as evidence.
- Do NOT infer unsupported triggers.
- Avoid duplicates and near-duplicates.
- Keep trigger phrases concise (1–4 words).
- If no valid triggers are present, return:
  {
    "triggers": ["unknown"],
    "evidence": []
  }

OUTPUT FORMAT:
Respond ONLY with valid JSON:
{
  "triggers": ["<trigger 1>", "<trigger 2>"],
  "evidence": ["<evidence 1>", "<evidence 2>"]
}


You are a clinical annotation specialist (voter {voter_id} of {total_voters}).

CONVERSATION:
{conversation}

EXTRACTED SIGNALS:
- Advice: {advice}
- Quit Attempts: {attempts}
- Readiness / Stage: {readiness}
- Concerns: {concerns}
- Triggers: {triggers}

Based on ALL the above signals, produce a unified clinical annotation.
Be independent - do not anchor to previous voters.

IMPORTANT — field sourcing rules:
The "all_concerns", "all_triggers", "recommended_intervention", and "quit_attempt_history" fields MUST be sourced directly from the corresponding Extracted Signals above:
- "all_concerns" must come from the Concerns signal (its "concerns" list). Include EVERY concern the patient expressed in this session — do not pick a single "main" concern, do not drop minor ones. You may lightly normalize wording for consistency.
- "all_triggers" must come from the Triggers signal (its "triggers" list). Include EVERY trigger identified in this session — do not pick a single "primary" trigger, do not drop minor ones. You may lightly normalize wording.
- "recommended_intervention" must come from the Advice signal (its "advice" list). Include only cessation advice the COUNSELOR actually delivered. Do not invent, suggest, or substitute strategies the counselor did not give.
- "quit_attempt_history" must be derived from the Quit Attempts signal (its "attempts" list). Join EVERY attempt listed there verbatim, separated by "; ", into a single string — do NOT paraphrase, summarize, or drop any attempt. If the Quit Attempts signal is empty, set "quit_attempt_history" to "unknown".
- For "all_concerns", "all_triggers", and "recommended_intervention": if the corresponding extracted signal is empty, return an empty list. Do NOT fabricate items to fill the lists.

SUICIDAL IDEATION DETECTION:
Review the full conversation for any direct or indirect expression of suicidal ideation or self-harm intent. Set "suicidal_ideation" to true if ANY of the following are present, false otherwise:
- Explicit statements about wanting to die or end their life
- Expressions of hopelessness tied to a wish not to exist
- References to self-harm or suicide attempts
- Indirect cues such as "I don't want to be here anymore" or "everyone would be better off without me"
Do NOT infer suicidal ideation from general distress, sadness, or smoking-related hopelessness alone.

Respond ONLY with valid JSON:
{
  "stage_of_change": "precontemplation|contemplation|preparation|action|maintenance|relapse",
  "all_concerns": ["<every patient concern from the Concerns signal>", "..."],
  "all_triggers": ["<every trigger from the Triggers signal>", "..."],
  "quit_attempt_history": "<every attempt from the Quit Attempts signal, joined verbatim with '; '>",
  "recommended_intervention": ["<advice item the counselor actually gave>", "..."],
  "suicidal_ideation": false
}

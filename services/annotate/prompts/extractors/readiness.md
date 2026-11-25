You are a clinical psychologist specializing in the Transtheoretical Model (TTM) of behavior change.

CONVERSATION:
{conversation}

Task: Classify the patient's current stage of change for smoking cessation based solely on the conversation.

Stage definitions:
- precontemplation: Not considering quitting in the next 6 months; may deny or minimize the problem.
- contemplation: Aware of the need to quit and considering it within the next 6 months, but not yet committed to action.
- preparation: Planning to quit within the next 30 days; may have already taken small steps (e.g., reduced smoking, set a quit date).
- action: Has quit smoking and maintained abstinence for less than 6 months.
- maintenance: Has maintained abstinence for 6 months or longer and is working to prevent relapse.
- relapse: Previously quit but has resumed smoking.

Select the single best-fitting stage. Cite one or two specific patient statements from the conversation that justify your classification.

Respond ONLY with valid JSON:
{
  "readiness_stage": "<one of the six stages above>",
  "evidence": "<one or two sentences from the conversation that justify this classification>"
}

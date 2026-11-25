You are a clinical reasoning specialist producing the final annotation for a tobacco-cessation chat data.

Task: Validate the consensus annotation against the source conversation and produce a clinically grounded reasoning summary.

CONVERSATION:
{conversation}

CONSENSUS ANNOTATION:
{consensus}

Steps:
1. Verify that every field in the consensus annotation (stage of change, all concerns, all triggers, quit attempt history) is internally consistent and directly supported by the conversation.
2. Flag any field that is unsupported, contradicted, or inconsistent with another field.
3. Write a reasoning_summary (1–2 sentences) that explains: (a) why the patient is at this particular stage of change, (b) what their main barriers to quitting are, and (c) what intervention approach was actually given to the patient by the counselor in this session.

IMPORTANT — list-field copy rule:
The "all_concerns", "all_triggers", and "recommended_intervention" fields must be sourced from the consensus annotation's corresponding lists, which are themselves derived from the conversation:
- Copy items verbatim from consensus.all_concerns, consensus.all_triggers, and consensus.recommended_intervention.
- You may drop an item only if it is clearly contradicted by the conversation (e.g., the patient never expressed that concern, the counselor did not give that advice).
- Do NOT add new concerns, triggers, or interventions that are not in the consensus lists.
- Do NOT collapse the lists into a single "main" or "primary" item — preserve every entry that the conversation supports.

Respond ONLY with valid JSON:
{
  "stage_of_change": "<from consensus>",
  "all_concerns": ["<every concern from consensus.all_concerns>", "..."],
  "all_triggers": ["<every trigger from consensus.all_triggers>", "..."],
  "quit_attempt_history": "<from consensus>",
  "recommended_intervention": ["<advice item the counselor actually gave, copied from consensus>", "..."],
  "reasoning_summary": "<1–2 sentence clinical rationale>"
}

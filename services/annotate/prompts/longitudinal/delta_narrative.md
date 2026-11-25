You are a clinical psychologist reviewing the progress of a tobacco-cessation patient across two counseling sessions.

SESSION {n_minus_1} ANNOTATION:
  Stage of change:  {stage_before}
  Concerns:         {concerns_before}
  Triggers:         {triggers_before}
  Interventions:    {interventions_before}

SESSION {n} ANNOTATION (current):
  Stage of change:  {stage_after}
  Concerns:         {concerns_after}
  Triggers:         {triggers_after}
  Interventions:    {interventions_after}

STRUCTURAL CHANGES DETECTED:
  Stage direction:      {stage_direction}
  New triggers:         {new_triggers}
  Resolved triggers:    {resolved_triggers}
  New concerns:         {new_concerns}
  Resolved concerns:    {resolved_concerns}
  New interventions:    {new_interventions}
  Quit attempt history: {cumulative_quit_history}

Write a concise 2-3 sentence clinical narrative summarising what changed between these two sessions and what it means for the patient's cessation journey. Be specific — reference the actual changes above.

Respond ONLY with valid JSON:
{
  "clinical_summary": "<2-3 sentence narrative>"
}

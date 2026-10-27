You are a clinical NLP specialist identifying patient-reported concerns about quitting smoking from tobacco-cessation counseling transcripts.

CONVERSATION:
{conversation}

Task: Identify all barriers, fears, or concerns the PATIENT expresses about quitting smoking.

Common concern categories include:
- Physiological: withdrawal symptoms, cravings, weight gain, sleep disruption
- Psychological: anxiety, mood changes, fear of failure, stress management
- Social/financial: peer pressure, cost of cessation aids, impact on relationships
- Situational: relapse triggers such as alcohol, social events, or work stress

Rules:
- Only include concerns explicitly stated or strongly implied by the patient.
- Do not include the counselor's statements or general clinical observations.
- Capture the full intensity of the concern — do not water down language (e.g., "terrified of lung cancer" is not the same as "worried about health").
- If no concerns are present, return empty lists.

For each concern, provide corresponding evidence (direct quote or close paraphrase from the patient).

Respond ONLY with valid JSON:
{
  "concerns": ["<concern 1>", "<concern 2>"],
  "evidence": ["<quote or paraphrase supporting concern 1>", "<quote or paraphrase supporting concern 2>"]
}

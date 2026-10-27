You are a Senior Clinical Informatics Specialist specializing in NLP quality assurance for tobacco cessation research.

Task: Audit the quit-attempt extraction below against the source conversation for 100% fidelity.

SOURCE CONVERSATION:
{conversation}

EXTRACTION TO AUDIT:
{attempt_output}

Conduct the following four checks:

1. Grounding and Veracity: Does every extracted attempt have a direct textual anchor in the conversation? Flag any logical leaps where a quit attempt was assumed without explicit confirmation.

2. Hallucination Check: List any data points in the extraction that have no basis in the source text.

3. Omission Check: Scan the conversation for missed signals — keywords such as "stopped," "gave up," "last time I tried," "cut back to zero," or specific dates or durations — that should have been captured.

4. Taxonomy Alignment: Verify that the attempt method (e.g., Cold Turkey, NRT, Pharmacotherapy, Behavioral Support) aligns with established clinical standards.

Scoring rubric:
- 9–10: Perfect recall and precision, no errors.
- 7–8: High utility; minor formatting or non-clinical nuance issues only.
- 5–6: Partial data loss or one significant hallucination.
- Below 5: Unreliable; multiple hallucinations or missed major attempts.

Respond ONLY with valid JSON:
{
  "confidence": 0.0,
  "issues": ["<issue 1>", "<issue 2>"]
}

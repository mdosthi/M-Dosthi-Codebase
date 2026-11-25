You are a clinical assistant reviewing a therapy session transcript for tobacco cessation.

A patient had the following {signal}s noted in a PREVIOUS session:
{prev_items}

CURRENT SESSION TRANSCRIPT:
"""
{transcript}
"""

For each previous {signal} listed above, determine whether the patient has EXPLICITLY stated that this {signal} is no longer a problem, that they have overcome it, or that they no longer experience it.

Rules:
- A {signal} is ONLY resolved if the patient makes an explicit statement of resolution.
- The {signal} NOT being mentioned in the current session does NOT count as resolved.
- Therapist statements alone do not count — the resolution must come from the patient.

Respond ONLY with valid JSON — one entry per previous {signal}:
{
  "resolved_{signal}s": ["<{signal}>", ...],
  "unresolved_{signal}s": ["<{signal}>", ...]
}

You are a clinical assistant helping to compare smoking related {signal}s mentioned across two sessions.

PREVIOUS SESSION {signal}s:
{prev_items}

CURRENT SESSION {signal}s:
{curr_items}

Your tasks:
1. Identify which current {signal}s are genuinely NEW (not semantically equivalent to any previous {signal}).
2. Identify which previous {signal}s are PERSISTENT (still present, even if phrased differently).
3. Write just the {signal} and no other metadata.
Respond ONLY with valid JSON:
{
  "new_{signal}s": ["<{signal}>", ...],
  "persistent_{signal}s": ["<{signal}>", ...]
}

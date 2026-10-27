"""
import annotate.config.settings as cfg
cfg.enable_rag = True
import annotate.agents.confidence.confidence as confmod

result = confmod.run_confidence_check(
    signal_name='trigger',
    extracted_signal={'triggers': ['morning coffee', 'work stress'], 'evidence': ['cigarette with my coffee every morning', 'work stress is a big trigger']},
    conversation='Counselor: What triggers your smoking?\nPatient: I have a cigarette with my coffee every single morning. Also work stress — it was a brutal project and I just cracked one night.',
)
print(result)
"""

import annotate.config.settings as cfg
cfg.enable_rag = True
import annotate.agents.confidence.confidence as confmod

# Negative example: the extractor hallucinated a 'trigger' that is actually a
# health/financial concern and a future quit-goal — per the ontology's
# negative_exclusion rule, neither belongs in 'triggers'. The patient never
# links either to a smoking urge or behavior.
result = confmod.run_confidence_check(
    signal_name='trigger',
    extracted_signal={
        'triggers': ['worried about lung damage', 'cost of cigarettes', 'wanting to be healthy for kids'],
        'evidence': ['my doctor told me my lungs are showing early signs of damage', 'cigarettes are expensive', 'I want to be healthy for my kids'],
    },
    conversation=(
        'Counselor: What brings you in today?\n'
        'Patient: My doctor told me last month that my lungs are showing early signs of damage. That scared me.\n'
        'Counselor: That sounds like a wake-up call.\n'
        'Patient: Also cigarettes are so expensive now, and I want to be healthy for my kids.\n'
        'Counselor: What actually makes you reach for a cigarette?\n'
        'Patient: Honestly, just my morning coffee and stress at work.'
    ),
)
print(result)


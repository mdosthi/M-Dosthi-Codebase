import annotate.config.settings as cfg
cfg.enable_rag = True
from annotate.utils.prompt_loader import format_prompt, load_prompt
from annotate.agents.confidence.ontology_rag import retrieve_ontology_context
from annotate.llm.router import call_llm
from annotate.llm.json_parser import repair_json

signal_name = 'trigger'
extracted_signal = {
    'triggers': ['worried about lung damage', 'cost of cigarettes', 'wanting to be healthy for kids'],
    'evidence': ['my doctor told me my lungs are showing early signs of damage', 'cigarettes are expensive', 'I want to be healthy for my kids'],
}
conversation = (
    'Counselor: What brings you in today?\n'
    'Patient: My doctor told me last month that my lungs are showing early signs of damage. That scared me.\n'
    'Counselor: That sounds like a wake-up call.\n'
    'Patient: Also cigarettes are so expensive now, and I want to be healthy for my kids.\n'
    'Counselor: What actually makes you reach for a cigarette?\n'
    'Patient: Honestly, just my morning coffee and stress at work.'
)

prompt = format_prompt(
    load_prompt(f'{signal_name}_confidence_check'),
    conversation=conversation[:4000],
    **{f'{signal_name}_output': extracted_signal},
)
context = retrieve_ontology_context(signal_name, extracted_signal, conversation)
prompt = f'{prompt}\n\nONTOLOGY REFERENCE (ground your audit against these clinically established definitions; this is reference material, not conversation evidence):\n{context}\n'

raw = call_llm(prompt)
print('--- RAW LLM OUTPUT ---')
print(raw)
print('--- PARSED ---')
print(repair_json(raw))

from annotate.config.model_config import LLM_PROVIDER, TEMPERATURE, OLLAMA_MODEL, GROQ_MODEL, DEEPINFRA_MODEL


def call_llm(prompt: str, model: str | None = None, temperature: float = TEMPERATURE) -> str:
    provider = LLM_PROVIDER.lower()

    if provider == "ollama":
        from annotate.llm.ollama_client import call_ollama
        return call_ollama(prompt, model=model or OLLAMA_MODEL, temperature=temperature)

    if provider == "groq":
        from annotate.llm.groq_client import call_groq
        return call_groq(prompt, model=model or GROQ_MODEL, temperature=temperature)

    if provider == "deepinfra":
        from annotate.llm.deepinfra_client import call_deepinfra
        return call_deepinfra(prompt, model=model or DEEPINFRA_MODEL, temperature=temperature)

    raise ValueError(f"Unknown LLM_PROVIDER: {provider!r}. Choose 'ollama', 'groq', or 'deepinfra'.")

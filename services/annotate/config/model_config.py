import os

LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "ollama")  # "ollama" | "groq" | "deepinfra"

# Shared
TEMPERATURE: float = 0.2
MAX_RETRIES: int = 3
TIMEOUT_SECONDS: int = 600

# Ollama
OLLAMA_URL: str = "http://localhost:11434/api/generate"
#OLLAMA_MODEL: str = "kamekichi128/qwen3-4b-instruct-2507"
#OLLAMA_MODEL: str = "qwen3.5:4b"
OLLAMA_MODEL: str = "frob/qwen3.5-instruct:4b"
# Ollama embeddings (used for ontology RAG retrieval — see agents/confidence/ontology_rag.py)
OLLAMA_EMBED_URL: str = "http://localhost:11434/api/embeddings"
OLLAMA_EMBED_MODEL: str = "embeddinggemma:300m-qat-q4_0"

# Groq
GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
GROQ_URL: str = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL: str = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")

# DeepInfra
DEEPINFRA_API_KEY: str = os.getenv("DEEPINFRA_API_KEY", "")
DEEPINFRA_URL: str = "https://api.deepinfra.com/v1/openai/chat/completions"
DEEPINFRA_MODEL: str = os.getenv("DEEPINFRA_MODEL", "meta-llama/Llama-3.1-8B-Instruct")

# Backward compat alias
MODEL_NAME: str = OLLAMA_MODEL

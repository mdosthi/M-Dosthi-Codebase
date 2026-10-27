import time
import requests
from typing import Dict, Any

from annotate.config.model_config import GROQ_API_KEY, GROQ_MODEL, GROQ_URL, TEMPERATURE, MAX_RETRIES, TIMEOUT_SECONDS
from annotate.utils.logger import log, log_llm_exchange


def call_groq(prompt: str, model: str = GROQ_MODEL, temperature: float = TEMPERATURE) -> str:
    if not GROQ_API_KEY:
        raise RuntimeError("GROQ_API_KEY is not set")

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload: Dict[str, Any] = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
    }

    last_error: Exception | None = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.post(GROQ_URL, json=payload, headers=headers, timeout=TIMEOUT_SECONDS)
            if response.status_code != 200:
                raise RuntimeError(f"Groq HTTP {response.status_code}: {response.text[:5000]}")
            response_text = response.json()["choices"][0]["message"]["content"]
            log_llm_exchange(
                provider="groq",
                model=model,
                temperature=temperature,
                prompt=prompt,
                response_text=response_text,
                attempt=attempt,
                status="success",
            )
            return response_text

        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as exc:
            last_error = exc
            wait = 2 ** attempt
            log(f"[groq_client] Attempt {attempt}/{MAX_RETRIES} failed. Retrying in {wait}s…")
            log_llm_exchange(
                provider="groq",
                model=model,
                temperature=temperature,
                prompt=prompt,
                response_text=str(exc),
                attempt=attempt,
                status=exc.__class__.__name__,
            )
            time.sleep(wait)

        except Exception as exc:
            log_llm_exchange(
                provider="groq",
                model=model,
                temperature=temperature,
                prompt=prompt,
                response_text=str(exc),
                attempt=attempt,
                status="exception",
            )
            raise RuntimeError(f"Groq call failed: {exc}") from exc

    raise RuntimeError(f"Groq unreachable after {MAX_RETRIES} attempts. Last error: {last_error}")

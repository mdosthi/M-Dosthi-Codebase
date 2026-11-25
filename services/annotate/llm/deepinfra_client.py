import time
import requests
from typing import Dict, Any

from annotate.config.model_config import DEEPINFRA_API_KEY, DEEPINFRA_MODEL, DEEPINFRA_URL, TEMPERATURE, MAX_RETRIES, TIMEOUT_SECONDS
from annotate.utils.logger import log, log_llm_exchange


def call_deepinfra(prompt: str, model: str = DEEPINFRA_MODEL, temperature: float = TEMPERATURE) -> str:
    if not DEEPINFRA_API_KEY:
        raise RuntimeError("DEEPINFRA_API_KEY is not set")

    headers = {
        "Authorization": f"Bearer {DEEPINFRA_API_KEY}",
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
            response = requests.post(DEEPINFRA_URL, json=payload, headers=headers, timeout=TIMEOUT_SECONDS)
            if response.status_code != 200:
                raise RuntimeError(f"DeepInfra HTTP {response.status_code}: {response.text[:5000]}")
            response_text = response.json()["choices"][0]["message"]["content"]
            log_llm_exchange(
                provider="deepinfra",
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
            log(f"[deepinfra_client] Attempt {attempt}/{MAX_RETRIES} failed. Retrying in {wait}s…")
            log_llm_exchange(
                provider="deepinfra",
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
                provider="deepinfra",
                model=model,
                temperature=temperature,
                prompt=prompt,
                response_text=str(exc),
                attempt=attempt,
                status="exception",
            )
            raise RuntimeError(f"DeepInfra call failed: {exc}") from exc

    raise RuntimeError(f"DeepInfra unreachable after {MAX_RETRIES} attempts. Last error: {last_error}")

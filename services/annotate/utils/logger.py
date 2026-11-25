import logging
import json
import sys
from typing import Any

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

_logger = logging.getLogger("clinical_pipeline")


def log(msg: str) -> None:
    _logger.info(msg)


def warning(msg: str) -> None:
    _logger.warning(msg)


def error(msg: str) -> None:
    _logger.error(msg)


def log_data(label: str, data: Any) -> None:
    try:
        formatted = json.dumps(data, indent=2, ensure_ascii=False, default=str, sort_keys=True)
    except Exception:
        formatted = repr(data)
    _logger.info(f"{label}:\n{formatted}")


def log_llm_exchange(
    *,
    provider: str,
    model: str,
    temperature: float,
    prompt: str,
    response_text: str,
    attempt: int,
    status: str = "success",
) -> None:
    _logger.debug(
        f"[{provider.upper()}] model={model} attempt={attempt} status={status}"
    )


def log_ollama_exchange(
    *,
    model: str,
    temperature: float,
    prompt: str,
    response_text: str,
    attempt: int,
    status: str = "success",
) -> None:
    log_llm_exchange(
        provider="ollama",
        model=model,
        temperature=temperature,
        prompt=prompt,
        response_text=response_text,
        attempt=attempt,
        status=status,
    )

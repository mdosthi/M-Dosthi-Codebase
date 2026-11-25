from pathlib import Path
import re

_PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"


def _find_md(key: str) -> Path | None:
    """Locate a prompt .md file for *key*.

    Dotted keys (e.g. "consensus.consensus") map directly to
    ``{category}/{name}.md``.  Flat keys (e.g. "advice",
    "attempt_confidence_check") are found by searching every sub-directory.
    """
    if "." in key:
        parts = key.split(".", 1)
        path = _PROMPTS_DIR / parts[0] / f"{parts[1]}.md"
        return path if path.exists() else None

    for path in _PROMPTS_DIR.rglob(f"{key}.md"):
        return path
    return None


def load_prompt(key: str) -> str:
    """Load a prompt from its .md file.

    Accepts dotted keys (``"extractors.concern"``, ``"longitudinal.semantic_diff"``)
    or flat names (``"concern"``, ``"attempt_confidence_check"``).
    """
    path = _find_md(key)
    if path is None:
        stem = Path(key).stem
        path = _find_md(stem)
    if path is None:
        available = sorted(p.stem for p in _PROMPTS_DIR.rglob("*.md"))
        raise FileNotFoundError(
            f"Prompt not found: {key!r}. Available: {', '.join(available)}"
        )
    return path.read_text(encoding="utf-8")


def format_prompt(prompt: str, **kwargs) -> str:
    """Format only known placeholders in a prompt template.

    This avoids interpreting literal JSON braces that appear in prompt examples.
    """
    if not kwargs:
        return prompt

    pattern = re.compile(r"\{(" + "|".join(re.escape(k) for k in kwargs) + r")\}")

    def replace(match):
        k = match.group(1)
        if k not in kwargs:
            raise KeyError(f"Missing prompt placeholder: {k}")
        return str(kwargs[k])

    return pattern.sub(replace, prompt)

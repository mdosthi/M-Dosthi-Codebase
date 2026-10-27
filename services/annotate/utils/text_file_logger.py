from typing import Any


class PromptLogger:
    def __init__(self, output_dir: str | None = None):
        pass

    def save(self, agent: str, prompt: str) -> None:
        pass


class TextFileLogger:
    def __init__(self, output_dir: str | None = None):
        pass

    def save(self, stage: str, signal: str, data: Any) -> None:
        pass

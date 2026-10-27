#!/bin/bash
# Wrapper called by Tomcat (running as root) to launch the annotate pipeline.
# Using a script avoids inline env-var issues with root's restricted shell.

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
export PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}"
# LLM_PROVIDER is read from model_config.py — change the default there to switch providers
export HOME="${HOME:-$SCRIPT_DIR}"

LOG=/tmp/annotate_pipeline.log

echo "[pipeline] $(date '+%Y-%m-%d %H:%M:%S') — starting for patient: $1 ${@:2}" >> "$LOG"

cd "$SCRIPT_DIR" || exit 1

PYTHON_BIN="${PYTHON_BIN:-$SCRIPT_DIR/.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
	PYTHON_BIN="$(command -v python3 || true)"
fi

"$PYTHON_BIN" run_for_patient.py "$@" >> "$LOG" 2>&1

echo "[pipeline] $(date '+%Y-%m-%d %H:%M:%S') — finished for patient: $1 ${@:2}" >> "$LOG"

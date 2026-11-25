#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_FLUTTER="$SCRIPT_DIR/../../flutter/bin/flutter"

if [[ -x "$WORKSPACE_FLUTTER" ]]; then
	FLUTTER_BIN="$WORKSPACE_FLUTTER"
elif command -v flutter >/dev/null 2>&1; then
	FLUTTER_BIN="$(command -v flutter)"
else
	echo "Flutter SDK not found. Install Flutter or place it at ../../flutter relative to this project." >&2
	exit 1
fi

WEB_PORT="${WEB_PORT:-3000}"
echo "Starting Flutter web server at http://127.0.0.1:${WEB_PORT}"
exec "$FLUTTER_BIN" run -d web-server --web-hostname 127.0.0.1 --web-port "$WEB_PORT"
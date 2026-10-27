#!/usr/bin/env bash
# Start the Spring Boot API (port 9090) using values from .env.
set -eu
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$ROOT/.env" ]; then
  while IFS='=' read -r key value; do
    case "$key" in ''|\#*) continue ;; esac
    export "$key=${value%$'\r'}"
  done < "$ROOT/.env"
fi
cd "$ROOT/services/api"
exec ./mvnw spring-boot:run "$@"

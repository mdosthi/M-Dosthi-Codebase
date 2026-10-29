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

is_jdk25() {
  [ -x "$1/bin/java" ] &&
    [ -x "$1/bin/javac" ] &&
    [ -r "$1/release" ] || return 1
  version="$(sed -n 's/^JAVA_VERSION="\([^"]*\)"/\1/p' "$1/release")"
  [ "${version%%.*}" = 25 ]
}

if ! is_jdk25 "${JAVA_HOME:-/nonexistent}" && [ "$(uname)" = Darwin ]; then
  if [ -x /usr/libexec/java_home ]; then
    discovered_jdk="$(/usr/libexec/java_home -v 25 2>/dev/null || true)"
    if is_jdk25 "$discovered_jdk"; then
      JAVA_HOME="$discovered_jdk"
    fi
  fi

  if ! is_jdk25 "${JAVA_HOME:-/nonexistent}" && command -v brew >/dev/null 2>&1; then
    brew_jdk="$(brew --prefix openjdk@25 2>/dev/null || true)/libexec/openjdk.jdk/Contents/Home"
    if is_jdk25 "$brew_jdk"; then
      JAVA_HOME="$brew_jdk"
    fi
  fi
fi

if ! is_jdk25 "${JAVA_HOME:-/nonexistent}"; then
  echo "JDK 25 with java and javac is required. Install it or set JAVA_HOME to its installation directory." >&2
  echo "On macOS with Homebrew: brew install openjdk@25" >&2
  exit 1
fi

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

cd "$ROOT/services/api"
exec ./mvnw spring-boot:run "$@"

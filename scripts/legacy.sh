#!/usr/bin/env bash
# Build and start the legacy stack (Tomcat web app + RMI business logic).
# Usage: scripts/legacy.sh [build|start|stop|run]   (default: run = build + restart)
# Requires JDK 11 (JAVA_HOME or tools/jdk11) with javac and rmic.
set -eu

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LEGACY="$ROOT/services/legacy"
TOMCAT="$ROOT/tools/tomcat9"

# IDE-exported .env placeholders must not override gblinfo.inf.
for name in LEGACY_DB_URL LEGACY_DB_USERNAME LEGACY_DB_PASSWORD; do
  value="${!name:-}"
  case "$value" in
    change-me|your-database-user|jdbc:mysql://localhost:3306/your_database_name*) unset "$name" ;;
  esac
done

is_jdk11_with_rmic() {
  [ -x "$1/bin/java" ] &&
    [ -x "$1/bin/rmic" ] &&
    [ -r "$1/release" ] &&
    grep -Eq '^JAVA_VERSION="11([.]|")' "$1/release"
}

if ! is_jdk11_with_rmic "${JAVA_HOME:-/nonexistent}"; then
  for candidate in "$ROOT/tools/jdk11" /usr/lib/jvm/*; do
    if is_jdk11_with_rmic "$candidate"; then
      JAVA_HOME="$candidate"
      break
    fi
  done
fi

if ! is_jdk11_with_rmic "${JAVA_HOME:-/nonexistent}"; then
  echo "JDK 11 with rmic required. Set JAVA_HOME to a JDK 11 install." >&2
  exit 1
fi
export JAVA_HOME
JAVA_BIN="$JAVA_HOME/bin/java"

[ -f "$LEGACY/runtime/gblinfo.inf" ] && [ -d "$TOMCAT/bin" ] || { echo "Run scripts/setup.sh first." >&2; exit 1; }

build() {
  (cd "$LEGACY/server-src" && ./makeJar.sh)
  (cd "$LEGACY/servlet-src/WEB-INF/classes/src" && ./makeJar.sh)
}

stop() {
  "$TOMCAT/bin/shutdown.sh" >/dev/null 2>&1 || true
  pkill -f iMediXBusinessLogic.jar 2>/dev/null || true
  for _ in {1..10}; do
    if ! pgrep -f '[i]MediXBusinessLogic.jar' >/dev/null; then
      sleep 1
      return 0
    fi
    sleep 1
  done
  echo "Legacy RMI process did not stop; refusing to start another instance." >&2
  return 1
}

start() {
  "$TOMCAT/bin/startup.sh"
  cd "$LEGACY/runtime"
  JAVA_XMS="${LEGACY_JAVA_XMS:-128M}"; JAVA_XMX="${LEGACY_JAVA_XMX:-512M}"
  nohup "$JAVA_BIN" "-Xms$JAVA_XMS" "-Xmx$JAVA_XMX" -javaagent:lib/aspectjweaver-1.6.2.jar \
    --illegal-access=warn --module-path lib/ -jar iMediXBusinessLogic.jar \
    > "$LEGACY/runtime/SystemLog/bl.out" 2>&1 &
  PORT="$(grep -v '<!--' "$TOMCAT/conf/server.xml" | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1)"
  echo "Started. Web UI: http://localhost:${PORT:-8080}/M-Dosthi/  (RMI port 1099)"
}

case "${1:-run}" in
  build) build ;;
  start) start ;;
  stop)  stop ;;
  run)   build; stop; start ;;
  *) echo "Usage: $0 [build|start|stop|run]" >&2; exit 2 ;;
esac

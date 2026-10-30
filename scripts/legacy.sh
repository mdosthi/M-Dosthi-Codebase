#!/usr/bin/env bash
# Build and start the legacy stack (Tomcat web app + RMI business logic).
# Usage: scripts/legacy.sh [build|start|stop|run]   (default: run = build + restart)
# Requires JDK 11 or later with javac. Modern RMI uses dynamic stubs, so rmic
# is not required.
set -eu

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LEGACY="$ROOT/services/legacy"
TOMCAT="$ROOT/tools/tomcat9"

# IDE-exported .env placeholders must not override gblinfo.inf.
case "${LEGACY_DB_URL:-}" in
  *your_database_name*|*your-database*|*change-me*)
    unset LEGACY_DB_URL LEGACY_DB_USERNAME LEGACY_DB_PASSWORD
    ;;
esac

for name in LEGACY_DB_URL LEGACY_DB_USERNAME LEGACY_DB_PASSWORD; do
  value="${!name:-}"
  case "$value" in
    change-me|your-database-user|root|jdbc:mysql://localhost:3306/your_database_name*|jdbc:mysql://localhost:3306/your-database*) unset "$name" ;;
  esac
done

is_supported_jdk() {
  [ -x "$1/bin/java" ] &&
    [ -x "$1/bin/javac" ] &&
    [ -r "$1/release" ] &&
    version="$(sed -n 's/^JAVA_VERSION="\([^"]*\)"/\1/p' "$1/release")" &&
    [ -n "$version" ] &&
    [ "${version%%.*}" -ge 11 ]
}

if is_supported_jdk "${JAVA_HOME:-/nonexistent}"; then
  :
elif [ -x /usr/libexec/java_home ]; then
  JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || true)"
fi

if ! is_supported_jdk "${JAVA_HOME:-/nonexistent}" && command -v brew >/dev/null 2>&1; then
  brew_jdk="$(brew --prefix openjdk@25 2>/dev/null || true)"
  if is_supported_jdk "$brew_jdk/libexec/openjdk.jdk/Contents/Home"; then
    JAVA_HOME="$brew_jdk/libexec/openjdk.jdk/Contents/Home"
  fi
fi

if ! is_supported_jdk "${JAVA_HOME:-/nonexistent}"; then
  for candidate in "$ROOT/tools/jdk11" /usr/lib/jvm/*; do
    if is_supported_jdk "$candidate"; then
      JAVA_HOME="$candidate"
      break
    fi
  done
fi

if ! is_supported_jdk "${JAVA_HOME:-/nonexistent}"; then
  echo "JDK 11 or later with javac required. Set JAVA_HOME to a JDK install." >&2
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
  for pid in $(pgrep -f '[i]MediXBusinessLogic\.jar' || true); do
    [ "$pid" = "$$" ] || kill "$pid" 2>/dev/null || true
  done
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
  case "${LEGACY_ENABLE_TEST_CENTERS:-false}" in
    true) test_center_creation=true ;;
    *) test_center_creation=false ;;
  esac
  CATALINA_OPTS="${CATALINA_OPTS:-} -Dimedix.testCenterCreation=$test_center_creation" \
    "$TOMCAT/bin/startup.sh"
  cd "$LEGACY/runtime"
  JAVA_XMS="${LEGACY_JAVA_XMS:-128M}"; JAVA_XMX="${LEGACY_JAVA_XMX:-512M}"
  LEGACY_RMI_ADVERTISE_HOST="${LEGACY_RMI_ADVERTISE_HOST:-127.0.0.1}"
  nohup "$JAVA_BIN" "-Xms$JAVA_XMS" "-Xmx$JAVA_XMX" \
    "-Djava.rmi.server.hostname=$LEGACY_RMI_ADVERTISE_HOST" \
    -javaagent:lib/aspectjweaver-1.6.2.jar \
    --module-path lib/ -jar iMediXBusinessLogic.jar \
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

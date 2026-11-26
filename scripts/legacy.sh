#!/usr/bin/env bash
# Build and start the M-Dosthi legacy stack (Tomcat web app + RMI business logic).
# Supports both Individual Tomcat (M-Dosthi-Codebase/Tomcat9 -> tools/tomcat9) and Shared Tomcat (SHARED_TOMCAT_HOME).
# Usage: scripts/legacy.sh [build|start|stop|run|status] [--individual|--shared]
set -eu

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LEGACY="$ROOT/services/legacy"
SHARED_TOMCAT_HOME="${SHARED_TOMCAT_HOME:-}"
ACTION="run"
MODE="auto"

for arg in "$@"; do
  case "$arg" in
    build|start|stop|run|status)
      ACTION="$arg"
      ;;
    --shared)
      MODE="shared"
      ;;
    --shared=*)
      MODE="shared"
      SHARED_TOMCAT_HOME="${arg#--shared=}"
      ;;
    --individual|--standalone)
      MODE="individual"
      SHARED_TOMCAT_HOME=""
      ;;
    *)
      echo "Usage: $0 [build|start|stop|run|status] [--individual|--shared[=/path/to/tomcat9]]" >&2
      exit 2
      ;;
  esac
done

if [ "$MODE" = "shared" ] && [ -z "$SHARED_TOMCAT_HOME" ]; then
  if [ -d "$ROOT/../eDosthi codebases/DEVELOPMENT/eDosthi/Tomcat9" ]; then
    SHARED_TOMCAT_HOME="$ROOT/../eDosthi codebases/DEVELOPMENT/eDosthi/Tomcat9"
  else
    echo "--shared requires SHARED_TOMCAT_HOME to be set (or ../eDosthi codebases/DEVELOPMENT/eDosthi/Tomcat9 to exist)." >&2
    exit 1
  fi
fi

INDIVIDUAL_TOMCAT="$ROOT/tools/tomcat9"
TOMCAT="${SHARED_TOMCAT_HOME:-$INDIVIDUAL_TOMCAT}"
PID_FILE="$LEGACY/runtime/iMediXBusinessLogic.pid"
TOMCAT_PID_FILE="$INDIVIDUAL_TOMCAT/logs/tomcat.pid"

if [ -n "$SHARED_TOMCAT_HOME" ]; then
  TOMCAT="$(cd "$TOMCAT" && pwd)" || {
    echo "SHARED_TOMCAT_HOME does not exist: $SHARED_TOMCAT_HOME" >&2
    exit 1
  }
fi

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
  ( [ -x "$1/bin/java" ] || [ -x "$1/bin/java.exe" ] ) &&
    ( [ -x "$1/bin/javac" ] || [ -x "$1/bin/javac.exe" ] ) &&
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
  for candidate in \
    /opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home \
    /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
    "$ROOT/tools/jdk11" \
    /usr/lib/jvm/java-25* /usr/lib/jvm/jdk-25* /usr/lib/jvm/java-21* /usr/lib/jvm/java-17* /usr/lib/jvm/java-11* /usr/lib/jvm/* \
    /opt/jdk* "$HOME/.sdkman/candidates/java/current" \
    "/c/Program Files/Eclipse Adoptium"/jdk-* "/c/Program Files/Java"/jdk-* "/c/Program Files/Microsoft"/jdk-*; do
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

[ -f "$LEGACY/runtime/gblinfo.inf" ] && [ -d "$TOMCAT/bin" ] || { echo "Run scripts/setup.sh first (with the same SHARED_TOMCAT_HOME, if applicable)." >&2; exit 1; }

ensure_context_descriptor() {
  target_tomcat="$1"
  descriptor="$target_tomcat/conf/Catalina/localhost/mDosthi.xml"
  docbase_xml="$(printf '%s' "$ROOT/apps/web" | sed 's/&/\&amp;/g; s/"/\&quot;/g; s/</\&lt;/g; s/>/\&gt;/g')"
  expected="<Context docBase=\"$docbase_xml\" reloadable=\"false\" />"
  if [ -f "$descriptor" ] && [ "$(tr -d '\r\n' < "$descriptor")" = "$expected" ]; then
    return 0
  fi
  mkdir -p "$target_tomcat/conf/Catalina/localhost"
  printf '%s\n' "$expected" > "$descriptor"
}

configure_individual_tomcat_ports() {
  if [ -n "${TOMCAT_HTTP_PORT:-}" ]; then
    sed -i.bak -E "s/<Connector port=\"[0-9]+\" protocol=\"HTTP\/1.1\"/<Connector port=\"$TOMCAT_HTTP_PORT\" protocol=\"HTTP\/1.1\"/" "$INDIVIDUAL_TOMCAT/conf/server.xml"
    rm -f "$INDIVIDUAL_TOMCAT/conf/server.xml.bak"
  fi
  if [ -n "${TOMCAT_SHUTDOWN_PORT:-}" ]; then
    sed -i.bak -E "s/<Server port=\"[0-9]+\" shutdown=\"SHUTDOWN\">/<Server port=\"$TOMCAT_SHUTDOWN_PORT\" shutdown=\"SHUTDOWN\">/" "$INDIVIDUAL_TOMCAT/conf/server.xml"
    rm -f "$INDIVIDUAL_TOMCAT/conf/server.xml.bak"
  fi
}

build() {
  [ -f "$TOMCAT/lib/servlet-api.jar" ] || { echo "Tomcat must provide lib/servlet-api.jar: $TOMCAT" >&2; exit 1; }
  export SERVLET_API_JAR="${SERVLET_API_JAR:-$TOMCAT/lib/servlet-api.jar}"
  (cd "$LEGACY/server-src" && bash ./makeJar.sh)
  (cd "$LEGACY/servlet-src/WEB-INF/classes/src" && bash ./makeJar.sh)
}

is_pid_alive() {
  kill -0 "$1" 2>/dev/null || lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk '{print $2}' | grep -qx "$1"
}

is_our_rmi_running() {
  [ -s "$PID_FILE" ] || return 1
  pid="$(cat "$PID_FILE")"
  case "$pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
  is_pid_alive "$pid" || return 1
  if ps -p "$pid" -o args= >/dev/null 2>&1; then
    ps -p "$pid" -o args= | grep -F -- "$LEGACY/runtime/iMediXBusinessLogic.jar" >/dev/null
  else
    return 0
  fi
}

individual_http_port() {
  port="$(grep -v '<!--' "$INDIVIDUAL_TOMCAT/conf/server.xml" 2>/dev/null | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1 || true)"
  echo "${port:-8081}"
}

is_individual_tomcat_running() {
  if [ -s "$TOMCAT_PID_FILE" ]; then
    tpid="$(cat "$TOMCAT_PID_FILE")"
    case "$tpid" in
      ''|*[!0-9]*) ;;
      *)
        if is_pid_alive "$tpid"; then
          return 0
        fi
        ;;
    esac
  fi
  ind_port="$(individual_http_port)"
  listen_pid="$(lsof -iTCP:"$ind_port" -sTCP:LISTEN -P -n -t 2>/dev/null | head -1 || true)"
  if [ -n "$listen_pid" ]; then
    echo "$listen_pid" > "$TOMCAT_PID_FILE"
    return 0
  fi
  return 1
}

stop_rmi() {
  [ -s "$PID_FILE" ] || return 0
  if ! is_our_rmi_running; then
    rm -f "$PID_FILE"
    return 0
  fi
  pid="$(cat "$PID_FILE")"
  kill "$pid" 2>/dev/null || true
  for _ in {1..10}; do
    if ! is_pid_alive "$pid"; then
      rm -f "$PID_FILE"
      sleep 1
      return 0
    fi
    sleep 1
  done
  echo "M-Dosthi RMI process did not stop; refusing to start another instance." >&2
  return 1
}

stop_individual_tomcat() {
  if is_individual_tomcat_running; then
    tpid="$(cat "$TOMCAT_PID_FILE")"
    "$INDIVIDUAL_TOMCAT/bin/shutdown.sh" >/dev/null 2>&1 || true
    for _ in {1..10}; do
      if ! is_pid_alive "$tpid"; then
        rm -f "$TOMCAT_PID_FILE"
        return 0
      fi
      sleep 1
    done
    kill "$tpid" 2>/dev/null || true
    sleep 1
    if ! is_pid_alive "$tpid"; then
      rm -f "$TOMCAT_PID_FILE"
      return 0
    fi
    echo "M-Dosthi Individual Tomcat (PID $tpid) did not stop; refusing to leave stale state." >&2
    return 1
  else
    rm -f "$TOMCAT_PID_FILE"
  fi
}

stop() {
  if [ -z "$SHARED_TOMCAT_HOME" ]; then
    stop_individual_tomcat
  fi
  stop_rmi
}

start() {
  WEB_RMI_PORT="$(sed -n 's/^[[:space:]]*03)[[:space:]]*blport[[:space:]]*=[[:space:]]*//p' "$ROOT/apps/web/config.info" | head -1)"
  SERVER_RMI_PORT="$(sed -n 's/^[[:space:]]*blport[[:space:]]*=[[:space:]]*//p' "$LEGACY/runtime/gblinfo.inf" | head -1)"
  if [ -z "$WEB_RMI_PORT" ] || [ "$WEB_RMI_PORT" != "$SERVER_RMI_PORT" ]; then
    echo "M-Dosthi RMI ports must match in apps/web/config.info and services/legacy/runtime/gblinfo.inf." >&2
    exit 1
  fi

  if [ -n "$SHARED_TOMCAT_HOME" ]; then
    [ -f "$TOMCAT/conf/Catalina/localhost/mDosthi.xml" ] || {
      echo "Missing shared Tomcat context descriptor ($TOMCAT/conf/Catalina/localhost/mDosthi.xml). Run scripts/setup.sh --shared first." >&2
      exit 1
    }
  else
    ensure_context_descriptor "$INDIVIDUAL_TOMCAT"
    mkdir -p "$INDIVIDUAL_TOMCAT/logs" "$INDIVIDUAL_TOMCAT/temp" "$INDIVIDUAL_TOMCAT/work"
    configure_individual_tomcat_ports
    if is_individual_tomcat_running; then
      echo "M-Dosthi Individual Tomcat is already running (PID $(cat "$TOMCAT_PID_FILE"))."
    else
      case "${LEGACY_ENABLE_TEST_CENTERS:-false}" in
        true) test_center_creation=true ;;
        *) test_center_creation=false ;;
      esac
      CATALINA_OPTS="${CATALINA_OPTS:-} -Dimedix.testCenterCreation=$test_center_creation" \
        "$INDIVIDUAL_TOMCAT/bin/startup.sh"
    fi
  fi

  if is_our_rmi_running; then
    echo "M-Dosthi RMI is already running (PID $(cat "$PID_FILE"), port $SERVER_RMI_PORT)."
  else
    cd "$LEGACY/runtime"
    JAVA_XMS="${LEGACY_JAVA_XMS:-128M}"; JAVA_XMX="${LEGACY_JAVA_XMX:-512M}"
    LEGACY_RMI_ADVERTISE_HOST="${LEGACY_RMI_ADVERTISE_HOST:-127.0.0.1}"
    nohup "$JAVA_BIN" "-Xms$JAVA_XMS" "-Xmx$JAVA_XMX" \
      "-Djava.rmi.server.hostname=$LEGACY_RMI_ADVERTISE_HOST" \
      -javaagent:lib/aspectjweaver-1.6.2.jar \
      --module-path lib/ -jar "$LEGACY/runtime/iMediXBusinessLogic.jar" \
      > "$LEGACY/runtime/SystemLog/bl.out" 2>&1 &
    echo "$!" > "$PID_FILE"
  fi

  PORT="$(grep -v '<!--' "$TOMCAT/conf/server.xml" | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1)"
  if [ -n "$SHARED_TOMCAT_HOME" ]; then
    echo "Started. Web UI: http://localhost:${PORT:-8080}/mDosthi/ (RMI port $SERVER_RMI_PORT)"
    echo "Mode: Shared Tomcat ($TOMCAT) - Tomcat lifecycle is externally managed."
  else
    echo "Started. Web UI: http://localhost:${PORT:-8081}/mDosthi/ (RMI port $SERVER_RMI_PORT)"
    echo "Mode: M-Dosthi Individual Tomcat ($INDIVIDUAL_TOMCAT)"
  fi
}

status() {
  SERVER_RMI_PORT="$(sed -n 's/^[[:space:]]*blport[[:space:]]*=[[:space:]]*//p' "$LEGACY/runtime/gblinfo.inf" | head -1)"
  IND_PORT="$(grep -v '<!--' "$INDIVIDUAL_TOMCAT/conf/server.xml" | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1)"
  if is_our_rmi_running; then
    echo "M-Dosthi RMI:               RUNNING (PID $(cat "$PID_FILE"), port ${SERVER_RMI_PORT:-1100})"
  else
    echo "M-Dosthi RMI:               STOPPED"
  fi
  if is_individual_tomcat_running; then
    echo "M-Dosthi Individual Tomcat: RUNNING (PID $(cat "$TOMCAT_PID_FILE"), http://localhost:${IND_PORT:-8081}/mDosthi/)"
  else
    echo "M-Dosthi Individual Tomcat: STOPPED (configured for http://localhost:${IND_PORT:-8081}/mDosthi/)"
  fi
  if [ -n "$SHARED_TOMCAT_HOME" ]; then
    SH_PORT="$(grep -v '<!--' "$TOMCAT/conf/server.xml" | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1)"
    if [ -s "$TOMCAT/logs/tomcat.pid" ] && is_pid_alive "$(cat "$TOMCAT/logs/tomcat.pid")"; then
      echo "Shared Tomcat:              RUNNING (PID $(cat "$TOMCAT/logs/tomcat.pid"), http://localhost:${SH_PORT:-8080}/mDosthi/)"
    else
      echo "Shared Tomcat:              EXTERNAL / PID UNKNOWN (configured for http://localhost:${SH_PORT:-8080}/mDosthi/ at $TOMCAT)"
    fi
  fi
}

case "$ACTION" in
  build)  build ;;
  start)  start ;;
  stop)   stop ;;
  status) status ;;
  run)    stop; build; start ;;
esac

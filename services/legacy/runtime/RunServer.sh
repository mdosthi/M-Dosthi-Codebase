#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

JAVA_BIN="${JAVA_HOME:+$JAVA_HOME/bin/java}"
if [ -z "${JAVA_BIN}" ]; then
  JAVA_BIN="$(command -v java || true)"
fi
if [ -z "${JAVA_BIN}" ] || [ ! -x "${JAVA_BIN}" ]; then
  if [ -x "/usr/libexec/java_home" ]; then
    JAVA_BIN="$(/usr/libexec/java_home -v 11 2>/dev/null)/bin/java"
  fi
fi
if [ -z "${JAVA_BIN}" ] || [ ! -x "${JAVA_BIN}" ]; then
  echo "Java runtime not found. Set JAVA_HOME or install JDK 11." >&2
  exit 1
fi

# JVM flags must come before -jar. Override these values for a larger deployment.
JAVA_XMS="${LEGACY_JAVA_XMS:-128M}"
JAVA_XMX="${LEGACY_JAVA_XMX:-512M}"
"$JAVA_BIN" "-Xms$JAVA_XMS" "-Xmx$JAVA_XMX" -javaagent:lib/aspectjweaver-1.6.2.jar --illegal-access=warn --module-path lib/ -jar iMediXBusinessLogic.jar

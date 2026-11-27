#!/usr/bin/env bash
# One-time local setup for Linux/macOS (Windows: use setup.ps1, or run this in WSL/Git Bash).
# Supports both Individual Tomcat (M-Dosthi-Codebase/Tomcat9 -> tools/tomcat9) and Shared Tomcat (SHARED_TOMCAT_HOME).
set -eu

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOMCAT_VERSION="${TOMCAT_VERSION:-9.0.98}"
SHARED_TOMCAT_HOME="${SHARED_TOMCAT_HOME:-}"
MODE="auto"

for arg in "$@"; do
  case "$arg" in
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
      echo "Usage: $0 [--individual|--shared[=/path/to/tomcat9]]" >&2
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

INDIVIDUAL_TOMCAT_HOME="$ROOT/tools/tomcat9"
TOMCAT_HOME="${SHARED_TOMCAT_HOME:-$INDIVIDUAL_TOMCAT_HOME}"
DEFAULT_RMI_PORT=1100
LEGACY_RMI_PORT="${LEGACY_RMI_PORT:-$DEFAULT_RMI_PORT}"
cd "$ROOT"

if [ -n "$SHARED_TOMCAT_HOME" ]; then
  TOMCAT_HOME="$(cd "$TOMCAT_HOME" && pwd)" || {
    echo "SHARED_TOMCAT_HOME does not exist: $SHARED_TOMCAT_HOME" >&2
    exit 1
  }
fi

case "$LEGACY_RMI_PORT" in
  ''|*[!0-9]*|0)
    echo "LEGACY_RMI_PORT must be a valid TCP port number." >&2
    exit 1
    ;;
esac
[ "$LEGACY_RMI_PORT" -le 65535 ] || {
  echo "LEGACY_RMI_PORT must be between 1 and 65535." >&2
  exit 1
}

[ -f .env ] || { cp .env.example .env; echo "Created .env - edit it and set real values."; }

mkdir -p services/legacy/runtime/{temp,SystemLog,GenSqlLog} tools

if [ ! -d "$INDIVIDUAL_TOMCAT_HOME/bin" ]; then
  echo "Downloading M-Dosthi Individual Tomcat $TOMCAT_VERSION ..."
  curl -fSL "https://archive.apache.org/dist/tomcat/tomcat-9/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" -o tools/tomcat.tar.gz
  mkdir -p "$INDIVIDUAL_TOMCAT_HOME" && tar -xzf tools/tomcat.tar.gz -C "$INDIVIDUAL_TOMCAT_HOME" --strip-components=1
  rm tools/tomcat.tar.gz
  chmod +x "$INDIVIDUAL_TOMCAT_HOME"/bin/*.sh
fi

ln -sfn tools/tomcat9 "$ROOT/Tomcat9"
mkdir -p "$INDIVIDUAL_TOMCAT_HOME/logs" "$INDIVIDUAL_TOMCAT_HOME/temp" "$INDIVIDUAL_TOMCAT_HOME/work"

read_http_port() {
  if [ -f "$1/conf/server.xml" ]; then
    grep -v '<!--' "$1/conf/server.xml" | grep -oE '<Connector port="[0-9]+" protocol="HTTP/1.1"' | grep -oE '[0-9]+' | head -1 || true
  fi
}

if [ -n "$SHARED_TOMCAT_HOME" ]; then
  DEFAULT_HTTP_PORT="$(read_http_port "$TOMCAT_HOME")"
  CONFIG_HTTP_PORT="${TOMCAT_HTTP_PORT:-${DEFAULT_HTTP_PORT:-8080}}"
else
  DEFAULT_HTTP_PORT="$(read_http_port "$INDIVIDUAL_TOMCAT_HOME")"
  CONFIG_HTTP_PORT="${TOMCAT_HTTP_PORT:-${DEFAULT_HTTP_PORT:-8081}}"
fi

render() { # template -> target (only if target is missing)
  [ -f "$2" ] && return 0
  sed -e "s|@PROJECT_ROOT@|$ROOT|g" \
      -e "s|@LEGACY_RMI_PORT@|$LEGACY_RMI_PORT|g" \
      -e "s|@TOMCAT_HTTP_PORT@|$CONFIG_HTTP_PORT|g" "$1" > "$2"
  echo "Generated $2 - review credentials."
}
render services/legacy/runtime/gblinfo.inf.template services/legacy/runtime/gblinfo.inf
render apps/web/config.info.template apps/web/config.info
render apps/web/WEB-INF/classes/mail.properties.template apps/web/WEB-INF/classes/mail.properties
render apps/web/jspfiles/whatsappConfig.jsp.template apps/web/jspfiles/whatsappConfig.jsp

DOCBASE_XML="$(printf '%s' "$ROOT/apps/web" | sed 's/&/\&amp;/g; s/"/\&quot;/g; s/</\&lt;/g; s/>/\&gt;/g')"
EXPECTED_CONTEXT="<Context docBase=\"$DOCBASE_XML\" reloadable=\"false\" />"

write_context_descriptor() {
  target_tomcat="$1"
  mkdir -p "$target_tomcat/conf/Catalina/localhost"
  for context_name in M-Dosthi mDosthi; do
    descriptor="$target_tomcat/conf/Catalina/localhost/$context_name.xml"
    if [ ! -f "$descriptor" ] || [ "$(tr -d '\r\n' < "$descriptor")" != "$EXPECTED_CONTEXT" ]; then
      printf '%s\n' "$EXPECTED_CONTEXT" > "$descriptor"
    fi
  done
}

# Always configure M-Dosthi's own individual Tomcat
write_context_descriptor "$INDIVIDUAL_TOMCAT_HOME"

# Also configure Shared Tomcat when SHARED_TOMCAT_HOME is specified
if [ -n "$SHARED_TOMCAT_HOME" ]; then
  [ -x "$TOMCAT_HOME/bin/catalina.sh" ] && [ -f "$TOMCAT_HOME/lib/servlet-api.jar" ] || {
    echo "SHARED_TOMCAT_HOME must point to a Tomcat 9 installation with catalina.sh and servlet-api.jar." >&2
    exit 1
  }
  write_context_descriptor "$TOMCAT_HOME"
fi

case "$(uname -s)" in
  Darwin)
    if [ -d /opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home ]; then
      export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home}"
      export PATH="$JAVA_HOME/bin:$PATH"
    fi
    for p in /opt/homebrew/share/flutter/bin /opt/homebrew/opt/mysql/bin /opt/homebrew/bin /usr/local/mysql/bin /usr/local/bin; do
      [ -d "$p" ] && export PATH="$p:$PATH"
    done
    ;;
  Linux)
    for jdk in /usr/lib/jvm/java-25* /usr/lib/jvm/jdk-25* /usr/lib/jvm/temurin-25* /opt/jdk-25* "$HOME/.sdkman/candidates/java/current"; do
      if [ -x "$jdk/bin/java" ] && [ -x "$jdk/bin/javac" ]; then
        export JAVA_HOME="${JAVA_HOME:-$jdk}"
        export PATH="$JAVA_HOME/bin:$PATH"
        break
      fi
    done
    for p in "$HOME/flutter/bin" /opt/flutter/bin /snap/bin "$HOME/.local/bin"; do
      [ -d "$p" ] && export PATH="$p:$PATH"
    done
    ;;
  MINGW*|MSYS*|CYGWIN*)
    for jdk in "/c/Program Files/Eclipse Adoptium"/jdk-25* "/c/Program Files/Java"/jdk-25* "/c/Program Files/Microsoft"/jdk-25*; do
      if [ -x "$jdk/bin/java.exe" ] || [ -x "$jdk/bin/java" ]; then
        export JAVA_HOME="${JAVA_HOME:-$jdk}"
        export PATH="$JAVA_HOME/bin:$PATH"
        break
      fi
    done
    for p in "/c/Program Files/MySQL"/MySQL\ Server*/bin "/c/src/flutter/bin" "$HOME/flutter/bin"; do
      [ -d "$p" ] && export PATH="$p:$PATH"
    done
    ;;
esac

check() { command -v "$1" >/dev/null 2>&1 && echo "  ok      $1" || echo "  MISSING $1 ($2)"; }
echo "Prerequisites:"
check java "JDK 11 or later for legacy, JDK 25 for services/api"
check javac "JDK, not just a JRE"
check mvn "or use services/api/mvnw"
check mysql "MySQL 8 client and server"
check flutter "only for apps/mobile"
echo "Configured M-Dosthi Individual Tomcat: $INDIVIDUAL_TOMCAT_HOME (and $ROOT/Tomcat9)"
if [ -n "$SHARED_TOMCAT_HOME" ]; then
  echo "Configured M-Dosthi in Shared Tomcat:  $TOMCAT_HOME"
  echo "Restart that Shared Tomcat to load the /mDosthi context, or run scripts/legacy.sh --individual to use M-Dosthi's own Tomcat."
fi
echo "Done. See docs/setup.md for the next steps."

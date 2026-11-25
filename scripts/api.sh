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
  ( [ -x "$1/bin/java" ] || [ -x "$1/bin/java.exe" ] ) &&
    ( [ -x "$1/bin/javac" ] || [ -x "$1/bin/javac.exe" ] ) &&
    [ -r "$1/release" ] || return 1
  version="$(sed -n 's/^JAVA_VERSION="\([^"]*\)"/\1/p' "$1/release")"
  [ "${version%%.*}" = 25 ]
}

if ! is_jdk25 "${JAVA_HOME:-/nonexistent}"; then
  case "$(uname -s)" in
    Darwin)
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
      ;;
    Linux)
      for candidate in /usr/lib/jvm/java-25* /usr/lib/jvm/jdk-25* /usr/lib/jvm/temurin-25* /opt/jdk-25* "$HOME/.sdkman/candidates/java/"*; do
        if is_jdk25 "$candidate"; then
          JAVA_HOME="$candidate"
          break
        fi
      done
      ;;
    MINGW*|MSYS*|CYGWIN*)
      for candidate in "/c/Program Files/Eclipse Adoptium"/jdk-25* "/c/Program Files/Java"/jdk-25* "/c/Program Files/Microsoft"/jdk-25*; do
        if is_jdk25 "$candidate"; then
          JAVA_HOME="$candidate"
          break
        fi
      done
      ;;
  esac
fi

if ! is_jdk25 "${JAVA_HOME:-/nonexistent}"; then
  echo "JDK 25 with java and javac is required. Install it or set JAVA_HOME to its installation directory." >&2
  echo "  macOS (Homebrew): brew install openjdk@25" >&2
  echo "  Linux (Ubuntu/Debian): sudo apt install openjdk-25-jdk (or Temurin/SDKMAN)" >&2
  echo "  Windows (winget): winget install EclipseAdoptium.Temurin.25.JDK" >&2
  exit 1
fi

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

cd "$ROOT/services/api"
if [ -z "$(find src/main/java -name '*.java' -print -quit 2>/dev/null)" ]; then
  if [ ! -f target/classes/imedix/saMiX/SaMiXApplication.class ] && [ -f target/saMiX-0.0.1-SNAPSHOT.jar.original.zip ]; then
    unzip -qo target/saMiX-0.0.1-SNAPSHOT.jar.original.zip -d target/classes -x application.properties META-INF/\*
    cp src/main/resources/application.properties target/classes/application.properties
  fi
  exec ./mvnw spring-boot:run -Dmaven.main.skip=true "$@"
fi
exec ./mvnw spring-boot:run "$@"

#!/usr/bin/env bash
# One-time local setup for Linux/macOS (Windows: use setup.ps1, or run this in WSL/Git Bash).
set -eu

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TOMCAT_VERSION="${TOMCAT_VERSION:-9.0.98}"
cd "$ROOT"

[ -f .env ] || { cp .env.example .env; echo "Created .env - edit it and set real values."; }

render() { # template -> target (only if target is missing)
  [ -f "$2" ] && return 0
  sed "s|@PROJECT_ROOT@|$ROOT|g" "$1" > "$2"
  echo "Generated $2 - review credentials."
}
render services/legacy/runtime/gblinfo.inf.template services/legacy/runtime/gblinfo.inf
render apps/web/config.info.template apps/web/config.info

mkdir -p services/legacy/runtime/{temp,SystemLog,GenSqlLog} tools

if [ ! -d tools/tomcat9/bin ]; then
  echo "Downloading Tomcat $TOMCAT_VERSION ..."
  curl -fSL "https://archive.apache.org/dist/tomcat/tomcat-9/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" -o tools/tomcat.tar.gz
  mkdir -p tools/tomcat9 && tar -xzf tools/tomcat.tar.gz -C tools/tomcat9 --strip-components=1
  rm tools/tomcat.tar.gz
  chmod +x tools/tomcat9/bin/*.sh
fi

mkdir -p tools/tomcat9/conf/Catalina/localhost
cat > tools/tomcat9/conf/Catalina/localhost/M-Dosthi.xml <<EOF
<Context docBase="$ROOT/apps/web" reloadable="false" />
EOF

check() { command -v "$1" >/dev/null 2>&1 && echo "  ok      $1" || echo "  MISSING $1 ($2)"; }
echo "Prerequisites:"
check java "JDK 11 for legacy, JDK 25 for services/api"
check javac "JDK, not just a JRE"
check mvn "or use services/api/mvnw"
check mysql "MySQL 8 client; server may run via docker compose"
check flutter "only for apps/mobile"
echo "Done. See docs/setup.md for the next steps."

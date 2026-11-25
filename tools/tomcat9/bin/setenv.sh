#!/usr/bin/env bash
if [ -z "${JAVA_HOME:-}" ]; then
  for candidate in \
    "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" \
    "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home" \
    "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" \
    "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home" \
    "/usr/lib/jvm/java-25-openjdk-amd64" \
    "/usr/lib/jvm/java-21-openjdk-amd64" \
    "/usr/lib/jvm/java-17-openjdk-amd64" \
    "/usr/lib/jvm/default-java"; do
    if [ -x "$candidate/bin/java" ]; then
      export JAVA_HOME="$candidate"
      break
    fi
  done
fi
export JDK_JAVA_OPTIONS="${JDK_JAVA_OPTIONS:-} --add-exports=java.xml.crypto/com.sun.org.apache.xml.internal.security.utils=ALL-UNNAMED --add-opens=java.xml.crypto/com.sun.org.apache.xml.internal.security.utils=ALL-UNNAMED"
export CATALINA_PID="$CATALINA_BASE/logs/tomcat.pid"

MDOSTHI_ROOT=""
REAL_CATALINA_HOME="$(cd -P "$CATALINA_HOME" 2>/dev/null && pwd || true)"
for candidate_root in "$REAL_CATALINA_HOME/.." "$REAL_CATALINA_HOME/../.."; do
  resolved_root="$(cd -P "$candidate_root" 2>/dev/null && pwd || true)"
  if [ -n "$resolved_root" ] && [ -d "$resolved_root/apps/web" ]; then
    MDOSTHI_ROOT="$resolved_root"
    break
  fi
done

if [ -n "$MDOSTHI_ROOT" ]; then
  descriptor="$CATALINA_BASE/conf/Catalina/localhost/M-Dosthi.xml"
  docbase_xml="$(printf '%s' "$MDOSTHI_ROOT/apps/web" | sed 's/&/\&amp;/g; s/"/\&quot;/g; s/</\&lt;/g; s/>/\&gt;/g')"
  expected="<Context docBase=\"$docbase_xml\" reloadable=\"false\" />"
  if [ ! -f "$descriptor" ] || [ "$(tr -d '\r\n' < "$descriptor")" != "$expected" ]; then
    mkdir -p "$CATALINA_BASE/conf/Catalina/localhost"
    printf '%s\n' "$expected" > "$descriptor"
  fi
fi

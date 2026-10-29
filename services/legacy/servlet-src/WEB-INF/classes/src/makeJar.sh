set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../../../../../../" && pwd)"
LEGACY_DIR="$PROJECT_ROOT/services/legacy"
WEBAPP_DIR="$PROJECT_ROOT/apps/web"
JDK_HOME="${JAVA_HOME:-$PROJECT_ROOT/tools/jdk11}"
WORK_DIR="$(pwd)"

cp -r "$LEGACY_DIR/server-src/imedix" "$WORK_DIR"
mkdir -p "$WORK_DIR/imedixservlets" "$WEBAPP_DIR/WEB-INF/classes/imedix"

"$JDK_HOME/bin/javac" -classpath ".:$LEGACY_DIR/server-src/ftp.jar:$LEGACY_DIR/server-src:$LEGACY_DIR/external-lib/*:" -d "$WORK_DIR" *.java

SERVLET_CP="${SERVLET_API_JAR:-$PROJECT_ROOT/tools/tomcat9/lib/servlet-api.jar}"
"$JDK_HOME/bin/javac" -classpath ".:$LEGACY_DIR/server-src/ftp.jar:$LEGACY_DIR/server-src:$LEGACY_DIR/external-lib/*:$SERVLET_CP" -d "$WORK_DIR/src_servlet" *.java
cp -r "$WORK_DIR/src_servlet/imedixservlets/"* "$WORK_DIR/imedixservlets"
cp -r "$WORK_DIR/imedix/"*.class "$WEBAPP_DIR/WEB-INF/classes/imedix"

"$JDK_HOME/bin/jar" -cf  imedix.jar imedix/*.class
"$JDK_HOME/bin/jar" -cf  telem.jar telem/*.class
"$JDK_HOME/bin/jar" -cf  tuberculosis.jar tuberculosis/*.class
"$JDK_HOME/bin/jar" -cf  phiv.jar phiv/*.class
"$JDK_HOME/bin/jar" -cf  onlinegc.jar onlinegc/*.class
"$JDK_HOME/bin/jar" -cf  logger.jar logger/*.class
"$JDK_HOME/bin/jar" -cf  imedixservlets.jar imedixservlets/*.class
cp -r *.jar "$WEBAPP_DIR/WEB-INF/lib"

echo done

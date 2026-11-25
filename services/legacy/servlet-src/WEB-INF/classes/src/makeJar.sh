set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../../../../../../" && pwd)"
LEGACY_DIR="$PROJECT_ROOT/services/legacy"
WEBAPP_DIR="$PROJECT_ROOT/apps/web"
JDK_HOME="${JAVA_HOME:-$PROJECT_ROOT/tools/jdk11}"
WORK_DIR="$(pwd)"
CP_SEP=":"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) CP_SEP=";" ;;
esac

cp -r "$LEGACY_DIR/server-src/imedix" "$WORK_DIR"
mkdir -p "$WORK_DIR/imedixservlets" "$WEBAPP_DIR/WEB-INF/classes/imedix"

"$JDK_HOME/bin/javac" --release 11 -classpath ".${CP_SEP}$LEGACY_DIR/server-src/ftp.jar${CP_SEP}$LEGACY_DIR/server-src${CP_SEP}$LEGACY_DIR/external-lib/*${CP_SEP}" -d "$WORK_DIR" *.java

SERVLET_CP="${SERVLET_API_JAR:-${SHARED_TOMCAT_HOME:-$PROJECT_ROOT/tools/tomcat9}/lib/servlet-api.jar}"
"$JDK_HOME/bin/javac" --release 11 -classpath ".${CP_SEP}$LEGACY_DIR/server-src/ftp.jar${CP_SEP}$LEGACY_DIR/server-src${CP_SEP}$LEGACY_DIR/external-lib/*${CP_SEP}$SERVLET_CP" -d "$WORK_DIR/src_servlet" *.java
cp -r "$WORK_DIR/src_servlet/imedixservlets/"* "$WORK_DIR/imedixservlets"
cp -r "$WORK_DIR/imedix/"*.class "$WEBAPP_DIR/WEB-INF/classes/imedix"

"$JDK_HOME/bin/jar" -cf  imedix.jar imedix/*.class
"$JDK_HOME/bin/jar" -cf  telem.jar telem/*.class
"$JDK_HOME/bin/jar" -cf  tuberculosis.jar tuberculosis/*.class
"$JDK_HOME/bin/jar" -uf tuberculosis.jar -C "$LEGACY_DIR/server-src" tuberculosis/tbOperationsInterface.class -C "$LEGACY_DIR/server-src" tuberculosis/tbOperations_Stub.class
"$JDK_HOME/bin/jar" -cf  phiv.jar phiv/*.class
"$JDK_HOME/bin/jar" -uf phiv.jar -C "$LEGACY_DIR/server-src" phiv/phivdataentryinterface.class -C "$LEGACY_DIR/server-src" phiv/phivdataentry_Stub.class
"$JDK_HOME/bin/jar" -cf  onlinegc.jar onlinegc/*.class
"$JDK_HOME/bin/jar" -uf onlinegc.jar -C "$LEGACY_DIR/server-src" onlinegc/onlineinterface.class -C "$LEGACY_DIR/server-src" onlinegc/onlinecommunicator_Stub.class
"$JDK_HOME/bin/jar" -cf  logger.jar logger/*.class
"$JDK_HOME/bin/jar" -uf logger.jar -C "$LEGACY_DIR/server-src" logger/imedixloggerInterface.class -C "$LEGACY_DIR/server-src" logger/imedixlogger_Stub.class
"$JDK_HOME/bin/jar" -cf  imedixservlets.jar imedixservlets/*.class
cp -r *.jar "$WEBAPP_DIR/WEB-INF/lib"
cp "$LEGACY_DIR/external-lib/commons-codec-1.7.jar" "$WEBAPP_DIR/WEB-INF/lib/"
cp "$LEGACY_DIR/external-lib/json-simple-1.1.1.jar" "$WEBAPP_DIR/WEB-INF/lib/"

echo done

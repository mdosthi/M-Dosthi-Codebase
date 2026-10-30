set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
LEGACY_DIR="$PROJECT_ROOT/services/legacy"
JDK_HOME="${JAVA_HOME:-$PROJECT_ROOT/tools/jdk11}"
WORK_DIR="$(pwd)"

"$JDK_HOME/bin/javac" --release 11 -classpath ".:$LEGACY_DIR/server-src/ftp.jar:$LEGACY_DIR/external-lib/*:" -d "$WORK_DIR" *.java
"$JDK_HOME/bin/jar" -cf imedix.jar imedix/*.class
"$JDK_HOME/bin/jar" -cf tuberculosis.jar tuberculosis/*.class
"$JDK_HOME/bin/jar" -cf phiv.jar phiv/*.class
"$JDK_HOME/bin/jar" -cf logger.jar logger/*.class
"$JDK_HOME/bin/jar" -cf onlinegc.jar onlinegc/*.class
"$JDK_HOME/bin/jar" -cmf imedixserver.txt iMediXBusinessLogic.jar imedixserver/*.class

cp *.jar "$LEGACY_DIR/runtime/lib/"
cp iMediXBusinessLogic.jar "$LEGACY_DIR/runtime/"

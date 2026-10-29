set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
LEGACY_DIR="$PROJECT_ROOT/services/legacy"
JDK_HOME="${JAVA_HOME:-$PROJECT_ROOT/tools/jdk11}"
WORK_DIR="$(pwd)"

"$JDK_HOME/bin/javac" -classpath ".:$LEGACY_DIR/server-src/ftp.jar:$LEGACY_DIR/external-lib/*:" -d "$WORK_DIR" *.java
"$JDK_HOME/bin/jar" -cf imedix.jar imedix/*.class
"$JDK_HOME/bin/jar" -cf tuberculosis.jar tuberculosis/*.class
"$JDK_HOME/bin/jar" -cf phiv.jar phiv/*.class
"$JDK_HOME/bin/jar" -cf logger.jar logger/*.class
"$JDK_HOME/bin/jar" -cf onlinegc.jar onlinegc/*.class
"$JDK_HOME/bin/jar" -cmf imedixserver.txt iMediXBusinessLogic.jar imedixserver/*.class

"$JDK_HOME/bin/rmic" imedix.dbGenOperations
"$JDK_HOME/bin/rmic" imedix.CentreInfo
"$JDK_HOME/bin/rmic" imedix.UserInfo
"$JDK_HOME/bin/rmic" imedix.PatqueueInfo
"$JDK_HOME/bin/rmic" imedix.ItemlistInfo
"$JDK_HOME/bin/rmic" imedix.DataEntryFrm
"$JDK_HOME/bin/rmic" imedix.DisplayData
"$JDK_HOME/bin/rmic" imedix.AdminJobs
"$JDK_HOME/bin/rmic" imedix.SmsApi
"$JDK_HOME/bin/rmic" imedix.VideoConference
"$JDK_HOME/bin/rmic" phiv.phivdataentry
"$JDK_HOME/bin/rmic" imedix.graphsinfo
"$JDK_HOME/bin/rmic" tuberculosis.tbOperations
"$JDK_HOME/bin/rmic" logger.imedixlogger

cp *.jar "$LEGACY_DIR/runtime/lib/"
cp iMediXBusinessLogic.jar "$LEGACY_DIR/runtime/"

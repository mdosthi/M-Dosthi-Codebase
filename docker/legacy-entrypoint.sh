#!/bin/sh
set -eu
umask 077

mode="${1:-}"

write_legacy_config() {
  : "${LEGACY_DB_URL:?LEGACY_DB_URL is required}"
  : "${LEGACY_DB_USERNAME:?LEGACY_DB_USERNAME is required}"
  : "${LEGACY_DB_PASSWORD:?LEGACY_DB_PASSWORD is required}"

  cat > /opt/mdosthi/services/legacy/runtime/gblinfo.inf <<EOF
gblcentercode = ${IMEDIX_CENTER_CODE:-VBCR019}
gbldbjdbccriver = com.mysql.cj.jdbc.Driver
gbldburl = ${LEGACY_DB_URL}
gbldbusername = ${LEGACY_DB_USERNAME}
gbldbpasswd = ${LEGACY_DB_PASSWORD}
blport = 1099
tempdatadir = /var/lib/mdosthi/temp
ftphost = 127.0.0.1
ftpuser = ${LEGACY_FTP_USERNAME:-}
ftppasswd = ${LEGACY_FTP_PASSWORD:-}
ftpdocsendpath = doc/Send
ps_home = http://localhost:8080
CenterTypeMSPS = PS
SystemLogger = yes
SystemLoggerPath = /var/lib/mdosthi/SystemLog
GeneralSqlLog = yes
GeneralSqlLogPath = /var/lib/mdosthi/GenSqlLog
EOF
}

case "$mode" in
  rmi)
    write_legacy_config
    cd /opt/mdosthi/services/legacy/runtime
    exec java \
      "-Xms${LEGACY_JAVA_XMS:-128M}" \
      "-Xmx${LEGACY_JAVA_XMX:-512M}" \
      "-Djava.rmi.server.hostname=${LEGACY_RMI_ADVERTISE_HOST:-legacy-rmi}" \
      -javaagent:lib/aspectjweaver-1.6.2.jar \
      --module-path lib/ \
      -jar iMediXBusinessLogic.jar
    ;;
  web)
      awk '
        BEGIN {
          center = ENVIRON["IMEDIX_CENTER_CODE"]
          if (center == "") center = "VBCR019"
          rmi = ENVIRON["LEGACY_RMI_ADVERTISE_HOST"]
          if (rmi == "") rmi = "legacy-rmi"
          pacs_uid = ENVIRON["PACS_UID"]
          pacs_password = ENVIRON["PACS_PASSWORD"]
        }
        {
          gsub(/@PROJECT_ROOT@/, "/opt/mdosthi")
          if (index($0, "gblcentercode =") > 0) $0 = "01) gblcentercode = " center
          if (index($0, "blip =") > 0) $0 = "02) blip = " rmi
          if (index($0, "gblroot =") > 0) $0 = "04) gblroot = /usr/local/tomcat"
          if (index($0, "gbltemp =") > 0) $0 = "08) gbltemp = /usr/local/tomcat/webapps/M-Dosthi/temp"
          if (index($0, "PACSuid =") > 0) $0 = "13) PACSuid = " pacs_uid
          if (index($0, "PACSpass =") > 0) $0 = "14) PACSpass = " pacs_password
          print
        }' /opt/mdosthi/apps/web/config.info.template > /usr/local/tomcat/webapps/M-Dosthi/config.info
    exec /usr/local/tomcat/bin/catalina.sh run
    ;;
  *)
    echo "Usage: legacy-entrypoint.sh [rmi|web]" >&2
    exit 2
    ;;
esac

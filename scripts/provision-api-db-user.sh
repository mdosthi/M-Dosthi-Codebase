#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy .env.example to .env and configure database values." >&2
  exit 1
fi

while IFS='=' read -r key value; do
  value="${value%$'\r'}"
  case "$key" in
    SPRING_DATASOURCE_USERNAME) app_user="$value" ;;
    SPRING_DATASOURCE_PASSWORD) app_password="$value" ;;
    MYSQL_ROOT_PASSWORD) root_password="$value" ;;
    MYSQL_DATABASE) database="$value" ;;
    MYSQL_ADMIN_HOST) admin_host="$value" ;;
    MYSQL_ADMIN_PORT) admin_port="$value" ;;
  esac
done < "$ENV_FILE"

app_user="${app_user:-}"
app_password="${app_password:-}"
root_password="${root_password:-}"
database="${database:-mDosthi}"
admin_host="${admin_host:-127.0.0.1}"
admin_port="${admin_port:-3306}"

if [[ -z "$app_user" || -z "$app_password" || -z "$root_password" ]]; then
  echo "Set SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD, and MYSQL_ROOT_PASSWORD in .env." >&2
  exit 1
fi

if [[ ! "$app_user" =~ ^[A-Za-z0-9_]+$ || ! "$database" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "The application username and database name may contain only letters, digits, and underscores." >&2
  exit 1
fi

if [[ ! "$admin_host" =~ ^[A-Za-z0-9.-]+$ || ! "$admin_port" =~ ^[0-9]+$ ]]; then
  echo "MYSQL_ADMIN_HOST or MYSQL_ADMIN_PORT is invalid." >&2
  exit 1
fi

sql_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\'/\'\'}"
  printf "'%s'" "$value"
}

quoted_user="$(sql_quote "$app_user")"
quoted_password="$(sql_quote "$app_password")"

MYSQL_PWD="$root_password" mysql \
  --protocol=TCP \
  --host="$admin_host" \
  --port="$admin_port" \
  --user=root \
  <<SQL
CREATE USER IF NOT EXISTS $quoted_user@'%' IDENTIFIED BY $quoted_password;
ALTER USER $quoted_user@'%' IDENTIFIED BY $quoted_password;
GRANT ALL PRIVILEGES ON \`$database\`.* TO $quoted_user@'%';
SQL

echo "Provisioned the non-root API account for database '$database'."

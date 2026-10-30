#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! docker compose ps --status running --services | grep -Fxq mysql; then
  echo "The local MySQL Compose service must be running. Start it with: docker compose up -d mysql" >&2
  exit 1
fi

mysql_in_container() {
  docker compose exec -T mysql sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql --batch --skip-column-names -u"$MYSQL_USER" "$MYSQL_DATABASE" "$@"' \
    sh "$@"
}

database_name="$(mysql_in_container -e 'SELECT DATABASE()')"
if [ "$database_name" != "mDosthi" ]; then
  echo "Refusing to initialize schema '$database_name'; expected the local mDosthi database." >&2
  exit 1
fi

existing_tables="$(mysql_in_container -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name IN ('login', 'med', 'center', 'lpatq', 'tpatq', 'tpatwaitq')")"
if [ "$existing_tables" != "0" ]; then
  echo "Refusing to modify an existing legacy schema. This bootstrap is only for a fresh local database." >&2
  exit 1
fi

read -r -p "Development admin user ID [devadmin]: " admin_uid
admin_uid="${admin_uid:-devadmin}"
if [[ ! "$admin_uid" =~ ^[A-Za-z0-9._@-]{1,64}$ ]]; then
  echo "Use a user ID of 1-64 letters, numbers, dots, underscores, @ signs, or hyphens." >&2
  exit 1
fi

read -r -s -p "Development admin password (12+ characters, or same as user ID): " admin_password
printf '\n'
if [ "$admin_password" != "$admin_uid" ] && [ "${#admin_password}" -lt 12 ]; then
  unset admin_password
  echo "Use a password with at least 12 characters, or use the user ID as the password for this local-only test." >&2
  exit 1
fi
if [ "$admin_password" = "$admin_uid" ]; then
  echo "Warning: matching the user ID is weak; use this only in a disposable local database." >&2
fi
read -r -s -p "Repeat password: " admin_password_repeat
printf '\n'
if [ "$admin_password" != "$admin_password_repeat" ]; then
  unset admin_password admin_password_repeat
  echo "Passwords do not match." >&2
  exit 1
fi
unset admin_password_repeat

password_hash="$(printf '%s' "$admin_password" | openssl dgst -md5 | awk '{print $NF}')"
unset admin_password
if [[ ! "$password_hash" =~ ^[[:xdigit:]]{32}$ ]]; then
  echo "Could not generate the legacy password hash." >&2
  exit 1
fi

mysql_in_container < database/dev/legacy-minimal-login.sql
mysql_in_container <<SQL
INSERT INTO login (
    uid, pwd, name, crtdate, type, dis, rg_no, center, active, verified
) VALUES (
    '$admin_uid', '$password_hash', 'Local Development Admin', NOW(),
    'adm', '', 'ADMXXXX0001', 'XXXX', 'Y', 'A'
);
SQL

echo "Created local development admin '$admin_uid'."
echo "This database contains a minimal local testing schema, not the full application schema."
echo "Set services/legacy/runtime/gblinfo.inf database username/password to the local Compose API account from .env."

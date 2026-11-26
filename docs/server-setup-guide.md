# All-in-One Server Setup & Deployment Guide (mDosthi Alongside Existing eDosthi)

Complete, copy-paste reference for uploading and running **`M-Dosthi-Codebase`** on a Linux server **where `eDosthi` is already installed and running** — supporting **both**:
- **Guide A — Shared Tomcat Mode (`:8080`)**: Mounts `/mDosthi/` onto eDosthi's existing Tomcat 9 (`:8080`) alongside `/eDosthi/`, with M-Dosthi RMI on `:1100`.
- **Guide B — Individual Tomcat Mode (`:8081`)**: Runs M-Dosthi on its own bundled Tomcat 9 (`M-Dosthi-Codebase/Tomcat9 -> tools/tomcat9` on `:8081`, shutdown `:8006`) + M-Dosthi RMI (`:1100`), **zero touch and zero restart to eDosthi's Tomcat (`:8080`)**.

Works **with or without GitHub**, **with or without a domain / third-party tools**, and from **Linux or macOS** workstations.

> [!IMPORTANT]
> - **`eDosthi` is already on the server — do NOT upload `eDosthi codebases/` and do NOT modify eDosthi source files.** You only upload `M-Dosthi-Codebase`.
> - **Never commit secrets to Git.** Keep `.env`, credential files, `*.pid`, `*.log`, `apps/web/config.info`, and `services/legacy/runtime/gblinfo.inf` out of version control.
> - **Never expose internal ports publicly.** Keep MySQL (`3306`) and Java RMI (`1099`, `1100`) restricted to `127.0.0.1`.
> - Replace placeholders (`YOUR_SERVER_IP`, `YOUR_SERVER_USER`, `YOUR_DB_PASSWORD`) with real values — never wrap values in `<` or `>` in shell commands.

---

## 1. Exact File & Directory Locations (Server vs. Local)

### 1.1 Server Layout (`Server -> M-Dosthi-Codebase` Alongside Existing `eDosthi`)
```text
/home/YOUR_SERVER_USER/                                  # Server home directory ($HOME)
│
├── eDosthi/                                             # [ALREADY ON SERVER — DO NOT UPLOAD]
│   ├── eDosthi-BL/                                      # Existing eDosthi RMI (:1099)
│   │   ├── RunServer.sh
│   │   └── gblinfo.inf                                  # blport = 1099, DB = eDosthi
│   └── Tomcat9/                                         # [SHARED_TOMCAT_HOME] HTTP :8080, shutdown :8005
│       ├── bin/startup.sh, shutdown.sh, setenv.sh
│       ├── lib/servlet-api.jar
│       ├── webapps/eDosthi/                             # Existing /eDosthi/ web app + config.info
│       ├── conf/Catalina/localhost/
│       │   └── mDosthi.xml                             # [Created ONLY in Guide A: Shared Mode] -> points to M-Dosthi-Codebase/apps/web
│       ├── work/Catalina/localhost/mDosthi/            # [Shared Mode] Compiled JSP cache
│       └── logs/catalina.out, tomcat.pid
│
└── M-Dosthi-Codebase/                                   # [UPLOADED TO SERVER — /home/YOUR_SERVER_USER/M-Dosthi-Codebase]
    ├── .env                                             # [Server-only] Spring Boot API DB & JWT secret (if running API)
    ├── Tomcat9 -> tools/tomcat9                         # [Individual Mode] Root symlink to tools/tomcat9
    ├── tools/tomcat9/                                   # [Individual Mode] HTTP :8081, shutdown :8006
    │   ├── bin/startup.sh, shutdown.sh, setenv.sh
    │   ├── conf/server.xml                              # Port 8081 (HTTP), Port 8006 (Shutdown)
    │   ├── conf/Catalina/localhost/mDosthi.xml         # [Individual Mode] -> points docBase to $MDOSTHI_DIR/apps/web
    │   ├── work/Catalina/localhost/mDosthi/            # [Individual Mode] Compiled JSP cache
    │   └── logs/catalina.out, tomcat.pid                # [Individual Mode] Logs & Tomcat PID
    ├── apps/web/
    │   ├── config.info                                  # [Server-only] 03) blport=1100, 05) gblhome=..., 06) gbltelemedix=/mDosthi
    │   ├── temp/                                        # [Server-only] Runtime upload/session temp dir
    │   └── WEB-INF/lib/*.jar                            # Built by ./scripts/legacy.sh build
    └── services/legacy/runtime/
        ├── gblinfo.inf                                  # [Server-only] blport=1100, DB=mDosthi, credentials & log paths
        ├── iMediXBusinessLogic.jar                      # Built by ./scripts/legacy.sh build
        ├── iMediXBusinessLogic.pid                      # [Server-only] M-Dosthi RMI PID (isolated from eDosthi RMI)
        ├── SystemLog/bl.out                             # [Server-only] M-Dosthi RMI stdout/access logs
        ├── GenSqlLog/                                   # [Server-only] M-Dosthi SQL logs
        └── temp/                                        # [Server-only] M-Dosthi RMI temp dir
```

### 1.2 Local Workstation Layout (`Linux` or `macOS`)
```text
CodeBase/                                                # e.g. /Users/dipayanrana/Desktop/CodeBase (macOS) or ~/CodeBase (Linux)
├── eDosthi codebases/                                   # DO NOT UPLOAD (already running on server)
└── M-Dosthi-Codebase/                                   # <-- UPLOAD / PUSH ONLY THIS FOLDER TO SERVER
    ├── Tomcat9 -> tools/tomcat9                         # Symlink to bundled Individual Tomcat 9
    ├── tools/tomcat9/                                   # Bundled Individual Tomcat (:8081, shutdown :8006)
    │   ├── bin/setenv.sh, startup.sh, shutdown.sh
    │   ├── conf/server.xml                              # <Server port="8006">, <Connector port="8081">
    │   └── lib/servlet-api.jar, mysql-connector-j-8.4.0.jar
    ├── apps/
    │   ├── web/                                         # Legacy Web JSP + CSS + WEB-INF (used by BOTH modes)
    │   │   ├── index.jsp                                # Staff login page (<title>mDosthi</title>)
    │   │   ├── config.info.template                     # Template -> generates local apps/web/config.info
    │   │   ├── style/mdosthi-brand-tokens.css           # Brand design tokens & fonts
    │   │   ├── style/mdosthi-login.css                  # Responsive login styles
    │   │   ├── bootstrap/css/index.css                  # Responsive post-login dashboard styles
    │   │   ├── jspfiles/index1.jsp, patindex.jsp, ...   # Post-login portals & clinical pages
    │   │   └── WEB-INF/lib/*.jar                        # Compiled servlet & RMI stub JARs
    │   └── mobile/                                      # Flutter Web / Mobile app (mdosthi_app)
    ├── services/
    │   ├── legacy/
    │   │   ├── server-src/                              # M-Dosthi RMI Java sources + makeJar.sh
    │   │   ├── servlet-src/WEB-INF/classes/src/         # Servlet Java sources (projinfo.java, cook.java, makeJar.sh)
    │   │   └── runtime/
    │   │       ├── gblinfo.inf.template                 # Template -> generates local gblinfo.inf
    │   │       └── RunServer.sh                         # Starts iMediXBusinessLogic.jar
    │   └── api/                                         # Spring Boot REST API (:9090)
    │       └── src/main/resources/db/manual/
    │           ├── V20261029_01__pipeline_job_queue.sql
    │           └── V20261113_01__complete_api_schema.sql
    ├── database/migrations/*.sql                        # M-Dosthi screening & monitoring SQL migrations
    └── scripts/
        ├── setup.sh                                     # --shared=/path/to/Tomcat9  OR  --individual
        ├── legacy.sh                                    # build | start | stop | status  (--shared | --individual)
        └── api.sh                                       # Starts Spring Boot API (:9090)
```

### 1.3 Port & Coexistence Map on the Server

| Service | Port | Process / Exact Config Path | Shared Mode (`--shared`) | Individual Mode (`--individual`) |
| :--- | :--- | :--- | :--- | :--- |
| **MySQL Server** | `3306` | Native OS `mysqld` (`127.0.0.1` only) | Already running (`eDosthi` + `mDosthi` DBs) | Already running (`eDosthi` + `mDosthi` DBs) |
| **eDosthi RMI** | `1099` | `$EDOSTHI_DIR/eDosthi-BL/gblinfo.inf` | Already running (untouched) | Already running (untouched) |
| **eDosthi Tomcat 9** | `8080` (shutdown `8005`) | `$EDOSTHI_DIR/Tomcat9/conf/server.xml` | Serves **both** `/eDosthi/` and `/mDosthi/` | Serves `/eDosthi/` only (**untouched**) |
| **M-Dosthi RMI** | `1100` | `$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf` | Started via `./scripts/legacy.sh start --shared` | Started via `./scripts/legacy.sh start --individual` |
| **M-Dosthi Individual Tomcat 9** | `8081` (shutdown `8006`) | `$MDOSTHI_DIR/tools/tomcat9/conf/server.xml` | Stopped / unused | Serves `/mDosthi/` on `:8081` |
| **Spring Boot REST API** *(optional)* | `9090` | `$MDOSTHI_DIR/.env` & `scripts/api.sh` | Optional (for Flutter app) | Optional (for Flutter app) |

---

## 2. Connect to the Server & Locate Existing `eDosthi` Paths

### 2.1 SSH into the Server (from Linux or macOS)
```bash
ssh YOUR_SERVER_USER@YOUR_SERVER_IP
```
Enter the **server SSH password** when prompted (used for `ssh`, `rsync`, `scp`, and `sudo`).
*(Optional one-time passwordless SSH setup from your local machine: `ssh-copy-id YOUR_SERVER_USER@YOUR_SERVER_IP`.)*

### 2.2 Discover Exact Existing `eDosthi` & Java Paths on the Server
Run this right after logging into the server:
```bash
ps aux | grep -E "catalina|iMediXBusinessLogic" | grep -v grep
which java javac mysql
java -version
```
From the output, note:
1. **`EDOSTHI_TOMCAT`** (from `-Dcatalina.home=...`, e.g., `/home/YOUR_SERVER_USER/eDosthi/Tomcat9` or `/opt/eDosthi/Tomcat9`).
2. **Server target path**: upload `M-Dosthi-Codebase` directly under your server folder (`/home/YOUR_SERVER_USER/M-Dosthi-Codebase`, i.e., `$HOME/M-Dosthi-Codebase`).
3. **JDK path**: `legacy` compiles and runs on **JDK 11+** (or JDK 25); `services/api` requires **JDK 25** (`sudo apt update && sudo apt install -y openjdk-25-jdk` on Ubuntu/Debian if only JDK 11 is installed and you need `services/api` or Tomcat `--add-opens` flags).

---

## 3. Upload Only `M-Dosthi-Codebase` to the Server

Choose **Option A (With GitHub)** or **Option B (Without GitHub — Direct `rsync` over SSH)**.

### Option A: With GitHub (Push from Local Machine → Clone/Pull on Server)
1. On **your local Linux or macOS machine**:
   ```bash
   # macOS example: /Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase
   # Linux example: $HOME/CodeBase/M-Dosthi-Codebase
   LOCAL_MDOSTHI_DIR="/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase"

   cd "$LOCAL_MDOSTHI_DIR" && \
   git checkout -- flutter_web.pid 2>/dev/null || true && \
   git add apps/web apps/mobile docs/server-setup-guide.md && \
   git commit -m "fix: legacy login, brand tokens, responsive UI, and dual-mode server guide" && \
   git fetch origin && \
   git pull --no-rebase origin main && \
   git push origin main
   ```
2. On **the server**:
   ```bash
   MDOSTHI_DIR="$HOME/M-Dosthi-Codebase"

   if [ -d "$MDOSTHI_DIR/.git" ]; then
     git -C "$MDOSTHI_DIR" pull origin main
   else
     git clone https://github.com/mdosthi/M-Dosthi-Codebase.git "$MDOSTHI_DIR"
   fi
   ```
   *(If private, enter your GitHub username and Personal Access Token.)*

### Option B: Without GitHub (Direct `rsync` over SSH — Uploads `M-Dosthi-Codebase` Including `tools/tomcat9`)
Run on **your local Linux or macOS machine**:
```bash
LOCAL_MDOSTHI_DIR="/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase"
SERVER_USER="YOUR_SERVER_USER"
SERVER_IP="YOUR_SERVER_IP"
REMOTE_MDOSTHI_DIR="/home/$SERVER_USER/M-Dosthi-Codebase"

ssh "$SERVER_USER@$SERVER_IP" "mkdir -p '$REMOTE_MDOSTHI_DIR'"

rsync -avz --progress \
  --exclude='.git/' \
  --exclude='.DS_Store' \
  --exclude='.env' \
  --exclude='*.pid' \
  --exclude='*.log' \
  --exclude='apps/web/config.info' \
  --exclude='apps/web/temp/*' \
  --exclude='services/legacy/runtime/gblinfo.inf' \
  --exclude='services/legacy/runtime/SystemLog/*' \
  --exclude='services/legacy/runtime/GenSqlLog/*' \
  --exclude='services/legacy/runtime/temp/*' \
  --exclude='tools/tomcat9/conf/Catalina/localhost/*.xml' \
  --exclude='tools/tomcat9/logs/*' \
  --exclude='tools/tomcat9/work/*' \
  --exclude='tools/tomcat9/temp/*' \
  --exclude='apps/mobile/build/' \
  --exclude='apps/mobile/.dart_tool/' \
  "$LOCAL_MDOSTHI_DIR/" \
  "$SERVER_USER@$SERVER_IP:$REMOTE_MDOSTHI_DIR/"
```
*(Notice `tools/tomcat9/` **is included**—only its local `logs/`, `work/`, `temp/`, and local `mDosthi.xml` are excluded—so both `--shared` and `--individual` work out of the box on the server even without internet access!)*

---

## 4. Create & Populate the `mDosthi` Database on the Server (Leaves `eDosthi` DB Untouched)

MySQL is already running on the server (`127.0.0.1:3306`) for `eDosthi`. Create a separate **`mDosthi`** database and dedicated MySQL user.

### 4.1 Create `mDosthi` Schema & User (Run on Server)
```bash
DB_USER="mdosthi_user"
DB_PASS="ChooseAStrongPassword123!"

sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS mDosthi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON mDosthi.* TO '$DB_USER'@'127.0.0.1';
GRANT ALL PRIVILEGES ON mDosthi.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQL
```

### 4.2 Populate `mDosthi` (Choose Option 1 or Option 2 — First Time Only)

#### Option 1: Upload Your Ready Local `mDosthi` Database Dump (Recommended if Local DB Already Has All Migrations)
On **your local Linux or macOS machine**:
```bash
mysqldump --host=127.0.0.1 -u root -p mDosthi > /tmp/mDosthi_export.sql
scp /tmp/mDosthi_export.sql YOUR_SERVER_USER@YOUR_SERVER_IP:~/mDosthi_export.sql
rm -f /tmp/mDosthi_export.sql
```
On **the server**:
```bash
LC_ALL=C sed 's/DEFINER=`root`@`%`/DEFINER=`root`@`localhost`/g' ~/mDosthi_export.sql > /tmp/mDosthi_clean.sql
mysql --host=127.0.0.1 -u mdosthi_user -p mDosthi < /tmp/mDosthi_clean.sql
rm -f /tmp/mDosthi_clean.sql ~/mDosthi_export.sql
```

#### Option 2: Build `mDosthi` Directly on the Server from Existing `eDosthi` DB + M-Dosthi Migrations
Run on **the server** (reads existing `eDosthi` schema without modifying `eDosthi`, then applies every M-Dosthi migration):
```bash
MDOSTHI_DIR="$HOME/M-Dosthi-Codebase"

# 1. Clone base schema/data from existing eDosthi DB (normalize DEFINER if needed)
sudo mysqldump --routines --triggers eDosthi \
  | LC_ALL=C sed 's/DEFINER=`root`@`%`/DEFINER=`root`@`localhost`/g' \
  > /tmp/edosthi_base.sql
mysql --host=127.0.0.1 -u mdosthi_user -p mDosthi < /tmp/edosthi_base.sql
rm -f /tmp/edosthi_base.sql

# 2. Apply M-Dosthi legacy screening & monitoring migrations
for f in "$MDOSTHI_DIR"/database/migrations/*.sql; do
  echo "Applying $f ..."
  mysql --host=127.0.0.1 -u mdosthi_user -p mDosthi < "$f"
done

# 3. Apply M-Dosthi API & longitudinal schema migrations
mysql --host=127.0.0.1 -u mdosthi_user -p mDosthi \
  < "$MDOSTHI_DIR/services/api/src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql"
mysql --host=127.0.0.1 -u mdosthi_user -p mDosthi \
  < "$MDOSTHI_DIR/services/api/src/main/resources/db/manual/V20261113_01__complete_api_schema.sql"
```

---

## 5. Guide A — Shared Tomcat Setup (`:8080`, Alongside Existing `/eDosthi/`)

Use **Guide A** when you want `/mDosthi/` served on the **same `:8080` Tomcat** (and same reverse proxy / domain) that already serves `/eDosthi/`.

### Exact Files Created / Updated in Shared Mode
1. `$SHARED_TOMCAT_HOME/conf/Catalina/localhost/mDosthi.xml` → `<Context docBase="$MDOSTHI_DIR/apps/web" reloadable="false" />`
2. `$MDOSTHI_DIR/apps/web/config.info` → `blport = 1100`, `gblhome = http://YOUR_SERVER_IP:8080/mDosthi`, `gbltelemedix = /mDosthi`
3. `$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf` → `blport = 1100`, `gbldburl = jdbc:mysql://127.0.0.1:3306/mDosthi?...`
4. `$MDOSTHI_DIR/apps/web/WEB-INF/lib/*.jar` & `$MDOSTHI_DIR/services/legacy/runtime/iMediXBusinessLogic.jar`

### All-in-One Shared Tomcat Commands (Run on Server)
```bash
SHARED_TOMCAT_HOME="/home/YOUR_SERVER_USER/eDosthi/Tomcat9"
MDOSTHI_DIR="/home/YOUR_SERVER_USER/M-Dosthi-Codebase"
ACCESS_URL="http://YOUR_SERVER_IP:8080/mDosthi"
DB_USER="mdosthi_user"
DB_PASS="YOUR_STRONG_DB_PASSWORD"

export SHARED_TOMCAT_HOME
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which javac))))"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$MDOSTHI_DIR"
./scripts/setup.sh --shared="$SHARED_TOMCAT_HOME"
./scripts/legacy.sh build --shared

sed -i "s|^gbldbusername = .*|gbldbusername = $DB_USER|" "$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf"
sed -i "s|^gbldbpasswd = .*|gbldbpasswd = $DB_PASS|" "$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf"
sed -i "s|^03) blport = .*|03) blport = 1100|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^04) gblroot = .*|04) gblroot = $SHARED_TOMCAT_HOME|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^05) gblhome = .*|05) gblhome = $ACCESS_URL|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^08) gbltemp = .*|08) gbltemp = $MDOSTHI_DIR/apps/web/temp|" "$MDOSTHI_DIR/apps/web/config.info"

./scripts/legacy.sh stop --shared || true
./scripts/legacy.sh start --shared

rm -rf "$SHARED_TOMCAT_HOME/work/Catalina/localhost/mDosthi"
"$SHARED_TOMCAT_HOME/bin/shutdown.sh" || true
sleep 4
(cd "$SHARED_TOMCAT_HOME/webapps/eDosthi" && "$SHARED_TOMCAT_HOME/bin/startup.sh")

sleep 5
"$MDOSTHI_DIR/scripts/legacy.sh" status --shared
curl -s -o /dev/null -w "eDosthi (:8080) -> HTTP %{http_code}\n" http://127.0.0.1:8080/eDosthi/
curl -s -o /dev/null -w "M-Dosthi (:8080) -> HTTP %{http_code}\n" http://127.0.0.1:8080/mDosthi/
```
> [!NOTE]
> Always start Shared Tomcat from `$SHARED_TOMCAT_HOME/webapps/eDosthi` (as shown above) so existing `/eDosthi/` continues finding `$SHARED_TOMCAT_HOME/webapps/eDosthi/config.info`.
> If `$SHARED_TOMCAT_HOME/bin/setenv.sh` does not yet export `--add-opens` on Java 25, copy the `JDK_JAVA_OPTIONS` line from `$MDOSTHI_DIR/tools/tomcat9/bin/setenv.sh`.

### Optional `systemd` Service for Shared Mode (Auto-Starts M-Dosthi RMI `:1100` on Boot)
Create `/etc/systemd/system/mdosthi-rmi.service`:
```ini
[Unit]
Description=mDosthi RMI Server (Port 1100, Shared Tomcat Mode)
After=network.target mysql.service

[Service]
Type=forking
User=YOUR_SERVER_USER
WorkingDirectory=/home/YOUR_SERVER_USER/M-Dosthi-Codebase
Environment="SHARED_TOMCAT_HOME=/home/YOUR_SERVER_USER/eDosthi/Tomcat9"
ExecStart=/home/YOUR_SERVER_USER/M-Dosthi-Codebase/scripts/legacy.sh start --shared
ExecStop=/home/YOUR_SERVER_USER/M-Dosthi-Codebase/scripts/legacy.sh stop --shared
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Enable:
```bash
sudo systemctl daemon-reload && sudo systemctl enable --now mdosthi-rmi
```

---

## 6. Guide B — Individual Tomcat Setup (`:8081`, Dedicated Bundled Tomcat Alongside eDosthi)

Use **Guide B** when you want **100% process isolation from `eDosthi`** — `eDosthi` keeps running on `:8080` completely untouched (not even a `mDosthi.xml` descriptor or restart!), while M-Dosthi runs on its own bundled Tomcat (`$MDOSTHI_DIR/Tomcat9` -> `$MDOSTHI_DIR/tools/tomcat9`) on **HTTP `:8081`** (shutdown `:8006`) + M-Dosthi RMI on **`:1100`**.

### Exact Files Created / Updated in Individual Mode
1. `$MDOSTHI_DIR/Tomcat9` → symlink to `$MDOSTHI_DIR/tools/tomcat9`
2. `$MDOSTHI_DIR/tools/tomcat9/conf/server.xml` → HTTP Connector `8081`, Shutdown `8006`
3. `$MDOSTHI_DIR/tools/tomcat9/conf/Catalina/localhost/mDosthi.xml` → `<Context docBase="$MDOSTHI_DIR/apps/web" reloadable="false" />`
4. `$MDOSTHI_DIR/apps/web/config.info` → `blport = 1100`, `gblroot = $MDOSTHI_DIR/tools/tomcat9`, `gblhome = http://YOUR_SERVER_IP:8081/mDosthi`, `gbltelemedix = /mDosthi`
5. `$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf` → `blport = 1100`, `gbldburl = jdbc:mysql://127.0.0.1:3306/mDosthi?...`
6. `$MDOSTHI_DIR/tools/tomcat9/logs/tomcat.pid` & `$MDOSTHI_DIR/services/legacy/runtime/iMediXBusinessLogic.pid`

### All-in-One Individual Tomcat Commands (Run on Server)
```bash
MDOSTHI_DIR="/home/YOUR_SERVER_USER/M-Dosthi-Codebase"
SERVER_IP="YOUR_SERVER_IP"
ACCESS_URL="http://$SERVER_IP:8081/mDosthi"
DB_USER="mdosthi_user"
DB_PASS="YOUR_STRONG_DB_PASSWORD"

unset SHARED_TOMCAT_HOME
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which javac))))"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$MDOSTHI_DIR"
chmod +x scripts/*.sh tools/tomcat9/bin/*.sh services/legacy/runtime/*.sh
./scripts/setup.sh --individual
./scripts/legacy.sh build --individual

sed -i "s|^gbldbusername = .*|gbldbusername = $DB_USER|" "$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf"
sed -i "s|^gbldbpasswd = .*|gbldbpasswd = $DB_PASS|" "$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf"
sed -i "s|^03) blport = .*|03) blport = 1100|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^04) gblroot = .*|04) gblroot = $MDOSTHI_DIR/tools/tomcat9|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^05) gblhome = .*|05) gblhome = $ACCESS_URL|" "$MDOSTHI_DIR/apps/web/config.info"
sed -i "s|^08) gbltemp = .*|08) gbltemp = $MDOSTHI_DIR/apps/web/temp|" "$MDOSTHI_DIR/apps/web/config.info"

rm -rf "$MDOSTHI_DIR/tools/tomcat9/work/Catalina/localhost/mDosthi"
./scripts/legacy.sh stop --individual || true
./scripts/legacy.sh start --individual

sleep 5
./scripts/legacy.sh status --individual
curl -s -o /dev/null -w "M-Dosthi Individual (:8081) -> HTTP %{http_code}\n" http://127.0.0.1:8081/mDosthi/
```

### Open Port `8081` in the Server Firewall (Individual Mode Only)
*(Keep `8080` open for existing eDosthi, add `8081` for M-Dosthi, and keep `3306`, `1099`, `1100` closed to outside traffic.)*
- **Ubuntu / Debian (`ufw`):**
  ```bash
  sudo ufw allow 22/tcp
  sudo ufw allow 8080/tcp
  sudo ufw allow 8081/tcp
  sudo ufw deny 3306/tcp
  sudo ufw deny 1099/tcp
  sudo ufw deny 1100/tcp
  ```
- **RHEL / Rocky / CentOS / Fedora (`firewalld`):**
  ```bash
  sudo firewall-cmd --permanent --add-port=8081/tcp
  sudo firewall-cmd --reload
  ```
*(Custom port option if `8081` is already taken on the server: `TOMCAT_HTTP_PORT=8082 TOMCAT_SHUTDOWN_PORT=8007 ./scripts/legacy.sh start --individual`.)*

### Optional `systemd` Service for Individual Mode (Auto-Starts Tomcat `:8081` + RMI `:1100` on Boot)
Create `/etc/systemd/system/mdosthi-individual.service`:
```ini
[Unit]
Description=mDosthi Individual Tomcat 9 (:8081) + RMI (:1100)
After=network.target mysql.service

[Service]
Type=forking
User=YOUR_SERVER_USER
WorkingDirectory=/home/YOUR_SERVER_USER/M-Dosthi-Codebase
ExecStart=/home/YOUR_SERVER_USER/M-Dosthi-Codebase/scripts/legacy.sh start --individual
ExecStop=/home/YOUR_SERVER_USER/M-Dosthi-Codebase/scripts/legacy.sh stop --individual
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Enable:
```bash
sudo systemctl daemon-reload && sudo systemctl enable --now mdosthi-individual
```

---

## 7. Public Access URLs (With or Without Domain)

| Deployment Mode | Direct URL (No Domain, No Third Party) | Reverse-Proxied URL (If Server Uses Nginx/Apache) |
| :--- | :--- | :--- |
| **Existing eDosthi** | `http://YOUR_SERVER_IP:8080/eDosthi/` | `https://edosthi.in/eDosthi/` *(unchanged)* |
| **Guide A — M-Dosthi Shared Tomcat** | `http://YOUR_SERVER_IP:8080/mDosthi/` | `https://YOUR_DOMAIN/mDosthi/` *(proxy `127.0.0.1:8080/mDosthi/`)* |
| **Guide B — M-Dosthi Individual Tomcat** | `http://YOUR_SERVER_IP:8081/mDosthi/` | `https://YOUR_DOMAIN/mDosthi/` *(proxy `127.0.0.1:8081/mDosthi/`)* |

### Optional Nginx Location Block (Add Inside Existing Server Block if Nginx Is Used)
```nginx
# Route /mDosthi/ to 8080 (Guide A: Shared) or 8081 (Guide B: Individual)
location /mDosthi/ {
    proxy_pass http://127.0.0.1:8081/mDosthi/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cookie_path /mDosthi /mDosthi;
}
```

---

## 8. Optional: Deploy M-Dosthi Spring Boot API (`:9090`) & Flutter Web

Only needed if you also serve the **M-Dosthi Flutter Web / Mobile App** from this server.

### 8.1 Start Spring Boot API (`:9090`)
Create `$MDOSTHI_DIR/.env`:
```ini
SPRING_DATASOURCE_URL=jdbc:mysql://127.0.0.1:3306/mDosthi?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC
SPRING_DATASOURCE_USERNAME=mdosthi_user
SPRING_DATASOURCE_PASSWORD=YOUR_STRONG_DB_PASSWORD
SECRETKEY=YOUR_GENERATED_BASE64_JWT_SECRET
```
Start API (requires JDK 25):
```bash
cd "$MDOSTHI_DIR"
nohup ./scripts/api.sh > "$MDOSTHI_DIR/api.log" 2>&1 & echo $! > "$MDOSTHI_DIR/api.pid"
```

### 8.2 Build Flutter Web Release Bundle
```bash
cd "$MDOSTHI_DIR/apps/mobile"
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:9090 \
  --dart-define=API_HOST=YOUR_SERVER_IP:9090
```
*(Output is in `$MDOSTHI_DIR/apps/mobile/build/web/`. If proxied behind HTTPS Nginx `/api/`, use `https://YOUR_DOMAIN` and `YOUR_DOMAIN`.)*

---

## 9. Day-2 Operations: Updates, Logs, Verification & Stop Commands (Both Modes)

### 9.1 Fast UI-Only Update (JSP / CSS / Images — Zero Restart Needed!)
1. **Sync files** (either `git -C "$MDOSTHI_DIR" pull origin main` on server, **or** `rsync` from local machine):
   ```bash
   rsync -avz --exclude='config.info' --exclude='temp/' --exclude='.DS_Store' \
     "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/apps/web/" \
     "YOUR_SERVER_USER@YOUR_SERVER_IP:/home/YOUR_SERVER_USER/M-Dosthi-Codebase/apps/web/"
   ```
2. **Clear Tomcat's compiled JSP cache** (Tomcat recompiles updated JSPs automatically on next browser load):
   - **Shared Mode (`:8080`):**
     ```bash
     rm -rf "/home/YOUR_SERVER_USER/eDosthi/Tomcat9/work/Catalina/localhost/mDosthi"
     ```
   - **Individual Mode (`:8081`):**
     ```bash
     rm -rf "/home/YOUR_SERVER_USER/M-Dosthi-Codebase/tools/tomcat9/work/Catalina/localhost/mDosthi"
     ```

### 9.2 Rebuild When Java / Servlet / RMI Code Changes (`services/legacy/`)
- **Shared Mode (`:8080`):**
  ```bash
  MDOSTHI_DIR="/home/YOUR_SERVER_USER/M-Dosthi-Codebase"
  SHARED_TOMCAT_HOME="/home/YOUR_SERVER_USER/eDosthi/Tomcat9"
  cd "$MDOSTHI_DIR"
  SHARED_TOMCAT_HOME="$SHARED_TOMCAT_HOME" ./scripts/legacy.sh build --shared
  ./scripts/legacy.sh stop --shared && ./scripts/legacy.sh start --shared
  rm -rf "$SHARED_TOMCAT_HOME/work/Catalina/localhost/mDosthi"
  "$SHARED_TOMCAT_HOME/bin/shutdown.sh" && sleep 4 && (cd "$SHARED_TOMCAT_HOME/webapps/eDosthi" && "$SHARED_TOMCAT_HOME/bin/startup.sh")
  ```
- **Individual Mode (`:8081`):**
  ```bash
  MDOSTHI_DIR="/home/YOUR_SERVER_USER/M-Dosthi-Codebase"
  cd "$MDOSTHI_DIR"
  ./scripts/legacy.sh build --individual
  rm -rf "$MDOSTHI_DIR/tools/tomcat9/work/Catalina/localhost/mDosthi"
  ./scripts/legacy.sh stop --individual && ./scripts/legacy.sh start --individual
  ```

### 9.3 Exact Log File Locations on Server
| Log | Exact Server Path |
| :--- | :--- |
| **M-Dosthi RMI Output** | `$MDOSTHI_DIR/services/legacy/runtime/SystemLog/bl.out` |
| **M-Dosthi Access XML Logs** | `$MDOSTHI_DIR/services/legacy/runtime/SystemLog/*AccessLog.xml` |
| **Individual Tomcat Logs (`:8081`)** | `$MDOSTHI_DIR/tools/tomcat9/logs/catalina.out` & `localhost.YYYY-MM-DD.log` |
| **Shared Tomcat Logs (`:8080`)** | `$SHARED_TOMCAT_HOME/logs/catalina.out` & `localhost.YYYY-MM-DD.log` |
| **eDosthi RMI Logs (`:1099`)** | `$EDOSTHI_DIR/eDosthi-BL/SystemLog/` |
| **M-Dosthi Spring Boot API Log** | `$MDOSTHI_DIR/api.log` |

### 9.4 Verify & Stop Commands
```bash
MDOSTHI_DIR="/home/YOUR_SERVER_USER/M-Dosthi-Codebase"
SHARED_TOMCAT_HOME="/home/YOUR_SERVER_USER/eDosthi/Tomcat9"

# Check listening ports (3306=MySQL, 1099=eDosthi RMI, 1100=M-Dosthi RMI, 8080=Shared Tomcat, 8081=Individual Tomcat, 9090=API)
ss -tulpn | grep -E "3306|1099|1100|8080|8081|9090"

# Status check (Shared or Individual)
SHARED_TOMCAT_HOME="$SHARED_TOMCAT_HOME" "$MDOSTHI_DIR/scripts/legacy.sh" status --shared
"$MDOSTHI_DIR/scripts/legacy.sh" status --individual

# Stop Shared Mode (stops ONLY M-Dosthi RMI :1100; keeps /eDosthi/ on :8080 running!)
SHARED_TOMCAT_HOME="$SHARED_TOMCAT_HOME" "$MDOSTHI_DIR/scripts/legacy.sh" stop --shared

# Stop Individual Mode (stops M-Dosthi Tomcat :8081 + M-Dosthi RMI :1100; keeps /eDosthi/ on :8080 running!)
"$MDOSTHI_DIR/scripts/legacy.sh" stop --individual
```

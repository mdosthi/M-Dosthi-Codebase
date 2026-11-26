# All-in-One Server Setup & Deployment Guide (mDosthi Alongside Existing eDosthi)

Complete, copy-paste reference for uploading and running **`M-Dosthi-Codebase`** on a Linux server **where `eDosthi` is already installed and running** — supporting **both**:
- **Guide A — Shared Tomcat Mode (`:8080`)**: Mounts `/mDosthi/` onto eDosthi's existing Tomcat 9 (`:8080`) alongside `/eDosthi/`, with M-Dosthi RMI on `:1100`.
- **Guide B — Individual Tomcat Mode (`:8081`)**: Runs M-Dosthi on its own bundled Tomcat 9 (`M-Dosthi-Codebase/Tomcat9 -> tools/tomcat9` on `:8081`, shutdown `:8006`) + M-Dosthi RMI (`:1100`), **zero touch and zero restart to eDosthi's Tomcat (`:8080`)**.

Works **with or without GitHub**, **with or without a domain / third-party tools**, and from **Linux or macOS** workstations.

> [!IMPORTANT]
> - **`eDosthi` is already on the server — do NOT upload `eDosthi codebases/` and do NOT modify eDosthi source files.** You only upload `M-Dosthi-Codebase`.
> - **Never commit secrets to Git.** Keep `.env`, credential files, `*.pid`, `*.log`, `apps/web/config.info`, and `services/legacy/runtime/gblinfo.inf` out of version control.
> - **Never expose internal ports publicly.** Keep MySQL (`3306`) and Java RMI (`1099`, `1100`) restricted to `127.0.0.1`.
> - Configured for server **`sadmin@172.16.98.116`** — replace any remaining placeholders (`YOUR_DB_PASSWORD`, `YOUR_DOMAIN`) with real values, and never wrap values in `<` or `>` in shell commands.

---

## 1. Exact File & Directory Locations (Server vs. Local)

### 1.1 Exact Server Layout (`edosthisrv` — `sadmin@172.16.98.116`, Ubuntu 24.04)
> Verified disk space: `/home` = **4.3 TB free** (`4.7 TB` total), `/` = **110 GB free** (`183 GB` total). System Java: **OpenJDK 11.0.33.1** (`/usr/bin/java`, `/usr/bin/javac`), MySQL: `/usr/bin/mysql` (admin access via `sudo mysql --defaults-file=/etc/mysql/debian.cnf`; existing database: **`edosthidb`**; auth plugin: `mysql_native_password`; `validate_password` policy enforced).

```text
/home/sadmin/                                            # Server home directory ($HOME — 4.3 TB free)
│
├── edosthi/                                             # [ALREADY ON SERVER — RUNNING LIVE AS root — DO NOT TOUCH]
│   └── web/
│       ├── jdk11/bin/java                               # Existing eDosthi JDK 11 (PIDs running live as root)
│       ├── eDosthi-BL/                                  # Existing eDosthi RMI (:1099)
│       │   └── gblinfo.inf                              # gblcentercode=EXTR, ps_home=http://127.0.0.1:8080, DB=edosthidb
│       └── Tomcat9/                                     # [SHARED_TOMCAT_HOME] HTTP :8080, shutdown :8005 (runs as root)
│           ├── bin/startup.sh, shutdown.sh, setenv.sh
│           ├── lib/servlet-api.jar
│           ├── webapps/eDosthi/                         # Existing /eDosthi/ web app (gblhome=http://edosthi.in/eDosthi)
│           ├── conf/Catalina/localhost/
│           │   └── mDosthi.xml                          # [Created ONLY in Guide A: Shared Mode] -> /home/sadmin/M-Dosthi-Codebase/apps/web
│           ├── work/Catalina/localhost/mDosthi/         # [Shared Mode] Compiled JSP cache
│           └── logs/catalina.out, tomcat.pid
│
└── M-Dosthi-Codebase/                                   # [UPLOADED TO SERVER — /home/sadmin/M-Dosthi-Codebase]
    ├── .env                                             # [Server-only] Spring Boot API DB & JWT secret (if running API)
    ├── Tomcat9 -> tools/tomcat9                         # [Individual Mode] Root symlink to tools/tomcat9
    ├── tools/tomcat9/                                   # [Individual Mode] HTTP :8081, shutdown :8006
    │   ├── bin/startup.sh, shutdown.sh, setenv.sh
    │   ├── conf/server.xml                              # Port 8081 (HTTP), Port 8006 (Shutdown)
    │   ├── conf/Catalina/localhost/mDosthi.xml         # [Individual Mode] -> docBase="/home/sadmin/M-Dosthi-Codebase/apps/web"
    │   ├── work/Catalina/localhost/mDosthi/            # [Individual Mode] Compiled JSP cache
    │   └── logs/catalina.out, tomcat.pid                # [Individual Mode] Logs & Tomcat PID
    ├── apps/web/
    │   ├── config.info                                  # [Server-only] 03) blport=1100, 05) gblhome=..., 06) gbltelemedix=/mDosthi
    │   ├── temp/                                        # [Server-only] Runtime upload/session temp dir
    │   ├── WEB-INF/classes/UserAccessControl.json       # Role-to-JSP ACL (adm, doc, psy, usr, pat)
    │   └── WEB-INF/lib/*.jar                            # Built by ./scripts/legacy.sh build
    └── services/legacy/runtime/
        ├── gblinfo.inf                                  # [Server-only] blport=1100, DB=mDosthi, credentials & log paths
        ├── iMediXBusinessLogic.jar                      # Built by ./scripts/legacy.sh build
        ├── iMediXBusinessLogic.pid                      # [Server-only] M-Dosthi RMI PID (isolated from eDosthi RMI)
        ├── SystemLog/bl.out                             # [Server-only] M-Dosthi RMI stdout/access logs
        ├── GenSqlLog/                                   # [Server-only] M-Dosthi SQL logs
        └── temp/                                        # [Server-only] M-Dosthi RMI temp dir
```

### 1.2 Exact Local Workstation Layout (`macOS`)
```text
/Users/dipayanrana/Desktop/CodeBase/
├── eDosthi codebases/                                   # DO NOT UPLOAD (already running live on server)
└── M-Dosthi-Codebase/                                   # <-- UPLOAD / PUSH ONLY THIS FOLDER TO SERVER
    ├── Tomcat9 -> tools/tomcat9                         # Symlink to bundled Individual Tomcat 9
    ├── tools/tomcat9/                                   # Bundled Individual Tomcat (:8081, shutdown :8006)
    │   ├── bin/setenv.sh, startup.sh, shutdown.sh
    │   ├── conf/server.xml                              # <Server port="8006">, <Connector port="8081">
    │   └── lib/servlet-api.jar, mysql-connector-j-8.4.0.jar
    ├── apps/
    │   ├── web/                                         # Legacy Web JSP + CSS + WEB-INF (used by BOTH modes)
    │   │   ├── index.jsp                                # Staff login page (<title>mDosthi</title>)
    │   │   ├── config.info.template                     # Template -> generates server apps/web/config.info
    │   │   ├── style/mdosthi-brand-tokens.css           # 5-color brand logo design tokens & fonts
    │   │   ├── style/mdosthi-login.css                  # Responsive login styles
    │   │   ├── bootstrap/css/index.css                  # Responsive post-login dashboard styles
    │   │   ├── jspfiles/index1.jsp, patindex.jsp, ...   # Post-login portals & clinical pages
    │   │   ├── WEB-INF/classes/UserAccessControl.json   # Role access matrix (includes psy on editprofile/saveeditusr)
    │   │   └── WEB-INF/lib/*.jar                        # Compiled servlet & RMI stub JARs
    │   └── mobile/                                      # Flutter Web / Mobile app (mdosthi_app)
    │       ├── lib/theme/brand_theme.dart               # 5-color brand logo Flutter theme
    │       └── lib/login_page.dart                      # Bilingual login page
    ├── services/
    │   ├── legacy/
    │   │   ├── server-src/                              # M-Dosthi RMI Java sources + makeJar.sh
    │   │   ├── servlet-src/WEB-INF/classes/src/         # Servlet Java sources (projinfo.java, cook.java, UserAccessCheck.java)
    │   │   └── runtime/
    │   │       ├── gblinfo.inf.template                 # Template -> generates server gblinfo.inf
    │   │       └── RunServer.sh                         # Starts iMediXBusinessLogic.jar
    │   └── api/                                         # Spring Boot REST API (:9090, requires JDK 25)
    │       └── src/main/resources/db/manual/
    │           ├── V20261029_01__pipeline_job_queue.sql
    │           └── V20261113_01__complete_api_schema.sql
    ├── database/migrations/*.sql                        # M-Dosthi screening & monitoring SQL migrations
    └── scripts/
        ├── setup.sh                                     # --shared=/home/sadmin/edosthi/web/Tomcat9  OR  --individual
        ├── legacy.sh                                    # build | start | stop | status  (--shared | --individual)
        └── api.sh                                       # Starts Spring Boot API (:9090)
```

### 1.3 Port & Coexistence Map on `172.16.98.116` (`edosthi.in`)

| Service | Port | Exact Server Config / Binary Path | Shared Mode (`--shared`) | Individual Mode (`--individual`) |
| :--- | :--- | :--- | :--- | :--- |
| **Apache2 HTTPS Reverse Proxy** | `80`, `443` | `/etc/apache2/sites-available/edosthi.in.conf` | Routes `/` → `:8080`, `/api/` → `:9090`, `/mdosthi-api/` → `:9091` | Routes `/mDosthi/` if custom proxy added |
| **MySQL Server** | `3306` | `/usr/bin/mysql` (`127.0.0.1` only) | Already running (`edosthidb` + `mDosthi` DBs) | Already running (`edosthidb` + `mDosthi` DBs) |
| **Ollama LLM Server** | `11434` | `127.0.0.1:11434` (`llama3.2:3b`, Bengali models) | Shared locally by Spring Boot APIs | Shared locally by Spring Boot APIs |
| **eDosthi RMI** | `1099` | Live `root` process (`/home/sadmin/edosthi/web/eDosthi-BL/`) | Already running (**untouched**) | Already running (**untouched**) |
| **eDosthi Tomcat 9** | `8080` (shutdown `8005`) | `/home/sadmin/edosthi/web/Tomcat9/conf/server.xml` | Serves `/eDosthi/`, `/mDosthi/`, & `/mDosthi-app/` | Serves `/eDosthi/` only (**zero touch / zero restart**) |
| **eDosthi Spring Boot API** | `9090` | `/home/sadmin/edosthi/run_api.sh` (`/api/`) | Already running (**untouched**) | Already running (**untouched**) |
| **M-Dosthi RMI** | `1100` | `/home/sadmin/M-Dosthi-Codebase/services/legacy/runtime/gblinfo.inf` | `./scripts/legacy.sh start --shared=/home/sadmin/edosthi/web/Tomcat9` | `./scripts/legacy.sh start --individual` |
| **M-Dosthi Individual Tomcat 9** | `8081` (shutdown `8006`) | `/home/sadmin/M-Dosthi-Codebase/tools/tomcat9/conf/server.xml` | Stopped / unused | Serves `/mDosthi/` on `:8081` |
| **M-Dosthi Spring Boot API** | `9091` | `/home/sadmin/M-Dosthi-Codebase/.env` & `/opt/jdk-25` (`/mdosthi-api/`) | Runs on `:9091` alongside eDosthi API `:9090` | Runs on `:9091` alongside eDosthi API `:9090` |

---

## 2. Connect to the Server & Locate Existing `eDosthi` Paths

### 2.0 Connect to the Institute OpenVPN (Required Before SSH)
`172.16.98.116` is on a private institutional network — you must connect to the **Sophos SSL VPN** (`.ovpn` client profile) before `ssh`, `rsync`, or `scp` will work.

> [!CAUTION]
> **Never commit `.ovpn` files or VPN credentials to Git** (they contain embedded client private keys).

#### macOS (Recommended — Tunnelblick)
1. Install Tunnelblick if not already installed:
   ```bash
   brew install --cask tunnelblick
   ```
2. Double-click your `.ovpn` client config file → choose **Only Me** → enter your Mac login password.
3. Click the **Tunnelblick** menu bar icon → **VPN Details...** → select your profile → **Settings** tab → set **OpenVPN version** to **`2.5.x` (`OpenSSL 1.1.1w`)**.
   *(Older Sophos SSL VPN appliances using `AES-128-CBC` can fail or time out on OpenVPN `2.7.x` / OpenSSL `3.5+`.)*
4. Click **Connect** and enter your VPN **Username** and **Password** (leave Security Code blank if 2FA/OTP is not enabled on the account).
5. Wait until Tunnelblick shows **Connected** (green), then verify port `22` is reachable:
   ```bash
   nc -zv -w 4 172.16.98.116 22
   # Expected: Connection to 172.16.98.116 port 22 [tcp/ssh] succeeded!
   ```

#### macOS (OpenVPN CLI — Terminal)
```bash
# Install OpenVPN via Homebrew (once)
brew install openvpn

# Connect (prompts for Mac sudo password, then VPN username & password)
sudo /opt/homebrew/sbin/openvpn --config /path/to/client-config.ovpn \
  --data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-128-CBC \
  --data-ciphers-fallback AES-128-CBC
```
*(If Homebrew's OpenVPN `2.7.x` hits a legacy OpenSSL/TLS mismatch and Tunnelblick is installed, you can invoke Tunnelblick's bundled OpenVPN `2.5` + `OpenSSL 1.1.1w` directly from Terminal:)*
```bash
sudo /Applications/Tunnelblick.app/Contents/Resources/openvpn/openvpn-2.5_git_37160ee-openssl-1.1.1w/openvpn \
  --config /path/to/client-config.ovpn
```
Wait for **`Initialization Sequence Completed`**, leave that tab open, and use a second terminal tab for SSH (`Ctrl + C` in the first tab to disconnect).

#### Linux (OpenVPN CLI)
```bash
sudo apt update && sudo apt install -y openvpn
sudo openvpn --config /path/to/client-config.ovpn \
  --data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-128-CBC \
  --data-ciphers-fallback AES-128-CBC
```
Wait for **`Initialization Sequence Completed`**, then open a second terminal tab for SSH.

> [!TIP]
> **Troubleshooting `read TCP_CLIENT: Operation timed out`**: If OpenVPN connects TCP to the VPN gateway and then repeatedly resets with `Operation timed out` on home Wi-Fi, your ISP or router is likely dropping OpenVPN traffic. Switch to a **mobile hotspot** and reconnect.

### 2.1 SSH into the Server (from Linux or macOS)
```bash
ssh sadmin@172.16.98.116
```
Enter the **server SSH password** when prompted (used for `ssh`, `rsync`, `scp`, and `sudo`).
*(Optional one-time passwordless SSH setup from your local machine: `ssh-copy-id sadmin@172.16.98.116`.)*

Quick storage & resource check before uploading:
```bash
ssh sadmin@172.16.98.116 "df -h && echo '---' && free -h && echo '---' && ls -la ~"
```

### 2.2 Discover Exact Existing `eDosthi` & Java Paths on the Server
Run this right after logging into the server:
```bash
ps aux | grep -E "catalina|iMediXBusinessLogic" | grep -v grep
which java javac mysql
java -version
```
Verified values on `edosthisrv` (`172.16.98.116`):
1. **`SHARED_TOMCAT_HOME`**: `/home/sadmin/edosthi/web/Tomcat9` (running live as `root` with `/home/sadmin/edosthi/web/jdk11/bin/java`).
2. **Server upload target**: `/home/sadmin/M-Dosthi-Codebase` (on `/home`, **4.3 TB free**).
3. **JDK**: System **OpenJDK 11.0.33.1** (`/usr/bin/java`, `/usr/bin/javac`) works out of the box for M-Dosthi Legacy Web + RMI; `services/api` (Spring Boot 3.5) requires **JDK 25** (`sudo apt update && sudo apt install -y openjdk-25-jdk`).

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

### Option B: Without GitHub (Direct `rsync` over SSH — VPN-Resilient)
Run on **your local Linux or macOS machine** (uses `--partial --timeout=30` + SSH keepalives so slow VPN links never hang indefinitely, and excludes `.venv/` and large `database/snapshots/`):

#### B1. Lean Upload for Guide A — Shared Tomcat Mode (`:8080`, Fastest)
```bash
rsync -avz --partial --progress --timeout=30 \
  -e "ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=3" \
  --exclude='.git/' --exclude='.DS_Store' --exclude='.env' \
  --exclude='.venv/' --exclude='database/snapshots/' --exclude='docs/' \
  --exclude='tools/' --exclude='apps/mobile/' --exclude='services/api/' \
  --exclude='*.pid' --exclude='*.log' \
  --exclude='apps/web/config.info' --exclude='apps/web/temp/*' \
  --exclude='services/legacy/runtime/gblinfo.inf' \
  --exclude='services/legacy/runtime/SystemLog/*' \
  --exclude='services/legacy/runtime/GenSqlLog/*' \
  --exclude='services/legacy/runtime/temp/*' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/"
```

#### B2. Full Upload for Guide B — Individual Tomcat Mode (`:8081`, Includes `tools/tomcat9`)
```bash
LOCAL_MDOSTHI_DIR="/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase"
SERVER_USER="sadmin"
SERVER_IP="172.16.98.116"
REMOTE_MDOSTHI_DIR="/home/$SERVER_USER/M-Dosthi-Codebase"

ssh "$SERVER_USER@$SERVER_IP" "mkdir -p '$REMOTE_MDOSTHI_DIR'"

rsync -avz --partial --progress --timeout=30 \
  -e "ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=3" \
  --exclude='.git/' \
  --exclude='.DS_Store' \
  --exclude='.env' \
  --exclude='.venv/' \
  --exclude='database/snapshots/' \
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
  --exclude='services/api/target/' \
  "$LOCAL_MDOSTHI_DIR/" \
  "$SERVER_USER@$SERVER_IP:$REMOTE_MDOSTHI_DIR/"
```
*(Notice B2 includes `tools/tomcat9/`—only its local `logs/`, `work/`, `temp/`, and local `mDosthi.xml` are excluded—so both `--shared` and `--individual` work out of the box on the server even without internet access!)*

### Option C: Step-by-Step Folder Upload (One by One via `rsync` from Mac)
If you prefer uploading and verifying one folder at a time from `/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase`:
```bash
# 0. Create remote directory skeleton
ssh sadmin@172.16.98.116 "mkdir -p /home/sadmin/M-Dosthi-Codebase/{scripts,apps,services,tools,database}"

# 1. scripts/ (60 KB)
rsync -avz --progress \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/scripts/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/scripts/"

# 2. services/legacy/ (18 MB — RMI & servlet sources/runtime, excludes local gblinfo.inf & logs)
rsync -avz --progress \
  --exclude='runtime/gblinfo.inf' --exclude='runtime/*.pid' \
  --exclude='runtime/SystemLog/*' --exclude='runtime/GenSqlLog/*' --exclude='runtime/temp/*' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/services/legacy/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/services/legacy/"

# 3. apps/web/ (40 MB — Legacy Web JSP/CSS/WEB-INF, excludes local config.info & temp)
rsync -avz --progress \
  --exclude='config.info' --exclude='temp/*' --exclude='.DS_Store' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/apps/web/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/apps/web/"

# 4. tools/tomcat9/ (80 MB — Bundled Individual Tomcat :8081, excludes local logs/work/mDosthi.xml)
rsync -avz --progress \
  --exclude='conf/Catalina/localhost/*.xml' --exclude='logs/*' --exclude='work/*' --exclude='temp/*' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/tools/tomcat9/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/tools/tomcat9/"

# 5. database/ (165 MB — SQL migrations & dumps)
rsync -avz --progress \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/database/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/database/"

# 6. [Optional] services/api/ (Spring Boot REST API :9090, excludes target/)
rsync -avz --progress --exclude='target/' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/services/api/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/services/api/"

# 7. [Optional] apps/mobile/ (Flutter Web/Mobile source, excludes build/ & .dart_tool/)
rsync -avz --progress --exclude='build/' --exclude='.dart_tool/' \
  "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/apps/mobile/" \
  "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/apps/mobile/"
```

---

## 4. Create & Populate the `mDosthi` Database on the Server (Leaves `edosthidb` Untouched)

MySQL is already running on the server (`127.0.0.1:3306`) with existing database **`edosthidb`** for `eDosthi`. On this Ubuntu server, `root@localhost` requires a MySQL password, while Ubuntu's built-in admin config (`sudo mysql --defaults-file=/etc/mysql/debian.cnf`) works directly.

> [!NOTE]
> MySQL's `validate_password` policy is enabled on this server: `DB_PASS` must be **8+ characters** with **uppercase, lowercase, a number, and a symbol**. Always wrap `DB_PASS` in **single quotes** (`'...'`) and avoid `!` to prevent shell history expansion.

### 4.1 Create `mDosthi` Schema & User (Run on Server)
```bash
DB_USER='mDosthi'
DB_PASS='YOUR_STRONG_DB_PASSWORD'

sudo mysql --defaults-file=/etc/mysql/debian.cnf <<SQL
CREATE DATABASE IF NOT EXISTS mDosthi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_PASS';
GRANT ALL PRIVILEGES ON mDosthi.* TO '$DB_USER'@'127.0.0.1';
GRANT ALL PRIVILEGES ON mDosthi.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
SQL
```

### 4.2 Populate `mDosthi` (Choose Option 1 or Option 2 — First Time Only)

#### Option 1: Build `mDosthi` Directly on the Server from Existing `edosthidb` + M-Dosthi Migrations (Verified — 331 Tables)
Run on **the server** (reads `edosthidb` with `--single-transaction` without locking or modifying live `eDosthi`, normalizes all `DEFINER` clauses, imports into `mDosthi`, and applies all 11 M-Dosthi SQL migrations):
```bash
MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"

# 1. Clone base schema/data from existing edosthidb (non-locking read, normalize DEFINER)
sudo mysqldump --defaults-file=/etc/mysql/debian.cnf \
  --single-transaction --routines --triggers --set-gtid-purged=OFF edosthidb \
  | sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' \
  > /tmp/edosthi_base.sql && \
sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi < /tmp/edosthi_base.sql && \
rm -f /tmp/edosthi_base.sql

# 2. Apply all 11 M-Dosthi legacy screening & monitoring migrations (runs via debian.cnf for trigger privileges)
for f in "$MDOSTHI_DIR"/database/migrations/V*.sql; do
  echo "Applying $(basename "$f")..."
  sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi < "$f" || break
done

# 3. Verify table count (expected: 331 tables)
sudo mysql --defaults-file=/etc/mysql/debian.cnf \
  -e "SELECT COUNT(*) AS mDosthi_tables FROM information_schema.tables WHERE table_schema='mDosthi';"

# 4. [Optional — only if deploying Spring Boot API :9090] Apply API schema migrations
# sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi \
#   < "$MDOSTHI_DIR/services/api/src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql"
# sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi \
#   < "$MDOSTHI_DIR/services/api/src/main/resources/db/manual/V20261113_01__complete_api_schema.sql"
```

#### Option 2: Upload Your Ready Local `mDosthi` Database Dump (Alternative)
On **your local Linux or macOS machine**:
```bash
mysqldump --host=127.0.0.1 -u root -p mDosthi > /tmp/mDosthi_export.sql
scp /tmp/mDosthi_export.sql sadmin@172.16.98.116:~/mDosthi_export.sql
rm -f /tmp/mDosthi_export.sql
```
On **the server**:
```bash
sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' ~/mDosthi_export.sql > /tmp/mDosthi_clean.sql
sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi < /tmp/mDosthi_clean.sql
rm -f /tmp/mDosthi_clean.sql ~/mDosthi_export.sql
```

---

## 5. Guide A — Shared Tomcat Setup (`:8080`, Alongside Existing `/eDosthi/`)

Use **Guide A** when you want `/mDosthi/` served on the **same `:8080` Tomcat** (and same reverse proxy / domain) that already serves `/eDosthi/`.

### Exact Files Created / Updated in Shared Mode
1. `$SHARED_TOMCAT_HOME/conf/Catalina/localhost/mDosthi.xml` → `<Context docBase="$MDOSTHI_DIR/apps/web" reloadable="false" />`
2. `$MDOSTHI_DIR/apps/web/config.info` → `blport = 1100`, `gblhome = http://172.16.98.116:8080/mDosthi`, `gbltelemedix = /mDosthi`
3. `$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf` → `blport = 1100`, `gbldburl = jdbc:mysql://127.0.0.1:3306/mDosthi?...`
4. `$MDOSTHI_DIR/apps/web/WEB-INF/lib/*.jar` & `$MDOSTHI_DIR/services/legacy/runtime/iMediXBusinessLogic.jar`

### All-in-One Shared Tomcat Commands (Run on Server)
*(Works even with the lean B1 upload where `tools/tomcat9/` is not uploaded, and uses `sudo` where Shared Tomcat is owned/run by `root`.)*

```bash
SHARED_TOMCAT_HOME="/home/sadmin/edosthi/web/Tomcat9"
MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"
ACCESS_URL="http://172.16.98.116:8080/mDosthi"   # Or http://edosthi.in/mDosthi if reverse-proxied
DB_USER='mDosthi'
DB_PASS='YOUR_STRONG_DB_PASSWORD'

# 1. Create runtime directories (world-writable web temp so root Tomcat & sadmin share cleanly)
mkdir -p "$MDOSTHI_DIR/services/legacy/runtime/"{temp,SystemLog,GenSqlLog} "$MDOSTHI_DIR/apps/web/temp"
chmod 777 "$MDOSTHI_DIR/apps/web/temp"

# 2. Write M-Dosthi RMI config (gblinfo.inf)
cat > "$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf" <<EOF
gblcentercode = EXTR
gbldbjdbccriver = com.mysql.cj.jdbc.Driver
gbldburl = jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8
gbldbusername = $DB_USER
gbldbpasswd = $DB_PASS
blport = 1100
tempdatadir = $MDOSTHI_DIR/services/legacy/runtime/temp
ftphost = 127.0.0.1
ftpuser = imedixftp
ftppasswd =change-me
ftpdocsendpath = doc/Send
ps_home = http://127.0.0.1:8080
CenterTypeMSPS = PS
SystemLogger = yes
SystemLoggerPath = $MDOSTHI_DIR/services/legacy/runtime/SystemLog
GeneralSqlLog = yes
GeneralSqlLogPath = $MDOSTHI_DIR/services/legacy/runtime/GenSqlLog
EOF

# 3. Write M-Dosthi Web config (apps/web/config.info)
cat > "$MDOSTHI_DIR/apps/web/config.info" <<EOF
01) gblcentercode = XXXX
02) blip = 127.0.0.1
03) blport = 1100
04) gblroot = $SHARED_TOMCAT_HOME
05) gblhome = $ACCESS_URL
06) gbltelemedix = /mDosthi
07) gblsip = 127.0.0.1
08) gbltemp = $MDOSTHI_DIR/apps/web/temp
09) gblPageRow = 25
10) gbldata = /data/
11) LargeFileSaveLayer(PL->Presentation Layer / DL->Data Layer(FTP)) = PL
12) PACSServiceURL = https://technocratzindia.co.in:216/ServiceTWP.svc/
13) PACSuid = report
14) PACSpass =change-me
15) PACSurl = https://technocratzindia.co.in:215/
16) EmailURL = 
17) SMSURL = 
18) maxFileUploadLimit = 10
19) vidServerUrl = meet.jit.si
EOF

# 4. Register /mDosthi context descriptor in Shared Tomcat (runs as root)
sudo mkdir -p "$SHARED_TOMCAT_HOME/conf/Catalina/localhost"
echo "<Context docBase=\"$MDOSTHI_DIR/apps/web\" reloadable=\"false\" />" \
  | sudo tee "$SHARED_TOMCAT_HOME/conf/Catalina/localhost/mDosthi.xml"

# 5. Build M-Dosthi JARs (JDK 11) and start M-Dosthi RMI on :1100
cd "$MDOSTHI_DIR"
export SHARED_TOMCAT_HOME
export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which javac)")")")"
export PATH="$JAVA_HOME/bin:$PATH"
chmod +x scripts/*.sh services/legacy/server-src/makeJar.sh services/legacy/servlet-src/WEB-INF/classes/src/makeJar.sh

./scripts/legacy.sh build --shared="$SHARED_TOMCAT_HOME"
./scripts/legacy.sh stop --shared="$SHARED_TOMCAT_HOME" || true
./scripts/legacy.sh start --shared="$SHARED_TOMCAT_HOME"

# 6. Clear /mDosthi JSP cache and reload/restart Shared Tomcat as root using eDosthi's JDK 11
sudo rm -rf "$SHARED_TOMCAT_HOME/work/Catalina/localhost/mDosthi"
sudo JAVA_HOME="/home/sadmin/edosthi/web/jdk11" "$SHARED_TOMCAT_HOME/bin/shutdown.sh" || true
sleep 4
sudo bash -c 'export JAVA_HOME="/home/sadmin/edosthi/web/jdk11" && cd /home/sadmin/edosthi/web/Tomcat9/webapps/eDosthi && /home/sadmin/edosthi/web/Tomcat9/bin/startup.sh'

# 7. Verify RMI (:1099 & :1100) and HTTP 200 on BOTH /eDosthi/ and /mDosthi/
sleep 5
"$MDOSTHI_DIR/scripts/legacy.sh" status --shared="$SHARED_TOMCAT_HOME"
ss -tulpn | grep -E ':3306|:1099|:1100|:8080'
curl -s -o /dev/null -w "eDosthi (:8080) -> HTTP %{http_code}\n" http://127.0.0.1:8080/eDosthi/
curl -s -o /dev/null -w "M-Dosthi (:8080) -> HTTP %{http_code}\n" http://127.0.0.1:8080/mDosthi/
```
> [!NOTE]
> Always start Shared Tomcat as `root` with `JAVA_HOME="/home/sadmin/edosthi/web/jdk11"` from `/home/sadmin/edosthi/web/Tomcat9/webapps/eDosthi` (matching the live `eDosthi` process) so existing `/eDosthi/` continues finding `$SHARED_TOMCAT_HOME/webapps/eDosthi/config.info` without permission issues.

### Optional `systemd` Service for Shared Mode (Auto-Starts M-Dosthi RMI `:1100` on Boot)
Create `/etc/systemd/system/mdosthi-rmi.service`:
```ini
[Unit]
Description=mDosthi RMI Server (Port 1100, Shared Tomcat Mode)
After=network.target mysql.service

[Service]
Type=forking
User=sadmin
WorkingDirectory=/home/sadmin/M-Dosthi-Codebase
Environment="SHARED_TOMCAT_HOME=/home/sadmin/edosthi/web/Tomcat9"
ExecStart=/home/sadmin/M-Dosthi-Codebase/scripts/legacy.sh start --shared
ExecStop=/home/sadmin/M-Dosthi-Codebase/scripts/legacy.sh stop --shared
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
4. `$MDOSTHI_DIR/apps/web/config.info` → `blport = 1100`, `gblroot = $MDOSTHI_DIR/tools/tomcat9`, `gblhome = http://172.16.98.116:8081/mDosthi`, `gbltelemedix = /mDosthi`
5. `$MDOSTHI_DIR/services/legacy/runtime/gblinfo.inf` → `blport = 1100`, `gbldburl = jdbc:mysql://127.0.0.1:3306/mDosthi?...`
6. `$MDOSTHI_DIR/tools/tomcat9/logs/tomcat.pid` & `$MDOSTHI_DIR/services/legacy/runtime/iMediXBusinessLogic.pid`

### All-in-One Individual Tomcat Commands (Run on Server)
```bash
MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"
SERVER_IP="172.16.98.116"
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
User=sadmin
WorkingDirectory=/home/sadmin/M-Dosthi-Codebase
ExecStart=/home/sadmin/M-Dosthi-Codebase/scripts/legacy.sh start --individual
ExecStop=/home/sadmin/M-Dosthi-Codebase/scripts/legacy.sh stop --individual
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Enable:
```bash
sudo systemctl daemon-reload && sudo systemctl enable --now mdosthi-individual
```

---

## 7. Public Access Architecture & URLs (Verified Live via Apache2 HTTPS)

Apache2 on `172.16.98.116` (`:80` → redirect to `:443`, Let's Encrypt SSL for `edosthi.in`) reverse-proxies all web and API paths so external devices can reach both **eDosthi** and **mDosthi** over HTTPS without VPN or custom ports:

```text
External Browser / Phone (Internet, no VPN)
  │  HTTPS (port 443, Let's Encrypt SSL)
  ▼
Apache2 Reverse Proxy (/etc/apache2/sites-available/edosthi.in.conf)
  ├── /eDosthi/*     ──► 127.0.0.1:8080/eDosthi/     (Shared Tomcat 9) ──► RMI :1099 ──► MySQL: edosthidb
  ├── /api/*         ──► 127.0.0.1:9090/api/         (eDosthi API)     ────────────────► MySQL: edosthidb
  │
  ├── /mDosthi/*     ──► 127.0.0.1:8080/mDosthi/     (Shared Tomcat 9) ──► RMI :1100 ──► MySQL: mDosthi
  ├── /mdosthi-api/* ──► 127.0.0.1:9091/             (mDosthi API, JDK 25) ────────────► MySQL: mDosthi + Ollama :11434
  └── /mDosthi-app/* ──► 127.0.0.1:8080/mDosthi-app/ (Flutter Web)     ── calls ──────► /mdosthi-api/
```

| Service | Direct Internal URL (VPN / LAN Only) | Public HTTPS URL (Any Device, No VPN) |
| :--- | :--- | :--- |
| **Existing eDosthi Web** | `http://172.16.98.116:8080/eDosthi/` | `https://edosthi.in/eDosthi/` *(unchanged, HTTP 200)* |
| **Existing eDosthi API** | `http://172.16.98.116:9090/api/` | `https://edosthi.in/api/` *(unchanged)* |
| **mDosthi Legacy Web (Shared Tomcat)** | `http://172.16.98.116:8080/mDosthi/` | `https://edosthi.in/mDosthi/` *(verified HTTP 200)* |
| **mDosthi Spring Boot API (`:9091`)** | `http://172.16.98.116:9091/` | `https://edosthi.in/mdosthi-api/` *(verified HTTP 403 on protected root)* |
| **mDosthi Flutter Web** | `http://172.16.98.116:8080/mDosthi-app/` | `https://edosthi.in/mDosthi-app/` *(mounted via `mDosthi-app.xml`)* |
| **mDosthi Individual Tomcat (Guide B)** | `http://172.16.98.116:8081/mDosthi/` | Requires proxy rule to `127.0.0.1:8081/mDosthi/` |

> [!NOTE]
> `172.16.98.116` is a private institutional IP — always share **`https://edosthi.in/mDosthi/`** and **`https://edosthi.in/mDosthi-app/`** for phones or external laptops outside the VPN, and set `05) gblhome = https://edosthi.in/mDosthi` in `apps/web/config.info`.

### Exact Apache2 Rule Added to `/etc/apache2/sites-available/edosthi.in.conf`
*(Placed directly **before** `ProxyPass / http://127.0.0.1:8080/`, leaving `/api/` → `127.0.0.1:9090/api/` untouched):*
```apache
    # PROXY /mdosthi-api/ -> mDosthi Spring Boot API (9091)
    ProxyPass        /mdosthi-api/  http://127.0.0.1:9091/
    ProxyPassReverse /mdosthi-api/  http://127.0.0.1:9091/
```

---

## 8. Deploy M-Dosthi Spring Boot API (`:9091`) & Flutter Web (`/mDosthi-app/`)

Because `eDosthi/API` already uses port **`9090`** (`/api/`), M-Dosthi's Spring Boot API runs on port **`9091`** (`/mdosthi-api/`) using a side-by-side **Temurin JDK 25** installation in `/opt/jdk-25` (without changing system Java 11 or eDosthi's JDK 11).

### 8.1 Install Side-by-Side Temurin JDK 25 on the Server
```bash
sudo mkdir -p /opt/jdk-25 && \
curl -fSL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse" -o /tmp/jdk25.tar.gz && \
sudo tar -xzf /tmp/jdk25.tar.gz -C /opt/jdk-25 --strip-components=1 && \
rm -f /tmp/jdk25.tar.gz && \
/opt/jdk-25/bin/java -version
```

### 8.2 Apply API SQL Migrations, Build Fat JAR & Start API on `:9091`
```bash
MDOSTHI="/home/sadmin/M-Dosthi-Codebase"

# 1. Apply both API SQL migrations to mDosthi DB
cd "$MDOSTHI/services/api"
sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi < src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql
sudo mysql --defaults-file=/etc/mysql/debian.cnf mDosthi < src/main/resources/db/manual/V20261113_01__complete_api_schema.sql

# 2. Build 30 MB Spring Boot fat JAR on the server using JDK 25
export JAVA_HOME=/opt/jdk-25
export PATH="$JAVA_HOME/bin:$PATH"
chmod +x mvnw
./mvnw -q package -DskipTests

# 3. Create server-only .env (quote JDBC URL so '&' is safe when sourced)
cat > "$MDOSTHI/.env" <<EOF
SPRING_DATASOURCE_URL='jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8'
SPRING_DATASOURCE_USERNAME='mDosthi'
SPRING_DATASOURCE_PASSWORD='YOUR_STRONG_DB_PASSWORD'
SECRETKEY='$(openssl rand -base64 48 | tr -d '\n')'
OLLAMA_BASE_URL='http://127.0.0.1:11434'
OLLAMA_MODEL_EN='llama3.2:3b'
OLLAMA_MODEL_BN='Gemma_3_4B_Bengali_Edosthi_v2-q4_k_m:latest'
EOF
chmod 600 "$MDOSTHI/.env"

# 4. Launch Spring Boot API on port 9091
set -a; source "$MDOSTHI/.env"; set +a
nohup /opt/jdk-25/bin/java -jar -Dserver.port=9091 \
  "$MDOSTHI/services/api/target/saMiX-0.0.1-SNAPSHOT.jar" \
  > "$MDOSTHI/api.log" 2>&1 &
echo $! > "$MDOSTHI/api.pid"
```

### 8.3 Build Flutter Web Release Bundle (On Mac) & Mount at `https://edosthi.in/mDosthi-app/`
On **your local Mac**:
```bash
cd /Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/apps/mobile
flutter build web --release \
  --base-href=/mDosthi-app/ \
  --dart-define=API_HOST=edosthi.in/mdosthi-api

tar -czf /tmp/mdosthi_flutter_web.tar.gz -C build/web .
rsync -av --partial --progress --timeout=30 \
  -e "ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=3" \
  /tmp/mdosthi_flutter_web.tar.gz \
  sadmin@172.16.98.116:/tmp/mdosthi_flutter_web.tar.gz
```
On **the server (`sadmin@edosthisrv`)**:
```bash
mkdir -p /home/sadmin/M-Dosthi-Codebase/apps/mobile/build/web && \
tar -xzf /tmp/mdosthi_flutter_web.tar.gz -C /home/sadmin/M-Dosthi-Codebase/apps/mobile/build/web && \
rm -f /tmp/mdosthi_flutter_web.tar.gz && \
echo '<Context docBase="/home/sadmin/M-Dosthi-Codebase/apps/mobile/build/web" reloadable="false" />' \
  | sudo tee /home/sadmin/edosthi/web/Tomcat9/conf/Catalina/localhost/mDosthi-app.xml && \
sleep 4 && \
curl -sk -o /dev/null -w "mDosthi Flutter Web HTTPS -> HTTP %{http_code}\n" -H "Host: edosthi.in" https://127.0.0.1/mDosthi-app/
```

---

## 9. Day-2 Operations: Updates, Logs, Verification & Stop Commands (Both Modes)

### 9.1 Fast UI-Only Update (JSP / CSS / Images — Zero Restart Needed!)
1. **Sync files** (either `git -C "$MDOSTHI_DIR" pull origin main` on server, **or** `rsync` from local machine):
   ```bash
   rsync -avz --exclude='config.info' --exclude='temp/' --exclude='.DS_Store' \
     "/Users/dipayanrana/Desktop/CodeBase/M-Dosthi-Codebase/apps/web/" \
     "sadmin@172.16.98.116:/home/sadmin/M-Dosthi-Codebase/apps/web/"
   ```
2. **Clear Tomcat's compiled JSP cache** (Tomcat recompiles updated JSPs automatically on next browser load):
   - **Shared Mode (`:8080`):**
     ```bash
     sudo rm -rf "/home/sadmin/edosthi/web/Tomcat9/work/Catalina/localhost/mDosthi"
     ```
   - **Individual Mode (`:8081`):**
     ```bash
     rm -rf "/home/sadmin/M-Dosthi-Codebase/tools/tomcat9/work/Catalina/localhost/mDosthi"
     ```

### 9.2 Rebuild When Java / Servlet / RMI Code Changes (`services/legacy/`)
- **Shared Mode (`:8080`):**
  ```bash
  MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"
  SHARED_TOMCAT_HOME="/home/sadmin/edosthi/web/Tomcat9"
  cd "$MDOSTHI_DIR"
  export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which javac)")")")"
  ./scripts/legacy.sh build --shared="$SHARED_TOMCAT_HOME"
  ./scripts/legacy.sh stop --shared="$SHARED_TOMCAT_HOME" && ./scripts/legacy.sh start --shared="$SHARED_TOMCAT_HOME"
  sudo rm -rf "$SHARED_TOMCAT_HOME/work/Catalina/localhost/mDosthi"
  sudo JAVA_HOME="/home/sadmin/edosthi/web/jdk11" "$SHARED_TOMCAT_HOME/bin/shutdown.sh" || true
  sleep 4
  sudo bash -c 'export JAVA_HOME="/home/sadmin/edosthi/web/jdk11" && cd /home/sadmin/edosthi/web/Tomcat9/webapps/eDosthi && /home/sadmin/edosthi/web/Tomcat9/bin/startup.sh'
  ```
- **Individual Mode (`:8081`):**
  ```bash
  MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"
  cd "$MDOSTHI_DIR"
  ./scripts/legacy.sh build --individual
  rm -rf "$MDOSTHI_DIR/tools/tomcat9/work/Catalina/localhost/mDosthi"
  ./scripts/legacy.sh stop --individual && ./scripts/legacy.sh start --individual
  ```

### 9.3 Exact Log File Locations on `172.16.98.116`
| Log | Exact Server Path |
| :--- | :--- |
| **M-Dosthi RMI Output** | `/home/sadmin/M-Dosthi-Codebase/services/legacy/runtime/SystemLog/bl.out` |
| **M-Dosthi Access XML Logs** | `/home/sadmin/M-Dosthi-Codebase/services/legacy/runtime/SystemLog/*AccessLog.xml` |
| **Individual Tomcat Logs (`:8081`)** | `/home/sadmin/M-Dosthi-Codebase/tools/tomcat9/logs/catalina.out` & `localhost.YYYY-MM-DD.log` |
| **Shared Tomcat Logs (`:8080`)** | `/home/sadmin/edosthi/web/Tomcat9/logs/catalina.out` & `localhost.YYYY-MM-DD.log` |
| **M-Dosthi Spring Boot API Log** | `/home/sadmin/M-Dosthi-Codebase/api.log` |

### 9.4 Verify & Stop Commands
```bash
MDOSTHI_DIR="/home/sadmin/M-Dosthi-Codebase"
SHARED_TOMCAT_HOME="/home/sadmin/edosthi/web/Tomcat9"

# Check listening ports (80/443=Apache2, 3306=MySQL, 1099=eDosthi RMI, 1100=M-Dosthi RMI, 8080=Shared Tomcat, 8081=Individual Tomcat, 9090=eDosthi API, 9091=M-Dosthi API, 11434=Ollama)
sudo ss -tulpn | grep -E ':80 |:443 |:3306|:1099|:1100|:8080|:8081|:9090|:9091|:11434'

# Status check (Shared or Individual)
SHARED_TOMCAT_HOME="$SHARED_TOMCAT_HOME" "$MDOSTHI_DIR/scripts/legacy.sh" status --shared
"$MDOSTHI_DIR/scripts/legacy.sh" status --individual

# Stop Shared Mode (stops ONLY M-Dosthi RMI :1100; keeps /eDosthi/ on :8080 running!)
SHARED_TOMCAT_HOME="$SHARED_TOMCAT_HOME" "$MDOSTHI_DIR/scripts/legacy.sh" stop --shared

# Stop Individual Mode (stops M-Dosthi Tomcat :8081 + M-Dosthi RMI :1100; keeps /eDosthi/ on :8080 running!)
"$MDOSTHI_DIR/scripts/legacy.sh" stop --individual
```

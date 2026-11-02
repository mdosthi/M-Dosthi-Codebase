# Setup Guide

This guide covers the independently runnable parts of the M-Dosthi repository. The normal Flutter workflow is `apps/mobile` plus `services/api`; the older JSP/Tomcat workflow is `apps/web` plus the RMI process in `services/legacy`. They have separate DB configuration and can target different schemas.

## Choose A Workflow

| You want to run | Required parts | Entry point |
|---|---|---|
| Flutter client in a browser/device | MySQL with the expected schema, Spring Boot API, Flutter SDK | `services/api` and `apps/mobile` |
| Legacy JSP website | MySQL with the legacy schema, Tomcat 9, legacy RMI process | `apps/web` and `services/legacy` |
| Python annotation tools | Python environment and, for model calls, Ollama | `services/annotate` |

You do not need to start both Java servers for the Flutter workflow. The JSP application is not the Flutter app's API server.

## Choose A Platform And Run Mode

The Flutter client and Spring API can run on macOS, Linux, and Windows. Use Docker Compose for a consistent multi-service stack, or run the Flutter/API components directly with the platform's native tools.

| Run mode | macOS | Linux | Windows |
|---|---|---|---|
| Docker | Install Docker Desktop or Docker Engine with Compose. Run `docker compose` from Terminal. | Install Docker Engine and the Compose plugin. Run `docker compose` from a shell. | Install Docker Desktop. Run `docker compose` from PowerShell. |
| Without Docker | Use `scripts/setup.sh` and `scripts/api.sh` from Terminal; Flutter runs natively. | Use `scripts/setup.sh` and `scripts/api.sh` from a shell; Flutter runs natively. | Use `scripts/setup.ps1` and `scripts/api.ps1` from PowerShell; Flutter runs natively. |

The no-Docker path requires you to install and configure JDK 25, Flutter, and MySQL 8 yourself (MySQL may be local or remote). For Windows, the legacy JSP/RMI scripts are Bash scripts and require Git Bash or WSL; alternatively, use Docker Compose for those services. The Compose stack uses Linux containers and is supported through Docker Desktop on macOS/Windows and Docker Engine on Linux.

To start the Docker stack, first prepare `.env` as described below, then follow [Run The Apps With Docker Compose](#run-the-apps-with-docker-compose). To start Flutter and the API without Docker, follow [Run Flutter And The API](#4-run-flutter-and-the-api). Compose initializes an empty database only; neither setup mode supplies clinical schemas or patient data.

## Prerequisites

Install the tools needed for your chosen workflow. The repository setup scripts do not install Java, Flutter, Python, MySQL, or Ollama.

| Tool | Used by | Notes |
|---|---|---|
| Git | All workflows | Clone this repository. |
| JDK 25 | `services/api` | Required by `services/api/pom.xml`; set `JAVA_HOME` and `PATH` before starting Maven. |
| JDK 11 or later | Legacy build and runtime | Must include `javac`. The legacy RMI service uses dynamic stubs and does not require the removed `rmic` tool; builds target Java 11 bytecode. A local `tools/jdk11` may still be used; `tools/` is not part of Git. |
| MySQL 8 | API and legacy workflows | Use a local server, a remote server, or the optional Compose service. You need a compatible database dump/schema; Compose alone creates an empty database. |
| Flutter SDK | `apps/mobile` | Chrome is needed for the Chrome target; `web-server` can be used with another browser. |
| Python 3.10+ | `services/annotate` | Create an isolated environment and install the package's declared dependencies. |
| Ollama | Annotation and configured API features | Install separately, start the service, and download/configure the model names required by your workflow. |
| Docker Compose | Unified web/API/database stack and Android APK build | `docker compose` is included with current Docker Desktop and many Docker Engine installations. |

On Windows, run setup and the API in PowerShell. The legacy scripts are Bash scripts; use Git Bash or WSL. Flutter can use native Windows tooling for targets supported by the installed Flutter SDK.

## 1. Clone And Prepare Local Files

From a terminal:

```bash
git clone <repository-url> M-Dosthi
cd M-Dosthi
scripts/setup.sh
```

PowerShell:

```powershell
git clone <repository-url> M-Dosthi
Set-Location M-Dosthi
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

The setup script prepares local configuration and Tomcat, then reports which prerequisite commands are on `PATH`. It does not install those prerequisites or initialize application tables. If `.env` is missing, it copies `.env.example` to `.env`; the tracked `.env.example` template is not modified. Edit only `.env` with local values. It also creates `services/legacy/runtime/gblinfo.inf` and `apps/web/config.info` from templates, replacing `@PROJECT_ROOT@` with this checkout's absolute path. Generated files are not overwritten on later setup runs, so preserve your local edits.

`tools/` is Git-ignored. Setup downloads Tomcat 9 there if it is missing, but a Java distribution is not automatically downloaded. Install the needed JDKs yourself and keep their paths outside version control.

## 2. Configure Java And Secrets

Copy `.env.example` to `.env` in the repository root, then edit `.env`. It is ignored by Git; keep one value per line as `NAME=value`. Never put passwords, API tokens, or other credentials in `.env.example`; it is a tracked template shared with the repository.

For the API, select JDK 25 before launching. Bash example:

```bash
brew install openjdk@25
export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

On macOS, `scripts/api.sh` can also find a JDK 25 installed by Homebrew or registered with the system when `JAVA_HOME` is unset. If the JDK is installed elsewhere, set `JAVA_HOME` to its installation directory. The API script checks that `JAVA_HOME` contains JDK 25 before starting Maven.

PowerShell example:

```powershell
$env:JAVA_HOME = 'C:\path\to\jdk-25'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

For legacy build commands, select JDK 11 or later:

```bash
export JAVA_HOME=/path/to/jdk-11
export PATH="$JAVA_HOME/bin:$PATH"
"$JAVA_HOME/bin/javac" -version
```

The most important API values in `.env` are `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, and `SECRETKEY`. Use a dedicated, non-root MySQL account for `SPRING_DATASOURCE_USERNAME`; `MYSQL_ROOT_PASSWORD` is only for database administration and must not be used as the API password. For the local Compose database, Compose creates the API account using the Spring datasource username and password. Replace the example database password with a strong, unique value. Generate a unique key, for example with `openssl rand -base64 32`; do not reuse any credentials from historical files. Ollama model settings and `IMEDIX_WHATSAPP_*` values are only needed for those integrations. Set `OLLAMA_LOG_PAYLOAD_ENABLED=false` where prompt payloads may contain patient data.

The legacy RMI server does not automatically load `.env`. Edit the generated `services/legacy/runtime/gblinfo.inf` for its JDBC URL, username, password, FTP credentials, and local paths. The legacy website has its own generated `apps/web/config.info`; provide any required external integration credentials there too. Both files are ignored by Git.

## Optional English speech playback

The Flutter chatbot keeps Ollama as its response-generating LLM. When a patient explicitly chooses **Listen**, the Spring API sends only that persisted assistant response to the same configured Ollama instance's separate `/v1/audio/speech` endpoint and returns WAV audio. The default instance is local (`localhost:11434`); if you configure a remote Ollama host, the response text is sent there, so use only a deployment approved for counselling data. No conversation history, session ID, patient ID, or audio file is sent to the TTS model or stored by the API.

Use Ollama 0.40.9 or later and pull its Phonon model on the same Ollama instance configured by `OLLAMA_BASE_URL`:

```bash
ollama --version
ollama pull phonon
ollama show phonon
```

`ollama show phonon` lists the available English voices. Configure these optional values in the root `.env`:

| Variable | Default | Purpose |
|---|---:|---|
| `OLLAMA_TTS_ENABLED` | `true` | Enable or disable speech synthesis |
| `OLLAMA_TTS_MODEL` | `phonon` | Ollama speech model |
| `OLLAMA_TTS_VOICE` | `default` | Voice name supported by the installed model |
| `OLLAMA_TTS_LANGUAGE` | `en` | Supported language; the selected model currently accepts English only |
| `OLLAMA_TTS_TIMEOUT` | `30000` | Per-segment request timeout in milliseconds |
| `OLLAMA_TTS_MAX_TEXT_LENGTH` | `12000` | Maximum prepared response length |
| `OLLAMA_TTS_MAX_CONCURRENT` | `2` | Maximum concurrent synthesis requests (1–16) |

Speech is generated on demand; autoplay is off. English sessions show Listen, pause/resume, replay, and volume controls. Bengali sessions and responses containing non-Latin letters remain text-only; the application does not translate them. The current model configuration validates `OLLAMA_TTS_LANGUAGE=en` at startup. Speech errors leave the written answer available. Audio is buffered until synthesis completes; audio is not streamed incrementally. The API does not cache or persist generated audio; the client retains only the currently selected audio in memory for replay and releases it on message change or screen disposal. Text is cleaned for speech (including Markdown and fenced code blocks) and long responses are split at sentence boundaries, with oversized sentences split at word boundaries.

The model is [Phonon 31m English](https://huggingface.co/gradium/phonon-31m-en) (24 kHz mono); its model card lists Apache-2.0. The [official Phonon runtime](https://github.com/gradium-ai/xn-ptts) source is MIT OR Apache-2.0, but the model license is separate. Review the license and voice terms for the exact model/version deployed. The API uses [Ollama's documented speech API](https://docs.ollama.com/capabilities/speech) and does not download weights into this repository.

## Chat voice input

The microphone button beside the chat composer uses the platform's speech-recognition service to transcribe a short dictation into the message draft. It is separate from Ollama and the M-Dosthi API; the recording is not uploaded to this application's API. Depending on the browser, operating system, and configured recognition provider, audio may be processed by that provider or sent to its online service. The recognized text remains an unsent draft until the patient chooses **Send**.

The feature requires microphone permission and a browser/device with speech-recognition support. For Flutter web, use a supported browser and a secure context (HTTPS, or localhost for local development), then allow microphone access when prompted. The session language selects English or Bengali recognition where supported by the browser or device. iOS and macOS microphone and speech-recognition permission descriptions are configured in their respective `Info.plist` files. Recognition availability and language support vary by platform; speech input is not provided by the Ollama TTS configuration.

To verify a deployment, start the API and Flutter app, open an English patient chat, wait for an assistant response, then use **Listen** and test pause/resume, replay, and volume. A standalone non-clinical model check is:

```bash
curl http://localhost:11434/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -d '{"model":"phonon","voice":"default","input":"This is a local speech test."}' \
  --output /tmp/phonon-test.wav
```

If synthesis fails, confirm that `ollama show phonon` lists the configured voice, `OLLAMA_BASE_URL` points to the same Ollama instance, and that instance is reachable from the API host. The API returns a user-friendly error and preserves the written response if the model is missing, times out, or is overloaded.

## 3. Start MySQL And Prepare Schemas

### Optional local MySQL with Docker

Set `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD` in `.env`, then run:

```bash
docker compose up -d mysql
docker compose ps
```

On the first initialization of the Docker volume, Compose creates the schema named by `MYSQL_DATABASE` and a non-root application account whose credentials match `SPRING_DATASOURCE_USERNAME` and `SPRING_DATASOURCE_PASSWORD`. Set `SPRING_DATASOURCE_URL` to that MySQL server and schema. Docker does not copy data from an existing local MySQL server; import an approved dump into the container before using the app.

For local legacy testing without a backup, the repository README documents a guarded [minimal local development bootstrap](../README.md#fresh-local-database-local-legacy-testing). It supports local accounts, basic patient registration, screening checkpoints, and chat persistence tables, but is not a full database initialization and does not enable the other clinical workflows. Chat remains restricted to patients explicitly enrolled in the RCT.

Existing MySQL Docker volumes are not reinitialized when these values change. If the volume already exists, changing `.env` alone does not create or update the application account. Provision or update it safely using the configured MySQL administrator credentials:

```bash
bash scripts/provision-api-db-user.sh
```

The script uses `MYSQL_ROOT_PASSWORD` only to administer the database; it creates or updates the dedicated API user and grants it access only to `MYSQL_DATABASE`. For a database server not on `127.0.0.1:3306`, set `MYSQL_ADMIN_HOST` and `MYSQL_ADMIN_PORT` in `.env` to the server's administration endpoint. The failure `Access denied for user ...` means MySQL rejected the configured credentials or the account lacks access from the API host; restarting the API alone will not repair credentials.

Without Docker, start your MySQL 8 server using your operating system's service manager, then create the required schema(s) and a least-privilege application user. The JDBC URL host/port/database must match that server.

### Import an approved database

Database snapshots/backups are intentionally not distributed in Git. Obtain the correct approved dump through your organization's secure channel, verify the target environment and backup status, then import it into the matching schema. Never use real patient data in an unapproved development environment.

Example import commands (the password is prompted, not placed in shell history):

```bash
mysql --host=127.0.0.1 --user=YOUR_USER --password mDosthi < /secure/path/to/approved-api-dump.sql
mysql --host=127.0.0.1 --user=YOUR_USER --password mDosthi < /secure/path/to/approved-legacy-dump.sql
```

Only import schemas you actually have and intend to use. Do not assume the API and legacy application can share a database simply because both use MySQL; confirm the schema and tables in the supplied dump first.

The PO Bado migrations in `database/migrations` are for the `mDosthi` legacy schema. They are not general database initialization scripts and are not applied automatically. Back up first and follow [the migration runner guide](../database/migration-runner/README.md); its database guard rejects other schema names.

## Run The Apps With Docker Compose

The root `docker-compose.yml` is the single Docker entry point. From the repository root, copy `.env.example` to `.env`, set unique local values for `MYSQL_ROOT_PASSWORD`, `SPRING_DATASOURCE_PASSWORD`, `LEGACY_DB_PASSWORD`, and `SECRETKEY`, then start the services:

```bash
docker compose up --build -d
```

Compose starts MySQL, the Spring API, the legacy RMI service and JSP site, and the Flutter web app. Open:

| App | URL |
|---|---|
| Legacy JSP site | `http://localhost:8080/M-Dosthi/` |
| Flutter web app | `http://localhost:8081/` |
| Spring API | `http://localhost:9090/` |

Compose creates an empty database and does not import schemas or patient data. Import the approved API and/or legacy schema into the configured database before using database-backed features. By default, the legacy service uses the same database name as `MYSQL_DATABASE`; set `LEGACY_DB_DATABASE` if it needs a separate schema and provision its account as needed. The default legacy DB username/password are separate `.env` values and must match a provisioned MySQL account. MySQL initialization settings only apply when its named volume is first created.

Build an Android APK separately:

```bash
docker compose run --build --rm android-apk
```

The output is `dist/android/app-release.apk`. This checkout has no `apps/mobile/android/` project, so the build container creates the Android platform runner before building. The APK allows cleartext HTTP to match the app's current API protocol; use this local-development build only, not for production. The default application ID is `com.example.mdosthi_app`; set `ANDROID_ORG` to your organization's reverse-DNS prefix before distributing the APK. `ANDROID_API_HOST` defaults to `10.0.2.2:9090` for the standard Android emulator. Set it to a reachable LAN hostname/IP for a physical device. Flutter web calls the API through the same-origin Nginx `/api/` proxy; `FLUTTER_API_HOST` defaults to `localhost:8081` and should match the browser-visible host/port when changed.

Use the unified stack for local development only. It does not initialize clinical schemas, configure production secrets, or expose the RMI port on the host. A clean-checkout legacy image build may also require separately approved prebuilt artifacts documented in [the legacy build limitation](#legacy-clean-checkout-limitation).

## Share the Flutter web app from your computer

A Cloudflare Tunnel can expose the local Flutter web container at a domain you already own (for example `mdosthi.app`, registered at Name.com or any registrar). The registrar provides the domain; it does not host the app. The host computer (macOS, Linux, or Windows), Docker, internet connection, and tunnel process must stay running, so this is not an always-on production host. Domain registration may have a renewal fee. Replace `mdosthi.app` with your own domain throughout.

Commands are shown for Bash (macOS/Linux, or Git Bash/WSL on Windows) with PowerShell equivalents where they differ. Run them from the repository root.

```text
Browser --HTTPS--> Cloudflare (DNS + certificate) --tunnel--> cloudflared on your computer
  --> http://localhost:8081 (Nginx + Flutter web) --/api/--> Spring API --> MySQL
```

### Concepts

- **DNS** maps `mdosthi.app` to Cloudflare. Changing the domain's *nameservers* at Name.com delegates DNS to Cloudflare; ownership and registration stay at Name.com. Recreate any email (MX/TXT) records in Cloudflare.
- **Cloudflare Tunnel** (`cloudflared`) opens an outbound connection to Cloudflare, so no router ports are opened.
- **Loopback-only ports** (`127.0.0.1:PORT`) make Docker publish services to this computer only. `cloudflared` can reach them; other devices cannot.
- **HTTPS:** when the web app is opened over HTTPS, `LoginPage.protocol` in `apps/mobile/lib/login_page.dart` uses HTTPS for API calls. The browser calls `https://mdosthi.app/api/...`, which Nginx proxies to the API container.

### 1. Point the domain at Cloudflare

1. Add `mdosthi.app` to a Cloudflare account.
2. At Name.com, replace the domain's nameservers with the two Cloudflare gives you.
3. Verify that the nameservers are `*.ns.cloudflare.com`. Run each command separately. macOS/Linux: `dig NS mdosthi.app +short`. Windows PowerShell: `Resolve-DnsName mdosthi.app -Type NS`.
4. In Cloudflare, SSL/TLS mode must be **Flexible** or **Full** (not Full strict), and Edge Certificates should show an **Active** Universal certificate. New zones can take minutes to hours.

### 2. Configure `.env`

Add these to the Git-ignored `.env` in the repository root (never commit it or paste its secrets anywhere):

```dotenv
FLUTTER_API_HOST=mdosthi.app
FLUTTER_WEB_PORT=127.0.0.1:8081
API_PORT=127.0.0.1:9090
MYSQL_PORT=127.0.0.1:3306
LEGACY_WEB_PORT=127.0.0.1:8080
```

`FLUTTER_API_HOST` is compiled into the web image, so changing it requires a rebuild. Use strong unique secrets and import only the approved database schema/data; Compose creates an empty database.

### 3. Start the services

```bash
docker compose build --no-cache flutter-web
docker compose up -d --force-recreate mysql api flutter-web
docker compose stop legacy-web legacy-rmi
docker compose ps
```

`docker compose ps` must show `127.0.0.1:...` bindings. `--force-recreate` is required after changing port bindings. The legacy JSP services are not needed for the Flutter site. Check the Flutter image uses the public host (the container name may differ; see `docker compose ps`; the command works in any shell):

```bash
docker compose exec flutter-web grep -c "mdosthi.app" /usr/share/nginx/html/main.dart.js
```

The count should be greater than 0.

### 4. Create the tunnel

Install `cloudflared` for your platform ([downloads](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)):

| Platform | Install |
|---|---|
| macOS | `brew install cloudflared` |
| Linux | Use your package manager or the `.deb`/`.rpm`/binary from the downloads page |
| Windows | `winget install --id Cloudflare.cloudflared` |

Then authenticate and create the tunnel (same on all platforms):

```bash
cloudflared tunnel login
cloudflared tunnel create mdosthi
cloudflared tunnel list
```

The credentials directory is `~/.cloudflared/` on macOS/Linux and `%USERPROFILE%\.cloudflared\` on Windows.

- If `login` says a certificate (`cert.pem`) already exists, you are already logged in; skip it.
- If `create` says the name already exists, reuse that tunnel. Find its ID in any of these places:
  - `cloudflared tunnel list`: the `ID` column of the `mdosthi` row.
  - The credentials file name: `<TUNNEL_ID>.json` in the credentials directory.
  - The Cloudflare dashboard: Zero Trust > Networks > Tunnels > your tunnel.
  - The `tunnel:` line in `deploy/cloudflared/config.yml`.

  The tunnel ID is not secret; the `.json` file is.
- The `.json` credentials file and `cert.pem` are secrets. Keep them in that directory and never commit or share them.

Copy [`deploy/cloudflared/config.yml.example`](../deploy/cloudflared/config.yml.example) to `deploy/cloudflared/config.yml` (`cp` in Bash, `Copy-Item` in PowerShell) and edit it:

- Replace `YOUR_TUNNEL_ID` with the tunnel ID.
- Set `credentials-file` to the absolute path of the `.json` file: for example `/Users/you/.cloudflared/ID.json` (macOS), `/home/you/.cloudflared/ID.json` (Linux), or `C:\Users\you\.cloudflared\ID.json` (Windows).

Use plain values with no `<` `>` brackets. Edit the file in an editor; pasting YAML directly at a shell prompt runs each line as a command. The real `config.yml` is Git-ignored.

### 5. Route DNS and run the tunnel

```bash
cloudflared tunnel --config deploy/cloudflared/config.yml ingress validate
cloudflared tunnel route dns --overwrite-dns mdosthi mdosthi.app
cloudflared tunnel --config deploy/cloudflared/config.yml run mdosthi
```

`--overwrite-dns` replaces an existing `mdosthi.app` A/AAAA/CNAME record (otherwise error 1003 "record already exists"). Keep the `run` terminal open. In Cloudflare, Zero Trust > Networks > Tunnels should show the tunnel as **Healthy**, and the `mdosthi.app` DNS record must be **Proxied**. Then open `https://mdosthi.app`.

### Optional: run the tunnel in Docker instead

To avoid installing `cloudflared` on the host (identical on every platform), use the optional `cloudflared` Compose service. It is off unless the `tunnel` profile is enabled. Create the tunnel and DNS route as above (steps 1, 4 and the `route dns` command), then:

1. Copy [`deploy/cloudflared/config.docker.yml.example`](../deploy/cloudflared/config.docker.yml.example) to `deploy/cloudflared/config.docker.yml` and set `YOUR_TUNNEL_ID` and your hostname. It targets `http://flutter-web:80` on the Compose network.
2. Copy the tunnel's `<TUNNEL_ID>.json` credentials file to `deploy/cloudflared/credentials.json`. Both files are Git-ignored; never commit them.
3. Stop any host `cloudflared ... run` process, then start the stack with the profile:

   ```bash
   docker compose --profile tunnel up -d mysql api flutter-web cloudflared
   docker compose logs cloudflared
   ```

   The logs should show registered tunnel connections. Stop it with `docker compose --profile tunnel stop cloudflared`.

### Troubleshooting

| Symptom | Fix |
|---|---|
| `credentials file ... doesn't exist` | Remove `<` `>` from the config; confirm the `.json` file exists in the credentials directory (`ls ~/.cloudflared` or `dir $env:USERPROFILE\.cloudflared`). If lost, `cloudflared tunnel delete mdosthi` and create a new tunnel. |
| `command not found: tunnel:` (or similar) | YAML was pasted into the shell. Save it to the file instead. |
| `Connection reset by peer` on `https://mdosthi.app` | Certificate not yet issued, or a local DNS/network cache. Wait, check Edge Certificates, try mobile data or DNS `1.1.1.1`. Test with `curl -I --resolve mdosthi.app:443:<Cloudflare IP> https://mdosthi.app` (use `curl.exe` in PowerShell). |
| `502` | `flutter-web` is not running on port 8081; run `docker compose up -d flutter-web`. |
| Page loads but login fails | Rebuild `flutter-web` with `FLUTTER_API_HOST=mdosthi.app` and confirm the API and imported database are available. |
| Ports show `0.0.0.0` | `.env` values missing or containers not recreated; use `--force-recreate`. |

Stop everything with `docker compose down` (never `-v`, which deletes the database volume) and `Ctrl+C` in the tunnel terminal.

### Security

The site is public to anyone who can reach the domain; a tunnel does not replace authentication. Do not use real patient or sensitive data on a personal development host. Rotate any secret that has been exposed (WhatsApp token, database and root passwords, `SECRETKEY`) and avoid weak passwords. An internet-facing healthcare system needs approved hosting, access controls, backups, monitoring, and privacy/security review.

## 4. Run Flutter And The API

### Start the API

Ensure JDK 25 is selected and the API's database values in `.env` are correct:

```bash
scripts/api.sh
```

PowerShell:

```powershell
scripts/api.ps1
```

The Spring Boot API listens on port 9090. Keep this terminal open. It will fail at startup if the selected Java version, database, credentials, or required schema are unavailable. Ollama and WhatsApp integrations need their own configuration and services.

### Start the Flutter client

In another terminal, from the repository root:

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome --dart-define=API_HOST=localhost:9090
```

To serve the web build without Flutter's Chrome debugger, run:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 \
	--dart-define=API_HOST=localhost:9090
```

Open the URL printed by Flutter (for the example, `http://127.0.0.1:3001/`). Keep the Flutter process running. The `API_HOST` define is a host and port, not a URL; the app uses HTTP. Use `10.0.2.2:9090` for an Android emulator. For a physical device, use the development computer's LAN IP and ensure firewall/network access is allowed.

The client screen can render without the API, but login and server-backed features require a reachable API and populated compatible database. A web UI returning successfully does not prove credentials or the database are valid.

Flutter selects among devices available to the installed SDK. The web commands above work across macOS, Linux, and Windows. For a device or emulator, set `API_HOST` to an address reachable from that target; `localhost` inside a mobile emulator/device does not refer to the development computer.

## 5. Run The Legacy JSP And RMI System

This workflow requires JDK 11 or later, Tomcat 9, a compatible `mDosthi` schema and the legacy configuration files. Confirm `services/legacy/runtime/gblinfo.inf` contains the right local DB connection before starting.

```bash
export JAVA_HOME=/path/to/jdk-11
scripts/legacy.sh start
```

Commands:

| Command | Effect |
|---|---|
| `scripts/legacy.sh start` | Starts Tomcat and the existing RMI business-logic jar. |
| `scripts/legacy.sh stop` | Stops Tomcat and the legacy RMI process. |
| `scripts/legacy.sh build` | Recompiles legacy modules and generates jars. |
| `scripts/legacy.sh run` | Builds, stops the old process, then starts both services. |

The script prints the web URL based on `tools/tomcat9/conf/server.xml`; open that URL with `/M-Dosthi/`. The default Tomcat port is 8080, but local configurations can use a different port (for example 8081). The RMI service normally uses port 1099. Check the ports and stop any conflicting services before starting.

### Legacy clean-checkout limitation

Some old legacy components do not have corresponding Java source in this repository. In particular, `drawchart` has historically been available only as a compiled class, while `.class` files and generated jars are ignored by Git. Therefore a legacy rebuild from a clean clone may fail or need a separately supplied, approved legacy artifact. A successful run on a developer machine with local build output does not establish a reproducible cross-platform build. Do not copy arbitrary compiled classes from patient or production systems; arrange for the missing source/artifact to be reviewed and distributed through an approved channel.

## 6. Optional Annotation Pipeline

Read [the annotation package README](../services/annotate/README.md) for supported inputs and commands. Use an isolated Python environment and install the shared dependencies from the repository-root `requirements.txt`, then start/configure Ollama if the selected workflow calls a local model. Do not place patient data in example inputs or generated logs unless it is authorized and protected.

## Ports At A Glance

| Port | Service | Notes |
|---:|---|---|
| 3306 | MySQL | Local default; may be changed in JDBC URLs/Compose. |
| 8080 | Tomcat | Legacy web default; inspect `server.xml` for the configured port. |
| 1099 | Java RMI | Legacy business-logic service. |
| 9090 | Spring Boot API | Flutter app's default API port. |
| 11434 | Ollama | Optional local model server. |
| 3000/3001 | Flutter web development server | Selected by Flutter; use the actual URL it prints. |

## Troubleshooting

- **API reports that JDK 25 is required:** install JDK 25, set `JAVA_HOME` to the JDK installation directory (not `bin/java`), and verify `"$JAVA_HOME/bin/java" -version` before running `scripts/api.sh`. On macOS with Homebrew, use `brew install openjdk@25`.
- **Suicide ideation tracking is disabled because database tables are missing:** the API can start, but the background alert poller remains disabled. Import the approved schema containing `signal_history`, `session_history`, and `login`, then restart the API. Do not create placeholder tables.
- **Login returns “Invalid Credential” for an account created by an older API:** restart with the current API; when the correct password is entered, legacy plaintext password rows are migrated to the format expected by login. Login resolves User IDs case-insensitively and retries after trimming surrounding whitespace from the username and password, matching the legacy JSP login while preserving exact credentials when they work. If it still fails, verify the account and password in the database configured by `SPRING_DATASOURCE_URL`.
- **`Access denied` or connection refused from MySQL:** verify the server is running, host/port are reachable, and that the credentials in `.env` (API) or `gblinfo.inf` (legacy) match the DB user. Test the exact JDBC schema name.
- **Unknown database/table:** Compose creates an empty schema, not application tables. Import the correct approved dump before using the app; apply only the migrations intended for that schema.
- **Flutter login says failed to fetch:** confirm the API is listening on 9090, set the correct `API_HOST` for the target device, and check browser/network CORS errors.
- **Flutter web asset manifest is missing:** stop the stale Flutter process, run `flutter pub get`, then start Flutter again from `apps/mobile` and open the new URL it prints.
- **`JDK 11 or later with javac required`:** set `JAVA_HOME` to a JDK installation. The legacy build uses dynamic RMI stubs and does not invoke `rmic`.
- **Tomcat or RMI port is occupied:** inspect listeners on the configured HTTP port and 1099, stop the conflicting application, and start again. Do not kill unrelated Java processes indiscriminately.
- **Legacy rebuild errors for absent classes:** see the clean-checkout limitation above; local ignored build output may have hidden the missing artifact.

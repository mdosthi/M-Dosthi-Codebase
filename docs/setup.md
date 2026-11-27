# Setup Guide

This guide covers the independently runnable parts of the M-Dosthi repository. The normal Flutter workflow is `apps/mobile` plus `services/api`; the older JSP/Tomcat workflow is `apps/web` plus the RMI process in `services/legacy`. They have separate DB configuration and can target different schemas.

## Choose A Workflow

| You want to run | Required parts | Entry point |
|---|---|---|
| Flutter client in a browser/device | MySQL with the expected schema, Spring Boot API, Flutter SDK | `services/api` and `apps/mobile` |
| Legacy JSP website | MySQL with the legacy schema, Tomcat 9, legacy RMI process | `apps/web` and `services/legacy` |
| Python annotation tools | Python environment and, for model calls, Ollama | `services/annotate` |

You do not need to start both Java servers for the Flutter workflow. The JSP application is not the Flutter app's API server.

## Choose A Platform

The Flutter client and Spring API can run natively on macOS, Linux, and Windows.

| macOS | Linux | Windows |
|---|---|---|
| Use `scripts/setup.sh`, `scripts/api.sh`, and `scripts/legacy.sh` from Terminal; Flutter runs natively. | Use `scripts/setup.sh`, `scripts/api.sh`, and `scripts/legacy.sh` from a shell; Flutter runs natively. | Use `scripts/setup.ps1`, `scripts/api.ps1`, and `scripts/legacy.ps1` from PowerShell (or the `.sh` scripts in Git Bash/WSL); Flutter runs natively. |

This requires you to install and configure JDK 25, Flutter, and MySQL 8 yourself (MySQL may be local or remote).

To start Flutter and the API, follow [Run Flutter And The API](#4-run-flutter-and-the-api).

## Prerequisites

Install the tools needed for your chosen workflow. The repository setup scripts do not install Java, Flutter, Python, MySQL, or Ollama.

| Tool | Used by | Notes |
|---|---|---|
| Git | All workflows | Clone this repository. |
| JDK 25 | `services/api` | Required by `services/api/pom.xml`; set `JAVA_HOME` and `PATH` before starting Maven. |
| JDK 11 or later | Legacy build and runtime | Must include `javac`. The legacy RMI service uses dynamic stubs and does not require the removed `rmic` tool; builds target Java 11 bytecode. A local `tools/jdk11` may still be used; `tools/` is not part of Git. |
| MySQL 8 | API and legacy workflows | Use a local server or a remote server. You need a compatible database dump/schema. |
| Flutter SDK | `apps/mobile` | Chrome is needed for the Chrome target; `web-server` can be used with another browser. |
| Python 3.10+ | `services/annotate` | Create an isolated environment and install the package's declared dependencies. |
| Ollama | Annotation and configured API features | Install separately, start the service, and download/configure the model names required by your workflow. |

### Install dependencies by platform

**macOS (Homebrew):**

```bash
brew install git openjdk@25 maven mysql python
brew install --cask flutter ollama
brew services start mysql
```

**Linux (Ubuntu / Debian):**

```bash
sudo apt update
sudo apt install -y git curl unzip mysql-server maven python3 python3-venv python3-pip
# Install JDK 25 (or via SDKMAN: curl -s "https://get.sdkman.io" | bash && sdk install java 25-open)
sudo apt install -y openjdk-25-jdk || sudo apt install -y openjdk-21-jdk
sudo systemctl enable --now mysql
# Flutter (Linux desktop/web dependencies + SDK)
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
sudo snap install flutter --classic
# Ollama
curl -fsSL https://ollama.com/install.sh | sh
```

**Linux (Fedora / RHEL):**

```bash
sudo dnf install -y git curl unzip mysql-server maven python3 clang cmake ninja-build gtk3-devel xz-devel
sudo systemctl enable --now mysqld
```

**Windows (PowerShell / winget):**

```powershell
winget install Git.Git
winget install EclipseAdoptium.Temurin.25.JDK
winget install Oracle.MySQL
winget install Google.Flutter
winget install Python.Python.3.12
winget install Ollama.Ollama
```

On Windows, run `scripts/setup.ps1`, `scripts/provision-api-db-user.ps1`, `scripts/api.ps1`, and `scripts/legacy.ps1` in PowerShell (or run the `.sh` scripts in Git Bash or WSL). Flutter can use native Windows tooling for targets supported by the installed Flutter SDK.

## 1. Clone And Prepare Local Files

From a terminal:

```bash
git clone REPOSITORY_URL M-Dosthi
cd M-Dosthi
scripts/setup.sh
```

PowerShell:

```powershell
git clone REPOSITORY_URL M-Dosthi
Set-Location M-Dosthi
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

The setup script prepares local configuration and Tomcat, then reports which prerequisite commands are on `PATH`. It does not install those prerequisites or initialize application tables. If `.env` is missing, it copies `.env.example` to `.env`; the tracked `.env.example` template is not modified. Edit only `.env` with local values. It also creates `services/legacy/runtime/gblinfo.inf` and `apps/web/config.info` from templates, replacing `@PROJECT_ROOT@` with this checkout's absolute path, `@TOMCAT_HTTP_PORT@` with the active Tomcat port (`8081` for Individual Tomcat, `8080` for Shared Tomcat), and `@LEGACY_RMI_PORT@` with the RMI port (default `1100` in both modes so it does not collide with eDosthi's `1099`). Set `LEGACY_RMI_PORT` before setup to choose another port. Generated files are not overwritten on later setup runs, so preserve your local edits.

`tools/tomcat9/` is bundled and tracked in Git (with the `Tomcat9 -> tools/tomcat9` symlink on macOS/Linux) as M-Dosthi's Individual Tomcat (`:8081`, shutdown `:8006`), while other local runtimes under `tools/` remain Git-ignored. If `tools/tomcat9` is absent, setup downloads Tomcat 9 there automatically; a Java distribution is not automatically downloaded. Install the needed JDKs yourself and keep their paths outside version control.

## 2. Configure Java And Secrets

Copy `.env.example` to `.env` in the repository root, then edit `.env`. It is ignored by Git; keep one value per line as `NAME=value`. Never put passwords, API tokens, or other credentials in `.env.example`; it is a tracked template shared with the repository.

For the API, select JDK 25 before launching.

macOS (Homebrew):

```bash
brew install openjdk@25
export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

Linux:

```bash
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64   # or your JDK 25 path
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

Windows (PowerShell):

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-25'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

`scripts/api.sh` and `scripts/api.ps1` also auto-discover JDK 25 in standard macOS Homebrew, Linux (`/usr/lib/jvm`, `/opt`, SDKMAN), and Windows (`C:\Program Files\Eclipse Adoptium`, `C:\Program Files\Java`, `C:\Program Files\Microsoft`) locations when `JAVA_HOME` is unset. If the JDK is installed elsewhere, set `JAVA_HOME` to its installation directory. The API script checks that `JAVA_HOME` contains JDK 25 before starting Maven.

For legacy build commands, select JDK 11 or later:

```bash
export JAVA_HOME=/path/to/jdk-11
export PATH="$JAVA_HOME/bin:$PATH"
"$JAVA_HOME/bin/javac" -version
```

The most important API values in `.env` are `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, and `SECRETKEY`. Use a dedicated, non-root MySQL account for `SPRING_DATASOURCE_USERNAME`; `MYSQL_ROOT_PASSWORD` is only for database administration and must not be used as the API password. For a local MySQL database, `scripts/provision-api-db-user.sh` creates the API account using the Spring datasource username and password. Replace the example database password with a strong, unique value. Generate a unique key, for example with `openssl rand -base64 32`; do not reuse any credentials from historical files. Ollama model settings and `IMEDIX_WHATSAPP_*` values are only needed for those integrations. Set `OLLAMA_LOG_PAYLOAD_ENABLED=false` where prompt payloads may contain patient data.

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

### Provision local MySQL database and user

Start your MySQL 8 server using your operating system's service manager, then set `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD` in `.env`. Provision the schema and dedicated non-root application user using:

macOS / Linux:

```bash
bash scripts/provision-api-db-user.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/provision-api-db-user.ps1
```

The script uses `MYSQL_ROOT_PASSWORD` only to administer the database; it creates the `MYSQL_DATABASE` schema and the dedicated API user, granting it access only to `MYSQL_DATABASE`. For a database server not on `127.0.0.1:3306`, set `MYSQL_ADMIN_HOST` and `MYSQL_ADMIN_PORT` in `.env` to the server's administration endpoint. The failure `Access denied for user ...` means MySQL rejected the configured credentials or the account lacks access from the API host; restarting the API alone will not repair credentials.

For local legacy testing without a backup, the repository README documents a guarded [minimal local development bootstrap](../README.md#fresh-local-database-local-legacy-testing). It supports local accounts, basic patient registration, screening checkpoints, and chat persistence tables, but is not a full database initialization and does not enable the other clinical workflows. Chat remains restricted to patients explicitly enrolled in the RCT.

### Import an approved database

Database snapshots/backups are intentionally not distributed in Git. Obtain the correct approved dump through your organization's secure channel, verify the target environment and backup status, then import it into the matching schema. Never use real patient data in an unapproved development environment.

Example import commands (the password is prompted, not placed in shell history):

```bash
mysql --host=127.0.0.1 --user=YOUR_USER --database=mDosthi -p < /secure/path/to/approved-api-dump.sql
mysql --host=127.0.0.1 --user=YOUR_USER --database=mDosthi -p < /secure/path/to/approved-legacy-dump.sql
mysql --host=127.0.0.1 --user=YOUR_USER --database=mDosthi -p < services/api/src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql
```

Only import schemas you actually have and intend to use. Do not assume the API and legacy application can share a database simply because both use MySQL; confirm the schema and tables in the supplied dump first.

The PO Bado migrations in `database/migrations` are for the `mDosthi` legacy schema. They are not general database initialization scripts and are not applied automatically. Back up first and follow [the migration runner guide](../database/migration-runner/README.md); its database guard rejects other schema names.

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

## 4. Run The Legacy JSP And RMI System

This workflow requires JDK 11 or later, Tomcat 9, a compatible `mDosthi` schema and the legacy configuration files. Confirm `services/legacy/runtime/gblinfo.inf` contains the right local DB connection before starting.

```bash
export JAVA_HOME=/path/to/jdk-11
scripts/legacy.sh start --individual   # or --shared
```

Commands (pass `--individual` [default] or `--shared` / `SHARED_TOMCAT_HOME` on Linux/macOS, and `-Mode individual|shared` on Windows):

| Command | Effect |
|---|---|
| `scripts/legacy.sh start` | Starts M-Dosthi's Individual Tomcat (`:8081`) and RMI business-logic jar (`:1100`); with `--shared` / `SHARED_TOMCAT_HOME`, starts only M-Dosthi RMI. |
| `scripts/legacy.sh stop` | Stops M-Dosthi's Individual Tomcat and RMI process; with `--shared` / `SHARED_TOMCAT_HOME`, stops only M-Dosthi RMI. |
| `scripts/legacy.sh build` | Recompiles legacy modules and generates jars against the selected Tomcat's `servlet-api.jar`. |
| `scripts/legacy.sh run` | Builds and restarts the stack; with `--shared` / `SHARED_TOMCAT_HOME`, leaves Shared Tomcat running and restarts only M-Dosthi RMI. |
| `scripts/legacy.sh status` | Shows live PID and port status for M-Dosthi RMI, Individual Tomcat (`:8081`), and (with `--shared`) Shared Tomcat (`:8080`). |

The Individual Tomcat defaults to `http://localhost:8081/mDosthi/` (shutdown port `8006`, configurable via `TOMCAT_HTTP_PORT` / `TOMCAT_SHUTDOWN_PORT`), while Shared Tomcat typically uses `http://localhost:8080/mDosthi/`. The setup also keeps `/M-Dosthi/` as a compatibility alias. Both default M-Dosthi's RMI port (`blport`) to `1100`. Check the ports and stop any conflicting services before starting.

### Run M-Dosthi in an existing Tomcat 9

Use this workflow when eDosthi already runs in Tomcat 9 and you want M-Dosthi served by the same Tomcat instance as well as (or instead of) M-Dosthi's Individual Tomcat, without changing eDosthi application source. `SHARED_TOMCAT_HOME` (or `--shared` / `-Mode shared`) must point to the Tomcat 9 installation directory (the directory containing `bin/`, `conf/`, and `lib/`). The setup script adds `mDosthi.xml` and the compatibility descriptor `M-Dosthi.xml` to that Tomcat, both pointing to this checkout's `apps/web` (while also configuring M-Dosthi's Individual Tomcat in `tools/tomcat9`); it does not edit eDosthi source or its application files. If eDosthi's Tomcat installation is inside its repository, this adds Tomcat deployment descriptors there; use a Tomcat installation outside that repository if you need to keep every file in it untouched.

Linux/macOS or Git Bash:

```bash
export SHARED_TOMCAT_HOME=/absolute/path/to/tomcat9
scripts/setup.sh --shared
```

PowerShell:

```powershell
$env:SHARED_TOMCAT_HOME = 'C:\path\to\tomcat9'
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -Mode shared
```

Setup writes both `/mDosthi` and compatibility `/M-Dosthi` context descriptors into M-Dosthi's Individual Tomcat (`tools/tomcat9`) and the shared Tomcat configuration. Configure the generated local files and build the web application before restarting the shared Tomcat to deploy `/mDosthi`; do not use M-Dosthi's script to restart or stop that Tomcat:

- In `apps/web/config.info`, set `gblhome` to the externally reachable M-Dosthi URL (`http://localhost:8080/mDosthi` for Shared Tomcat, `http://localhost:8081/mDosthi` for Individual Tomcat). Set `gbltelemedix` to `/mDosthi`.
- In **both** `apps/web/config.info` and `services/legacy/runtime/gblinfo.inf`, set `blport` to the same unused RMI port (default `1100`; override at setup with `LEGACY_RMI_PORT`). Ensure firewall rules permit the selected port as required. `scripts/legacy.sh start` and `scripts/legacy.ps1 start` check that the two configured port values match.
- Confirm M-Dosthi's DB credentials, temp/log paths, and integrations are configured for its intended environment. These are separate from the shared Tomcat and should not be assumed to match eDosthi's.

Keep the same `SHARED_TOMCAT_HOME` (or `--shared`) when running build/start/stop for shared mode:

```bash
export JAVA_HOME=/path/to/jdk-11
scripts/legacy.sh build --shared
# Restart the shared Tomcat now so it loads the built /mDosthi app.
scripts/legacy.sh start --shared
```

`scripts/legacy.sh stop` stops only the M-Dosthi RMI process in shared-Tomcat mode. The script tracks its own RMI process by PID so it does not terminate eDosthi's service. The servlet build uses the shared Tomcat's `lib/servlet-api.jar`. If the legacy RMI service was started by an older script version and has no M-Dosthi PID file, stop that known M-Dosthi process once before using the updated script; do not terminate Java processes by matching the shared jar name. The web UI should be available at the `gblhome` URL, commonly `http://localhost:8080/mDosthi/` for local testing.

The Spring Boot API is not deployed inside Tomcat 9; it remains a separate process on its configured port. The Flutter/API workflow is independent of this shared JSP deployment.

### Legacy clean-checkout limitation

Some old legacy components do not have corresponding Java source in this repository. In particular, `drawchart` has historically been available only as a compiled class, while `.class` files and generated jars are ignored by Git. Therefore a legacy rebuild from a clean clone may fail or need a separately supplied, approved legacy artifact. A successful run on a developer machine with local build output does not establish a reproducible cross-platform build. Do not copy arbitrary compiled classes from patient or production systems; arrange for the missing source/artifact to be reviewed and distributed through an approved channel.

## 5. Optional Annotation Pipeline

Read [the annotation package README](../services/annotate/README.md) for supported inputs and commands. Use an isolated Python environment and install the shared dependencies from the repository-root `requirements.txt`, then start/configure Ollama if the selected workflow calls a local model. Do not place patient data in example inputs or generated logs unless it is authorized and protected.

## Ports At A Glance

| Port | Service | Notes |
|---:|---|---|
| 3306 | MySQL | Local default; may be changed in JDBC URLs. |
| 8080 | Shared Tomcat | Shared Tomcat default (serves `/eDosthi` and `/mDosthi` when configured). |
| 8081 | Individual Tomcat | M-Dosthi bundled Tomcat (`tools/tomcat9`, shutdown `8006`, configurable via `TOMCAT_HTTP_PORT`). |
| 1100 | Java RMI | M-Dosthi RMI default in both Individual and Shared modes (avoids collision with eDosthi `1099`). |
| 9090 | Spring Boot API | Flutter app's default API port. |
| 11434 | Ollama | Optional local model server. |
| 3000/3001 | Flutter web development server | Selected by Flutter; use the actual URL it prints. |

## Troubleshooting

- **API reports that JDK 25 is required:** install JDK 25, set `JAVA_HOME` to the JDK installation directory (not `bin/java`), and verify `"$JAVA_HOME/bin/java" -version` before running `scripts/api.sh`. On macOS with Homebrew, use `brew install openjdk@25`.
- **Suicide ideation tracking is disabled because database tables are missing:** the API can start, but the background alert poller remains disabled. Import the approved schema containing `signal_history`, `session_history`, and `login`, then restart the API. Do not create placeholder tables.
- **Login returns “Invalid Credential” for an account created by an older API:** restart with the current API; when the correct password is entered, legacy plaintext password rows are migrated to the format expected by login. Login resolves User IDs case-insensitively and retries after trimming surrounding whitespace from the username and password, matching the legacy JSP login while preserving exact credentials when they work. If it still fails, verify the account and password in the database configured by `SPRING_DATASOURCE_URL`.
- **`Access denied` or connection refused from MySQL:** verify the server is running, host/port are reachable, and that the credentials in `.env` (API) or `gblinfo.inf` (legacy) match the DB user. Test the exact JDBC schema name.
- **Unknown database/table:** Import the correct approved dump before using the app; apply only the migrations intended for that schema.
- **Flutter login says failed to fetch:** confirm the API is listening on 9090 and `API_HOST` is reachable from the target. For Flutter web, pass `--dart-define=API_HOST=localhost:9090` (or the reachable API host and port) and ensure cross-origin API hosts allow the browser origin through CORS.
- **Flutter web asset manifest is missing:** stop the stale Flutter process, run `flutter pub get`, then start Flutter again from `apps/mobile` and open the new URL it prints.
- **`JDK 11 or later with javac required`:** set `JAVA_HOME` to a JDK installation. The legacy build uses dynamic RMI stubs and does not invoke `rmic`.
- **Tomcat or RMI port is occupied:** inspect listeners on the configured HTTP port and the RMI port in both M-Dosthi config files. For a shared Tomcat, leave Tomcat running and choose an unused M-Dosthi RMI port. Do not kill unrelated Java processes indiscriminately.
- **M-Dosthi does not appear in the shared Tomcat:** confirm `SHARED_TOMCAT_HOME` points at the right Tomcat 9 installation, that `conf/Catalina/localhost/mDosthi.xml` points to the M-Dosthi `apps/web` directory, and that Tomcat was restarted after setup.
- **Legacy rebuild errors for absent classes:** see the clean-checkout limitation above; local ignored build output may have hidden the missing artifact.

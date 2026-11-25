<p align="center">
  <img src="apps/web/images/mdosthi-primary-logo.png" alt="mDosthi — Digital Health &amp; Well-Being · Healthcare as Homecare" width="540" />
</p>

# M-Dosthi

M-Dosthi is a healthcare application monorepo containing the legacy JSP/Tomcat system, a Flutter client, a Spring Boot REST API, and a Python annotation pipeline. The system has more than one application path: the legacy web application uses its Java RMI business logic, while the Flutter client calls the Spring Boot API. They have separate configuration and may use different MySQL schemas.

## Contents

- [Choose a workflow](#choose-a-workflow)
- [Repository map](#repository-map)
- [Components and prerequisites](#components-and-prerequisites)
- [macOS, Linux, and Windows](#macos-linux-and-windows)
- [Quick start: Flutter and API](#quick-start-flutter-and-api)
- [Quick start: legacy JSP system](#quick-start-legacy-jsp-system)
- [Database and configuration safety](#database-and-configuration-safety)
- [Tests and development](#tests-and-development)
- [Troubleshooting](#troubleshooting)
- [More guides](#more-guides)

## Choose A Workflow

| Goal | Start here | Important note |
|---|---|---|
| Run the Flutter app and Spring API | [Flutter and API quick start](#quick-start-flutter-and-api) | Login and server-backed features need a reachable API and a compatible, populated database. |
| Run the older JSP website | [Legacy JSP quick start](#quick-start-legacy-jsp-system) | This is a separate application path using Tomcat, Java RMI, and its own legacy configuration. |
| Run M-Dosthi beside eDosthi | [All-in-One Setup & Shared Tomcat Guide](docs/all-in-one-setup-and-shared-tomcat-guide.md) | Complete end-to-end setup, DB backup restore, and line-by-line Shared Tomcat implementation. |
| Run annotation tools | [Annotation package guide](services/annotate/README.md) | Requires Python and, for model-backed work, Ollama. |
| Understand services and data flow | [Architecture guide](docs/architecture.md) | The legacy site and Flutter/API application are not the same backend. |

The full [setup guide](docs/setup.md) covers platform prerequisites, schema imports, optional integrations, ports, and troubleshooting. Choose one application workflow at a time; the legacy web app is not required to run Flutter.

## Repository Map

```text
.
├── apps/
│   ├── web/                         Legacy JSP site and static web assets
│   │   ├── WEB-INF/                 Deployment descriptors and third-party jars
│   │   ├── jspfiles/                JSP pages and server-rendered workflows
│   │   ├── forms/, templates/       Web forms and page templates
│   │   ├── includes/, images/       Shared JSP fragments and images
│   │   ├── bootstrap/, style/       Front-end libraries and styles
│   │   └── config.info.template     Local web configuration template
│   └── mobile/                      Flutter client (Android, iOS, web, desktop)
│       ├── lib/                     Screens, workflows, services, models
│       ├── assets/                  Images, icons, surveys, PDFs, media
│       ├── ios/, linux/, macos/     Platform runners
│       ├── windows/, web/           Platform runners
│       ├── test/                    Flutter tests
│       ├── pubspec.yaml             Dart/Flutter dependencies
│       └── pubspec.lock             Resolved dependency versions
├── services/
│   ├── api/                         Spring Boot REST API used by Flutter
│   │   ├── src/main/java/           Controllers and application logic
│   │   ├── src/main/resources/      Properties and prompt resources
│   │   ├── src/test/java/           API tests
│   │   ├── pom.xml                  Java 25 and Maven dependencies
│   │   └── mvnw, mvnw.cmd           Maven wrapper for Linux/macOS and Windows
│   ├── legacy/
│   │   ├── server-src/              Legacy RMI business-logic Java sources
│   │   ├── servlet-src/             Servlet Java sources and build script
│   │   ├── runtime/                 RMI launch files and local config template
│   │   └── external-lib/            Legacy compile-time dependencies
│   └── annotate/                    Python/Ollama annotation pipeline
│       ├── agents/, llm/            Agent and model integrations
│       ├── prompts/, schemas/       Prompt templates and data schemas
│       ├── db/, utils/              Persistence and helper code
│       ├── examples/                Example inputs and usage
│       └── pyproject.toml           Python package metadata and dependencies
├── database/
│   ├── migrations/                  Versioned SQL schema changes
│   ├── migration-runner/            Java migration application tool
│   └── snapshots/                   Local SQL imports; ignored by Git
├── docs/                            Setup, architecture, API, development guides
├── scripts/                         Cross-platform setup and run helpers
├── Tomcat9 -> tools/tomcat9         Symlink to bundled M-Dosthi Individual Tomcat 9 (:8081)
├── requirements.txt                 All Python runtime dependencies
├── .env.example                     Safe local configuration template
├── .gitignore, .gitattributes       Secret/generated-file and line-ending rules
├── tools/                           Bundled Individual Tomcat (`tools/tomcat9/`) and optional local runtimes
└── local-archive/                   Historical copies and backups; ignored by Git
```

## Components And Prerequisites

| Component | Runtime | Database/API | Start command |
|---|---|---|---|
| Flutter client (`apps/mobile`) | Flutter SDK; Chrome for web, or a configured platform runner | Calls `services/api` on port 9090 | `flutter run -d chrome --dart-define=API_HOST=localhost:9090` |
| REST API (`services/api`) | JDK 25; Maven wrapper included | MySQL 8; Ollama for configured AI features | `scripts/api.sh` or `scripts/api.ps1` |
| Legacy JSP site (`apps/web`) | Tomcat 9 (Individual `:8081` or Shared `:8080`); JDK 11+ for servlet build | Uses legacy Java business logic | `scripts/legacy.sh run` (or `--shared`) / `scripts/legacy.ps1 run` |
| Legacy RMI business logic (`services/legacy`) | JDK 11 or later; Bash or PowerShell | MySQL configuration in `runtime/gblinfo.inf` | Started with the legacy script |
| Annotation pipeline (`services/annotate`) | Python 3.10+; dependencies in project files | Ollama; optional database integrations | See `services/annotate/README.md` |

For manual development, the Flutter/API workflow requires the Flutter SDK and JDK 25; the legacy web workflow needs JDK 11 or later. On Windows, use PowerShell (`scripts/*.ps1`) or Git Bash / WSL (`scripts/*.sh`).

### macOS, Linux, and Windows

The Flutter client, Spring API, and legacy stack can be developed on macOS, Linux, or Windows using native tools; the detailed commands and prerequisites are in the [setup guide](docs/setup.md#choose-a-platform).

| macOS / Linux | Windows |
|---|---|
| Use the Flutter SDK, JDK 25, and a local/remote MySQL 8 server. Run `scripts/setup.sh`, `scripts/provision-api-db-user.sh`, `scripts/api.sh`, and `scripts/legacy.sh` from a shell. | Use the Flutter SDK, JDK 25, and a local/remote MySQL 8 server. Run `scripts/setup.ps1`, `scripts/provision-api-db-user.ps1`, `scripts/api.ps1`, and `scripts/legacy.ps1` from PowerShell (or the `.sh` scripts in Git Bash/WSL). |

## Quick Start: Flutter And API

Use this route to run the client and API natively on macOS, Linux, or Windows. Install Git, Flutter, JDK 25, and MySQL 8; MySQL can run locally or on a reachable development server. For Windows, run the setup and API scripts in PowerShell. From the repository root, prepare local files:

```bash
scripts/setup.sh
```

On Windows, use:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

Copy `.env.example` to `.env` if setup did not create it, then configure the API database URL, username, password, and secret. Create or obtain the compatible database schema separately; setup does not initialize application tables or import data. Start the API in one terminal:

```bash
scripts/api.sh
```

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/api.ps1
```

In another terminal, launch the Flutter web client:

```bash
cd apps/mobile
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 \
  --dart-define=API_BASE_URL=http://127.0.0.1:9090 \
  --dart-define=API_HOST=127.0.0.1:9090
```

Open the local URL printed by Flutter. Use `flutter devices` to see the targets available in your Flutter installation. `API_HOST` is a host and port, not a URL; for an Android emulator use `10.0.2.2:9090`, and for a physical device use a development-computer address reachable from the device. Login and server-backed features require the API and compatible database tables. See [the full setup guide](docs/setup.md#4-run-flutter-and-the-api) for Java configuration, schema requirements, alternate ports, and troubleshooting.

### Install Python dependencies

For the annotation pipeline, install `uv` first if it is not already available. From the repository root, create a virtual environment and install the dependencies listed in `requirements.txt`:

```bash
uv venv
uv pip install -r requirements.txt
```

Run these commands from the repository root because `requirements.txt` includes the local `services/annotate` package.

## Manual Development: Flutter And API

The Flutter app can run in a browser or on a supported device. Login and other server-backed features require the API and a populated compatible database. To run Flutter and the legacy JSP website together, start MySQL and use three terminals: one for the API, one for Flutter, and one for the legacy JSP/RMI services.

### One-time setup

From the repository root:

```bash
git clone REPOSITORY_URL M-Dosthi
cd M-Dosthi
scripts/setup.sh
```

On Windows, run `powershell -ExecutionPolicy Bypass -File scripts/setup.ps1` instead.

The setup script copies `.env.example` to `.env` if it does not exist; it does not modify the tracked template. Edit `.env` only with your local database settings. Generate a JWT secret with `openssl rand -base64 32` and put the output in `SECRETKEY`. Start your local MySQL 8 server, provision the database and user with `bash scripts/provision-api-db-user.sh`, and import an approved compatible database dump.

See [Setup instructions](docs/setup.md) for database import and configuration details.

### Optional English chat speech

The patient chat UI can read an English assistant response aloud after the user selects **Listen**. It uses Ollama's speech API with the separate Phonon model; Ollama remains the LLM and the displayed response is unchanged. Install the model on the Ollama host with `ollama pull phonon` (Ollama 0.40.9+). Speech is English-only and generated on demand by the configured Ollama host. The API does not cache or save the generated audio. See [speech setup and configuration](docs/setup.md#optional-english-speech-playback), including the data-handling implications of a remote Ollama host.

### Chat voice input

The chat microphone button uses the browser or device speech-recognition service to put dictated words into the message field; it does not use Ollama. Recognition support depends on the platform and browser, and the platform provider may process audio online. Review the [voice input setup and data-handling notes](docs/setup.md#chat-voice-input). Dictation only fills the draft; the patient must press Send to submit it.

### Terminal 1: start the API

From the repository root (the directory containing `scripts/` and `apps/`), select JDK 25 and start the API. On macOS/Linux:

```bash
scripts/api.sh
```

On Windows, use PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/api.ps1
```

Set `JAVA_HOME` to the JDK installation directory (not the path to the `java` executable) if it is not already configured. On macOS, `scripts/api.sh` can also find a JDK 25 installed through Homebrew or registered with the system. Keep this terminal open; the API listens on port `9090`.

To use another API port, pass it to Spring Boot:

```bash
scripts/api.sh -Dspring-boot.run.arguments=--server.port=9091
```

If JDK 25 is installed in a custom location, set `JAVA_HOME` to that JDK's installation directory:

```bash
export JAVA_HOME="/path/to/jdk-25"
export PATH="$JAVA_HOME/bin:$PATH"
scripts/api.sh
```

### Terminal 2: start Flutter in a browser

Open a second terminal at the repository root, then run:

```bash
cd apps/mobile
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 \
  --dart-define=API_BASE_URL=http://127.0.0.1:9090 \
  --dart-define=API_HOST=127.0.0.1:9090
```

Open `http://127.0.0.1:3001/` in your browser. Keep this terminal open while using the app. Alternatively, if Chrome is installed, run Flutter with Chrome:

```bash
flutter run -d chrome --dart-define=API_HOST=localhost:9090
```

If the API is using port `9091`, change the Flutter define to `--dart-define=API_HOST=localhost:9091` as well. The API and Flutter client must use matching ports.

If Flutter reports that port `3001` is already in use, first open `http://127.0.0.1:3001/`; an existing Flutter server may already be running. To start an additional server, use another port such as `3002` and open the URL with that port:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3002 \
  --dart-define=API_HOST=localhost:9090
```

For an Android emulator, set `API_HOST=10.0.2.2:9090`; for a physical phone, use the development computer's LAN IP and ensure the API is reachable. The Flutter UI may start without the API, but login and server-backed features will fail.

### Terminal 3: start the legacy JSP website

The legacy website is independent of Flutter and uses JDK 11 or later, Tomcat, and its RMI service. Configure `services/legacy/runtime/gblinfo.inf` for the legacy database and confirm the generated build artifacts are available. From a third terminal at the repository root, run this the first time or when rebuilding:

macOS / Linux:

```bash
scripts/legacy.sh run
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 run
```

After the legacy build artifacts are ready, on later starts use `scripts/legacy.sh start` (or `scripts/legacy.ps1 start` on Windows) instead of rebuilding. Keep the terminal open. Open the URL printed by the script (Individual Tomcat defaults to `http://localhost:8081/M-Dosthi/`, Shared Tomcat defaults to `http://localhost:8080/M-Dosthi/`). Both Individual and Shared modes default the M-Dosthi RMI port to `1100` so it does not collide with eDosthi (`1099`). Set `LEGACY_RMI_ADVERTISE_HOST` to a reachable address when clients connect from another machine.

The API and legacy build/runtime can use JDK 25. Set `JAVA_HOME` separately in each terminal if you run both Java services; do not try to run both from a single terminal environment. See [the legacy build notes](docs/setup.md#legacy-clean-checkout-limitation) if `scripts/legacy.sh run` fails on a clean checkout because a required artifact is missing.

## Quick Start: Legacy JSP System

The legacy stack is separate from the Flutter/API path. It needs JDK 11 or later, MySQL and a compatible legacy schema. Its build uses dynamic RMI stubs and does not require `rmic`. On a clean checkout, confirm that required legacy build artifacts are available before relying on the build command; see [Legacy Build Notes](docs/setup.md#legacy-web-and-rmi).

The screening migration runner requires Java 11 or later and Maven:

- **macOS (Homebrew):** `brew install maven openjdk@25`
- **Linux (Ubuntu/Debian):** `sudo apt install -y maven openjdk-25-jdk`
- **Windows (winget):** `winget install Apache.Maven EclipseAdoptium.Temurin.25.JDK`

Once Java and Maven are available, build and run the migration runner from the repository root:

```bash
mvn -f database/migration-runner/pom.xml package
java -jar database/migration-runner/target/pobado-migration-runner-1.0.0.jar
```

The runner reads the legacy database configuration, applies only pending migrations, and refuses databases other than `mDosthi`. It does not initialize a fresh legacy schema, and migrations are not applied automatically when Tomcat starts. See the [migration runner guide](database/migration-runner/README.md) before applying them to a production database.

### Individual Tomcat Guide (Standalone M-Dosthi on `:8081`)

M-Dosthi bundles its own Tomcat 9 in `tools/tomcat9` (symlinked at `Tomcat9 -> tools/tomcat9` on macOS/Linux) so you can run M-Dosthi independently of `eDosthi` — or side-by-side with `eDosthi`'s Shared Tomcat (`:8080`) without port conflicts:

- **HTTP port:** `8081` (`http://localhost:8081/M-Dosthi/`)
- **Shutdown port:** `8006` (keeps `8005` free for Shared Tomcat)
- **RMI business-logic port:** `1100` (keeps `1099` free for `eDosthi-BL`)
- **Context descriptor:** `tools/tomcat9/conf/Catalina/localhost/M-Dosthi.xml` (auto-created pointing `docBase` to `apps/web`)

#### 1. Setup & Build (macOS / Linux)
```bash
cd CodeBase/M-Dosthi-Codebase
scripts/setup.sh --individual
# Review/edit services/legacy/runtime/gblinfo.inf (DB credentials) and apps/web/config.info
scripts/legacy.sh build --individual
```

#### 2. Start, Status & Stop (macOS / Linux)
```bash
# Start Individual Tomcat (:8081) + M-Dosthi RMI (:1100)
scripts/legacy.sh start --individual

# Or start Individual Tomcat directly via the Tomcat9 symlink (RMI still started via legacy.sh)
./Tomcat9/bin/startup.sh

# Check running status
scripts/legacy.sh status --individual

# Verify HTTP response
curl -I http://localhost:8081/M-Dosthi/

# Stop Individual Tomcat (:8081) + M-Dosthi RMI (:1100)
scripts/legacy.sh stop --individual
```

#### 3. Customizing Individual Tomcat Ports
To override the default HTTP (`8081`) or shutdown (`8006`) ports without editing `tools/tomcat9/conf/server.xml` manually:
```bash
TOMCAT_HTTP_PORT=8082 TOMCAT_SHUTDOWN_PORT=8007 scripts/legacy.sh start --individual
```

#### 4. Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -Mode individual
powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 build -Mode individual
powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 start -Mode individual
powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 status -Mode individual
powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 stop -Mode individual
```

### Shared Tomcat Guide (Alongside eDosthi on `:8080`)

To host M-Dosthi in an existing Shared Tomcat 9 instance as well (or instead), configure the [shared Tomcat workflow](docs/setup.md#run-m-dosthi-in-an-existing-tomcat-9). Pass `--shared` (or set `SHARED_TOMCAT_HOME`) to `scripts/setup.sh` and `scripts/legacy.sh` (or `-Mode shared` on Windows). M-Dosthi's scripts will register the `/M-Dosthi` context and manage only the M-Dosthi RMI process in shared mode; they will not start or shut down the shared Tomcat, and do not modify eDosthi application files.

## Database And Configuration Safety

- Copy `.env.example` to `.env`; `.env` is local-only and ignored by Git. `scripts/api.sh` loads it for the Spring API.
- The API and generated legacy `gblinfo.inf` template default to schema `mDosthi`. Confirm that your approved database import populates it; neither app imports clinical data automatically.
- The legacy server reads `services/legacy/runtime/gblinfo.inf`; it does not load `.env` automatically. The migration runner supports `LEGACY_DB_*` environment overrides.
- `MYSQL_ROOT_PASSWORD` and `MYSQL_DATABASE` configure the local MySQL provisioning script (`scripts/provision-api-db-user.sh`).
- SQL dumps, generated legacy config, local runtimes, build products and patient files are not intended for Git. Never commit patient data or real credentials.
- Use the smallest required MySQL permissions, strong unique credentials, and a non-production environment for development.

## Tests And Development

Run targeted checks from the relevant component directory:

| Component | Command | Notes |
|---|---|---|
| Spring API | `cd services/api && ./mvnw test` | Requires a JDK 25-capable Java installation. |
| Flutter client | `cd apps/mobile && flutter test` | Uses the Flutter SDK and project dependencies. |
| Python annotation pipeline | See [annotation package guide](services/annotate/README.md) | Follow the package's environment and test instructions. |
| Legacy Java/web | See [development guide](docs/development.md) | Some legacy artifacts are not available in a clean checkout; review the limitation above before attempting a rebuild. |

Keep generated files, build output, SQL dumps, local configuration, and credentials out of commits. Never use real patient data in an unapproved local or development environment. The [development guide](docs/development.md) describes source locations and repository conventions.

## Troubleshooting

- **API does not start:** confirm JDK 25 is selected and `JAVA_HOME` points to the JDK directory, not its `bin/java` executable.
- **Database connection or login fails:** verify the API's `.env` JDBC URL and credentials, confirm MySQL is reachable, and ensure the compatible schema has been imported.
- **Flutter reports failed to fetch:** confirm the API is listening and the configured `API_HOST` is reachable from the chosen browser/device. Emulator and physical-device addresses differ from `localhost`.
- **Legacy scripts on Windows:** use `scripts/setup.ps1` and `scripts/legacy.ps1` in PowerShell (supports `build`, `start`, `stop`, `run`, `status`, and `-Mode individual|shared`), or run `scripts/*.sh` from Git Bash or WSL.
- **Legacy build fails because classes are missing:** see [the clean-checkout limitation](docs/setup.md#legacy-clean-checkout-limitation); do not copy artifacts from patient or production systems.

For detailed diagnostics and additional cases, see [setup troubleshooting](docs/setup.md#troubleshooting).

## More Guides

- [Setup instructions](docs/setup.md): platform prerequisites, database preparation, commands, troubleshooting.
- [Architecture](docs/architecture.md): component relationships and data flow.
- [All-in-One Setup & Shared Tomcat Guide](docs/all-in-one-setup-and-shared-tomcat-guide.md): complete native setup, MySQL backup restoration, run commands, and line-by-line Shared Tomcat implementation from eDosthi to M-Dosthi.
- [Database Inspection Guide](docs/database-inspection-guide.md): general MySQL CLI and SQL reference for checking databases, schemas, tables, columns, indexes, and sizes.
- [Shared Tomcat changes](docs/shared-tomcat-changes.md): summary and setup notes for hosting M-Dosthi alongside eDosthi.
- [API guide](docs/api.md): service endpoints and contracts.
- [Development guide](docs/development.md): build and contribution workflow.
- [Database guide](database/README.md) and [migration runner](database/migration-runner/README.md).
- [Security policy](SECURITY.md).

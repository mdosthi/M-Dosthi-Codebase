# M-Dosthi

M-Dosthi is a healthcare application monorepo containing the legacy JSP/Tomcat system, a Flutter client, a Spring Boot REST API, and a Python annotation pipeline. The system has more than one application path: the legacy web application uses its Java RMI business logic, while the Flutter client calls the Spring Boot API. They have separate configuration and may use different MySQL schemas.

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
│       ├── android/, ios/, linux/   Platform runners
│       ├── macos/, windows/, web/   Platform runners
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
├── requirements.txt                 All Python runtime dependencies
├── docker-compose.yml               Optional local MySQL 8 service
├── .env.example                     Safe local configuration template
├── .gitignore, .gitattributes       Secret/generated-file and line-ending rules
├── tools/                           Downloaded local runtimes; ignored by Git
└── local-archive/                   Historical copies and backups; ignored by Git
```

## Components And Prerequisites

| Component | Runtime | Database/API | Start command |
|---|---|---|---|
| Flutter client (`apps/mobile`) | Flutter SDK; Chrome for web, or a configured platform runner | Calls `services/api` on port 9090 | `flutter run -d chrome --dart-define=API_HOST=localhost:9090` |
| REST API (`services/api`) | JDK 25; Maven wrapper included | MySQL 8; Ollama for configured AI features | `scripts/api.sh` or `scripts/api.ps1` |
| Legacy JSP site (`apps/web`) | Tomcat 9; JDK 11 or later for servlet build | Uses legacy Java business logic | `scripts/legacy.sh run` in Bash |
| Legacy RMI business logic (`services/legacy`) | JDK 11 or later; Bash | MySQL configuration in `runtime/gblinfo.inf` | Started with the legacy script |
| Annotation pipeline (`services/annotate`) | Python 3.10+; dependencies in project files | Ollama; optional database integrations | See `services/annotate/README.md` |

For the Flutter/API workflow, install both the Flutter SDK and JDK 25; they are separate prerequisites and are not installed by the Python requirements file or setup scripts. Docker can provide local MySQL on port 3306, but Compose creates only an empty `mDosthi` schema. Import an approved compatible schema/data dump before using database-backed features. The setup scripts download Tomcat when it is absent; they do not install Java, Flutter, Python, MySQL, or Ollama. On Windows, use PowerShell for setup/API commands and Git Bash or WSL for the legacy build scripts.

### Install Python dependencies

For the annotation pipeline, install `uv` first if it is not already available. From the repository root, create a virtual environment and install the dependencies listed in `requirements.txt`:

```bash
uv venv
uv pip install -r requirements.txt
```

Run these commands from the repository root because `requirements.txt` includes the local `services/annotate` package.

## Quick Start: Flutter And API

The Flutter app can run in a browser or on a supported device. Login and other server-backed features require the API and a populated compatible database. To run Flutter and the legacy JSP website together, start MySQL and use three terminals: one for the API, one for Flutter, and one for the legacy JSP/RMI services.

### One-time setup

From the repository root:

```bash
git clone <repository-url> M-Dosthi
cd M-Dosthi
scripts/setup.sh                         # Windows: powershell -File scripts/setup.ps1
```

The setup script creates `.env` from `.env.example` if it does not exist. Edit `.env` with your local database settings. Generate a JWT secret with `openssl rand -base64 32` and put the output in `SECRETKEY` (do not leave the example value `change-me`). Start MySQL (or use an existing MySQL 8 server), then import an approved compatible database dump; Compose creates an empty database and does not load application data:

```bash
docker compose up -d mysql
```

See [Setup instructions](docs/setup.md) for database import and configuration details.

### Optional English chat speech

The patient chat UI can read an English assistant response aloud after the user selects **Listen**. It uses Ollama's speech API with the separate Phonon model; Ollama remains the LLM and the displayed response is unchanged. Install the model on the Ollama host with `ollama pull phonon` (Ollama 0.40.9+). Speech is English-only and generated on demand by the configured Ollama host. The API does not cache or save the generated audio. See [speech setup and configuration](docs/setup.md#optional-english-speech-playback), including the data-handling implications of a remote Ollama host.

### Chat voice input

The chat microphone button uses the browser or device speech-recognition service to put dictated words into the message field; it does not use Ollama. Recognition support depends on the platform and browser, and the platform provider may process audio online. Review the [voice input setup and data-handling notes](docs/setup.md#chat-voice-input). Dictation only fills the draft; the patient must press Send to submit it.

### Terminal 1: start the API

From the repository root (the directory containing `scripts/` and `apps/`), install JDK 25 if needed and start the API:

```bash
brew install openjdk@25
export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
javac -version
java -version
scripts/api.sh
```

The `JAVA_HOME` value must be the JDK installation directory, not the path to the `java` executable. `scripts/api.sh` also detects JDK 25 installed through Homebrew or registered with macOS when `JAVA_HOME` is unset. Keep this terminal open; the API listens on port `9090`.

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
  --dart-define=API_HOST=localhost:9090
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

```bash
export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
scripts/legacy.sh run
```

After the legacy build artifacts are ready, on later starts use `scripts/legacy.sh start` instead of rebuilding. Keep the terminal open. Open the web URL printed by the script; this repository's local Tomcat configuration uses port `8081`, so the address is typically `http://127.0.0.1:8081/M-Dosthi/`. Check `tools/tomcat9/conf/server.xml` if the port differs. The legacy RMI service uses port `1099` and advertises `127.0.0.1` by default for local development; set `LEGACY_RMI_ADVERTISE_HOST` to a reachable address when clients connect from another machine.

The API and legacy build/runtime can use JDK 25. Set `JAVA_HOME` separately in each terminal if you run both Java services; do not try to run both from a single terminal environment. See [the legacy build notes](docs/setup.md#legacy-clean-checkout-limitation) if `scripts/legacy.sh run` fails on a clean checkout because a required artifact is missing.

## Quick Start: Legacy Web System

The legacy stack is separate from the Flutter/API path. It needs JDK 11 or later, MySQL and a compatible legacy schema. Its build uses dynamic RMI stubs and does not require `rmic`. On a clean checkout, confirm that required legacy build artifacts are available before relying on the build command; see [Legacy Build Notes](docs/setup.md#legacy-web-and-rmi).

### Fresh local database: local legacy testing

Compose creates an empty database, not the full legacy application schema. If you have no approved database backup and need to test local legacy workflows, start MySQL and run the development-only bootstrap:

```bash
docker compose up -d mysql
scripts/dev/legacy-fresh-db.sh
```

The script refuses to run unless the Compose database is named `mDosthi` and the legacy login/queue tables are absent. It creates a minimal schema from [legacy-minimal-login.sql](database/dev/legacy-minimal-login.sql), then prompts you to choose an admin user ID and password. There is no default password. For this disposable local test only, the password may match the user ID; that is weak and must not be reused elsewhere. The minimal schema supports local accounts, patient registration, screening checkpoints, and chat-control/session/message persistence; it is not the full clinical application schema. Chat remains limited to patients explicitly enrolled in the RCT (`login.rctFlag = 1`); the bootstrap does not enroll patients automatically. Before starting or restarting the legacy services, set `gbldbusername` and `gbldbpasswd` in the ignored local file `services/legacy/runtime/gblinfo.inf` to the same local Compose application account configured by `SPRING_DATASOURCE_USERNAME` and `SPRING_DATASOURCE_PASSWORD` in `.env`, then run:

```bash
scripts/legacy.sh run
```

Sign in at `http://localhost:8080/M-Dosthi/` with the user ID and password you entered. The seeded account uses the legacy `adm` role; the legacy web app has no separate “System Administrator” role. This bootstrap does not initialize the full application schema or enable the other clinical workflows. The legacy application stores passwords with MD5, so use a unique local-only password and never use this bootstrap with production data or an exposed server. For a functional system, import the complete, approved legacy schema instead.

The screening migration runner requires Java 11 or later and Maven. On macOS with Homebrew, install both (JDK 25 is also suitable for the legacy project), then add them to the current terminal's `PATH`:

```bash
brew install maven openjdk@25
export JAVA_HOME="$(brew --prefix openjdk@25)/libexec/openjdk.jdk/Contents/Home"
export PATH="$(brew --prefix maven)/bin:$JAVA_HOME/bin:$PATH"
java -version
mvn -version
```

Once Java and Maven are available, build and run the migration runner from the repository root:

```bash
mvn -f database/migration-runner/pom.xml package
java -jar database/migration-runner/target/pobado-migration-runner-1.0.0.jar
```

The runner reads the legacy database configuration, applies only pending migrations, and refuses databases other than `mDosthi`. It does not initialize a fresh legacy schema, and migrations are not applied automatically when Tomcat starts. See the [migration runner guide](database/migration-runner/README.md) before applying them to a production database.

```bash
scripts/setup.sh
# Edit services/legacy/runtime/gblinfo.inf and apps/web/config.info.
scripts/legacy.sh run
```

Open the URL printed by the script. It derives the HTTP port from `tools/tomcat9/conf/server.xml`; the default Tomcat port is 8080, but a local Tomcat configuration may use another port. The RMI service uses port 1099.

## Configuration And Data Safety

- Copy `.env.example` to `.env`; `.env` is local-only and ignored by Git. `scripts/api.sh` loads it for the Spring API.
- The API and generated legacy `gblinfo.inf` template default to schema `mDosthi`. Confirm that your approved database import populates it; neither app imports clinical data automatically.
- The legacy server reads `services/legacy/runtime/gblinfo.inf`; it does not load `.env` automatically. The migration runner supports `LEGACY_DB_*` environment overrides.
- `MYSQL_ROOT_PASSWORD` and `MYSQL_DATABASE` configure the optional Docker MySQL service. Docker creates an empty schema; it does not supply an application dump.
- SQL dumps, generated legacy config, local runtimes, build products and patient files are not intended for Git. Never commit patient data or real credentials.
- Use the smallest required MySQL permissions, strong unique credentials, and a non-production environment for development.

## More Guides

- [Setup instructions](docs/setup.md): platform prerequisites, database preparation, commands, troubleshooting.
- [Architecture](docs/architecture.md): component relationships and data flow.
- [API guide](docs/api.md): service endpoints and contracts.
- [Development guide](docs/development.md): build and contribution workflow.
- [Database guide](database/README.md) and [migration runner](database/migration-runner/README.md).
- [Security policy](SECURITY.md).

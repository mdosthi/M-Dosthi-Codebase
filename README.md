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
│       ├── pyproject.toml           Python package metadata
│       └── pyproject.toml           Python package metadata and dependency source
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
| Legacy JSP site (`apps/web`) | Tomcat 9; Java 11 toolchain for servlet build | Uses legacy Java business logic | `scripts/legacy.sh run` in Bash |
| Legacy RMI business logic (`services/legacy`) | JDK 11 including `rmic`; Bash | MySQL configuration in `runtime/gblinfo.inf` | Started with the legacy script |
| Annotation pipeline (`services/annotate`) | Python 3.10+; dependencies in project files | Ollama; optional database integrations | See `services/annotate/README.md` |

Docker is optional and can provide a local MySQL server. The setup scripts download Tomcat when it is absent; they do not install Java, Flutter, Python, MySQL, or Ollama. On Windows, use PowerShell for setup/API commands and Git Bash or WSL for the legacy build scripts.

## Quick Start: Flutter And API

The Flutter app can run in a browser or on a supported device. Login and other server-backed features require the API and a populated compatible database. To run Flutter and the legacy JSP website together, start MySQL and use three terminals: one for the API, one for Flutter, and one for the legacy JSP/RMI services.

### One-time setup

From the repository root:

```bash
git clone <repository-url> M-Dosthi
cd M-Dosthi-Codebase
scripts/setup.sh                         # Windows: powershell -File scripts/setup.ps1
```

The setup script creates `.env` from `.env.example` if it does not exist. Edit `.env` with your local database settings. Generate a JWT secret with `openssl rand -base64 32` and put the output in `SECRETKEY` (do not leave the example value `change-me`). Start MySQL (or use an existing MySQL 8 server), then import an approved compatible database dump; Compose creates an empty database and does not load application data:

```bash
docker compose up -d mysql
```

See [Setup instructions](docs/setup.md) for database import and configuration details.

### Terminal 1: start the API

From the repository root (the directory containing `scripts/` and `apps/`), select JDK 25 and start the API:

```bash
export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
export PATH="$JAVA_HOME/bin:$PATH"
javac -version
java -version
scripts/api.sh
```

The `JAVA_HOME` value must be the JDK installation directory, not a placeholder or the path to the `java` executable. The command above derives it from the `javac` currently on your `PATH`; confirm the reported version is 25 before starting the API.

Keep this terminal open. The API listens on port `9090`. If you already have JDK 25 under `~/.jdk`, you can select it with:

```bash
export JAVA_HOME="$(find "$HOME/.jdk" -maxdepth 1 -type d -name 'jdk-25*' -print -quit)"
export PATH="$JAVA_HOME/bin:$PATH"

scripts/api.sh
```

### Terminal 2: start Flutter in a browser

Open a second terminal. If it is not already at the repository root, change to the checkout root first. Then run:

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

If Flutter reports that port `3001` is already in use, first open `http://127.0.0.1:3001/`; an existing Flutter server may already be running. To start an additional server, use another port such as `3002` and open the URL with that port:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3002 \
  --dart-define=API_HOST=localhost:9090
```

For an Android emulator, set `API_HOST=10.0.2.2:9090`; for a physical phone, use the development computer's LAN IP and ensure the API is reachable. The Flutter UI may start without the API, but login and server-backed features will fail.

### Terminal 3: start the legacy JSP website

The legacy website is independent of Flutter and uses JDK 11, Tomcat, and its RMI service. Configure `services/legacy/runtime/gblinfo.inf` for the legacy database and confirm the generated build artifacts are available. From a third terminal at the repository root, run this the first time or when rebuilding:

```bash
export JAVA_HOME="$PWD/tools/jdk11"
export PATH="$JAVA_HOME/bin:$PATH"
scripts/legacy.sh run
```

After the legacy build artifacts are ready, on later starts use `scripts/legacy.sh start` instead of rebuilding. Keep the terminal open. Open the web URL printed by the script; this repository's local Tomcat configuration uses port `8081`, so the address is typically `http://127.0.0.1:8081/M-Dosthi/`. Check `tools/tomcat9/conf/server.xml` if the port differs. The legacy RMI service uses port `1099`.

The API uses JDK 25 while the legacy build/runtime uses JDK 11. Set `JAVA_HOME` separately in each terminal; do not try to run both Java services from a single terminal environment. See [the legacy build notes](docs/setup.md#legacy-clean-checkout-limitation) if `scripts/legacy.sh run` fails on a clean checkout because a required artifact is missing.

## Quick Start: Legacy Web System

The legacy stack is separate from the Flutter/API path. It needs JDK 11 with `rmic`, MySQL and a compatible legacy schema. On a clean checkout, confirm that required legacy build artifacts are available before relying on the build command; see [Legacy Build Notes](docs/setup.md#legacy-web-and-rmi).

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

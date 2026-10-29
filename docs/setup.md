# Setup Guide

This guide covers the independently runnable parts of the M-Dosthi repository. The normal Flutter workflow is `apps/mobile` plus `services/api`; the older JSP/Tomcat workflow is `apps/web` plus the RMI process in `services/legacy`. They have separate DB configuration and can target different schemas.

## Choose A Workflow

| You want to run | Required parts | Entry point |
|---|---|---|
| Flutter client in a browser/device | MySQL with the expected schema, Spring Boot API, Flutter SDK | `services/api` and `apps/mobile` |
| Legacy JSP website | MySQL with the legacy schema, Tomcat 9, legacy RMI process | `apps/web` and `services/legacy` |
| Python annotation tools | Python environment and, for model calls, Ollama | `services/annotate` |

You do not need to start both Java servers for the Flutter workflow. The JSP application is not the Flutter app's API server.

## Prerequisites

Install the tools needed for your chosen workflow. The repository setup scripts do not install Java, Flutter, Python, MySQL, or Ollama.

| Tool | Used by | Notes |
|---|---|---|
| Git | All workflows | Clone this repository. |
| JDK 25 | `services/api` | Required by `services/api/pom.xml`; set `JAVA_HOME` and `PATH` before starting Maven. |
| JDK 11 | Legacy build and runtime | Must include `javac` and `rmic`. `rmic` was removed from later JDK releases. A local `tools/jdk11` may be supplied separately; `tools/` is not part of Git. |
| MySQL 8 | API and legacy workflows | Use a local server, a remote server, or the optional Compose service. You need a compatible database dump/schema; Compose alone creates an empty database. |
| Flutter SDK | `apps/mobile` | Chrome is needed for the Chrome target; `web-server` can be used with another browser. |
| Python 3.10+ | `services/annotate` | Create an isolated environment and install the package's declared dependencies. |
| Ollama | Annotation and configured API features | Install separately, start the service, and download/configure the model names required by your workflow. |
| Docker Compose | Optional MySQL | `docker compose` is included with current Docker Desktop and many Docker Engine installations. |

On Windows, run setup and the API in PowerShell. The legacy scripts are Bash scripts; use Git Bash or WSL. Flutter can use native Windows tooling for the desired target.

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

The setup script prepares local configuration and Tomcat, then reports which prerequisite commands are on `PATH`. It does not install those prerequisites or initialize application tables. It creates `.env` from `.env.example` if needed. It also creates `services/legacy/runtime/gblinfo.inf` and `apps/web/config.info` from templates, replacing `@PROJECT_ROOT@` with this checkout's absolute path. Generated files are not overwritten on later setup runs, so preserve your local edits.

`tools/` is Git-ignored. Setup downloads Tomcat 9 there if it is missing, but a JDK 11 distribution is not automatically downloaded. Install the needed JDKs yourself and keep their paths outside version control.

## 2. Configure Java And Secrets

Copy/edit `.env` in the repository root. It is ignored by Git; keep one value per line as `NAME=value` and do not add real values to `.env.example`.

For the API, select JDK 25 before launching. Bash example:

```bash
export JAVA_HOME=/path/to/jdk-25
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

PowerShell example:

```powershell
$env:JAVA_HOME = 'C:\path\to\jdk-25'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
```

For legacy build commands, select JDK 11 instead:

```bash
export JAVA_HOME=/path/to/jdk-11
export PATH="$JAVA_HOME/bin:$PATH"
"$JAVA_HOME/bin/rmic" -version
```

The most important API values in `.env` are `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, and `SECRETKEY`. Generate a unique key, for example with `openssl rand -base64 32`; do not reuse any credentials from historical files. Ollama model settings and `IMEDIX_WHATSAPP_*` values are only needed for those integrations. Set `OLLAMA_LOG_PAYLOAD_ENABLED=false` where prompt payloads may contain patient data.

The legacy RMI server does not automatically load `.env`. Edit the generated `services/legacy/runtime/gblinfo.inf` for its JDBC URL, username, password, FTP credentials, and local paths. The legacy website has its own generated `apps/web/config.info`; provide any required external integration credentials there too. Both files are ignored by Git.

## 3. Start MySQL And Prepare Schemas

### Optional local MySQL with Docker

Set `MYSQL_ROOT_PASSWORD` and `MYSQL_DATABASE` in `.env`, then run:

```bash
docker compose up -d mysql
docker compose ps
```

`MYSQL_DATABASE` creates one empty schema on the first initialization of the Docker volume. The API and legacy config template default to `mDosthi`. Docker does not copy data from an existing local MySQL server; import an approved dump into the container before using the app. Existing MySQL Docker volumes are not reinitialized when these values change.

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

## 5. Run The Legacy JSP And RMI System

This workflow requires JDK 11, Tomcat 9, a compatible `mDosthi` schema and the legacy configuration files. Confirm `services/legacy/runtime/gblinfo.inf` contains the right local DB connection before starting.

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

- **API exits with an unsupported Java version:** select JDK 25 and verify `java -version` in the same terminal before running `scripts/api.sh`.
- **`Access denied` or connection refused from MySQL:** verify the server is running, host/port are reachable, and that the credentials in `.env` (API) or `gblinfo.inf` (legacy) match the DB user. Test the exact JDBC schema name.
- **Unknown database/table:** Compose creates an empty schema, not application tables. Import the correct approved dump before using the app; apply only the migrations intended for that schema.
- **Flutter login says failed to fetch:** confirm the API is listening on 9090, set the correct `API_HOST` for the target device, and check browser/network CORS errors.
- **Flutter web asset manifest is missing:** stop the stale Flutter process, run `flutter pub get`, then start Flutter again from `apps/mobile` and open the new URL it prints.
- **`JDK 11 with rmic required`:** the legacy script auto-detects JDK 11 under `/usr/lib/jvm` or `tools/jdk11`. Otherwise, set `JAVA_HOME` to a JDK 11 installation that includes `bin/rmic`; JDK 15 and later do not include it.
- **Tomcat or RMI port is occupied:** inspect listeners on the configured HTTP port and 1099, stop the conflicting application, and start again. Do not kill unrelated Java processes indiscriminately.
- **Legacy rebuild errors for absent classes:** see the clean-checkout limitation above; local ignored build output may have hidden the missing artifact.

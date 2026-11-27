# Spring Boot API Source

## Patient Monitoring API

Apply `../../database/migrations/V20260923_01__patient_monitoring.sql` to the active MySQL database before using the monitoring endpoints. This project does not currently configure Flyway or Liquibase, so migrations are reviewed and applied explicitly.

The authenticated API surface is under `/api/monitoring`. Doctor operations require `type=doc` and an active `lpatq.assigneddoc` relationship; patient operations require `type=pat` and the authenticated user ID to match the patient ID.

## Required API Schema

Before the first API launch, from the repository root, apply the annotation pipeline queue schema to the same database configured by `SPRING_DATASOURCE_URL`:

```bash
mysql --host=127.0.0.1 --user=DB_MIGRATION_USER --password mDosthi \
  < services/api/src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql
```

Replace the host, migration account, and database name to match the configured JDBC URL. MySQL prompts for the password. Use a schema migration account with `CREATE` privileges; the API runtime account should retain only its required data privileges. This idempotent script creates the tables used by the scheduled annotation queue and seeds the default 00:00–02:00 processing window without overwriting an existing setting.
This directory contains the source code for the M-Dosthi Spring Boot API.

## Requirements

- JDK 25, as declared in `pom.xml`.
- MySQL for database-backed features.
- Ollama for AI-backed features where configured.

## Validate and Test

From this directory:

```bash
./mvnw -DskipTests validate
./mvnw test
```

Compilation and tests require a Java 25-capable JDK.

## Run From Source

From the repository root, use the API script so it loads the local `.env` settings:

```bash
scripts/api.sh
```

The configured port is `9090`. Configure `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD` in the root `.env`. Use a dedicated non-root MySQL account and ensure the account exists and has access to the configured schema. Direct Maven or IDE launches do not load the root `.env` automatically.

## Production Server Deployment (Alongside eDosthi on `:9090`)

On servers where existing `eDosthi/API` already occupies port `9090` (`/api/`):
1. Apply both `src/main/resources/db/manual/V20261029_01__pipeline_job_queue.sql` and `src/main/resources/db/manual/V20261113_01__complete_api_schema.sql` to `mDosthi`.
2. Build the fat JAR with JDK 25 (`./mvnw -q package -DskipTests`) and run on port **`9091`** (`java -jar -Dserver.port=9091 target/saMiX-0.0.1-SNAPSHOT.jar`) with `SPRING_DATASOURCE_*`, `SECRETKEY`, and `OLLAMA_*` loaded from the root `.env`.
3. Reverse-proxy `/mdosthi-api/` → `http://127.0.0.1:9091/` in Apache2/Nginx (leaving `/api/` → `127.0.0.1:9090/api/` untouched). See [docs/server-setup-guide.md](../../docs/server-setup-guide.md).

## Optional chat speech

The Flutter chatbot can read persisted English assistant messages aloud using Ollama's speech-only `/v1/audio/speech` API and the `phonon` model (local by default). This is separate from the existing Ollama chat/generation calls; response generation, conversation context, and clinical safety handling are unchanged. The speech endpoint accepts only an assistant message ID, verifies that its session belongs to the authenticated patient, and returns uncached `audio/wav` bytes. No message text is logged or written to temporary files.

Ollama 0.40.9 or later is required. On the Ollama host, run `ollama pull phonon` and `ollama show phonon`, then configure `OLLAMA_TTS_ENABLED`, `OLLAMA_TTS_MODEL`, `OLLAMA_TTS_VOICE`, `OLLAMA_TTS_LANGUAGE`, `OLLAMA_TTS_TIMEOUT`, `OLLAMA_TTS_MAX_TEXT_LENGTH`, and `OLLAMA_TTS_MAX_CONCURRENT` in the root `.env`. Defaults and language/licensing limitations are documented in the [setup guide](../../docs/setup.md#optional-english-speech-playback).

## Source Layout

```text
src/main/java/       Controllers, services, models, and configuration
src/main/resources/  Application properties and prompt resources
src/test/java/       Spring Boot tests
pom.xml              Maven dependencies and Java version
```

Build and run from source with `scripts/api.sh`; do not commit packaged JARs.

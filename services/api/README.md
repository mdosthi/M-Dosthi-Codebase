# Spring Boot API Source

## Patient Monitoring API

Apply `../../database/migrations/V20260923_01__patient_monitoring.sql` to the active MySQL database before using the monitoring endpoints. This project does not currently configure Flyway or Liquibase, so migrations are reviewed and applied explicitly.

The authenticated API surface is under `/api/monitoring`. Doctor operations require `type=doc` and an active `lpatq.assigneddoc` relationship; patient operations require `type=pat` and the authenticated user ID to match the patient ID.
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

```bash
./mvnw spring-boot:run
```

The configured port is `9090`. Review `src/main/resources/application.properties` and provide local environment values before starting the API.

## Source Layout

```text
src/main/java/       Controllers, services, models, and configuration
src/main/resources/  Application properties and prompt resources
src/test/java/       Spring Boot tests
pom.xml              Maven dependencies and Java version
```

Build and run from source with `scripts/api.sh`; do not commit packaged JARs.

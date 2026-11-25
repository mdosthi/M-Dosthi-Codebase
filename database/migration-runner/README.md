# PO Bado Database Migrations

The versioned SQL files in `database/migrations` are the source of truth for the PO Bado schema. Admin accounts such as `aimsadmin` and `sknadmin` are rows in the configured database; migrations run once per database, not once per admin account.

This runner applies the migrations to the legacy application's configured database. By default it only accepts the `mDosthi` schema. It does not run automatically when Tomcat starts, so deployments can take a backup and schedule the schema update explicitly.

## Run

From the repository root, with Java 11 or later, Maven, and MySQL reachable:

```sh
mvn -f database/migration-runner/pom.xml package
java -jar database/migration-runner/target/pobado-migration-runner-1.0.0.jar
```

The runner reads `services/legacy/runtime/gblinfo.inf`. Database URL, username, and password can be overridden with `LEGACY_DB_URL`, `LEGACY_DB_USERNAME`, and `LEGACY_DB_PASSWORD`. The optional `POBADO_MIGRATION_DATABASE` guard defaults to `mDosthi`; both it and the schema in the JDBC URL must be `mDosthi`.

Take a database backup before running in production. Flyway records successful migrations in `flyway_schema_history`; repeated runs validate and apply only pending migrations. For existing installations, the runner checks the legacy schema before Flyway starts: an untouched schema and a screening-table-only schema are baselined at their respective preceding versions, a fully migrated schema is recognized (including the required column order), and partial migrations are refused for manual review rather than guessed at.

The SQL scripts are deliberately schema-neutral, so the same migration set works for every admin account in `mDosthi`. This runner does not modify `mDosthi_review` or any other database.
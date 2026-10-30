# Development

## Where code lives

- JSP/static assets: `apps/web`
- Servlet sources: `services/legacy/servlet-src`; RMI logic: `services/legacy/server-src`
- Spring Boot API: `services/api` (`./mvnw test`)
- Flutter app: `apps/mobile` (`flutter test`)
- Python pipeline: `services/annotate`
- Migrations: `database/migrations`

## Legacy build

`scripts/legacy.sh build` compiles both legacy modules and copies jars into `services/legacy/runtime/lib` and `apps/web/WEB-INF/lib`. The web build also packages the RMI logger interface, `json-simple`, and `commons-codec`, which are required by login, access-control, and dashboard code. Both makeJar scripts compile with `JAVA_HOME` (JDK 11) and `services/legacy/external-lib`.

## Git conventions

- Never commit `.env`, `gblinfo.inf`, `config.info`, SQL dumps, or build output (see `.gitignore`).
- Jars built by `scripts/legacy.sh build` are git-ignored; third-party libraries and `ftp.jar` (no sources) are tracked.
- Line endings are normalized by `.gitattributes`.

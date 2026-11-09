# Development

## Where code lives

- JSP/static assets: `apps/web`
- Servlet sources: `services/legacy/servlet-src`; RMI logic: `services/legacy/server-src`
- Spring Boot API: `services/api` (`./mvnw test`)
- Flutter app: `apps/mobile` (`flutter test`)
- Python pipeline: `services/annotate`
- Migrations: `database/migrations`

## Running an updated codebase (Docker)

Containers run built images, so rebuild after pulling changes:

```sh
git pull
docker compose up -d --build                 # rebuild and restart everything
docker compose up -d --build api             # or only one service: api, flutter-web, legacy-web, legacy-rmi
docker compose ps
docker compose logs -f api
```

If `database/migrations` has new files, back up the database and apply them with the runner described in `database/migration-runner/README.md`:

```sh
mvn -f database/migration-runner/pom.xml package
java -jar database/migration-runner/target/pobado-migration-runner-1.0.0.jar
```

Add `--remove-orphans` to `docker compose up` to clean up containers for services removed from the compose file. Default ports: Flutter web 8081, API 9090, legacy web 8080, MySQL 3306 (all bound to 127.0.0.1).

## Legacy build

`scripts/legacy.sh build` compiles both legacy modules and copies jars into `services/legacy/runtime/lib` and `apps/web/WEB-INF/lib`. The web build also packages the RMI logger interface, `json-simple`, and `commons-codec`, which are required by login, access-control, and dashboard code. Both makeJar scripts compile with `JAVA_HOME` (JDK 11) and `services/legacy/external-lib`.

## Git conventions

- Never commit `.env`, `gblinfo.inf`, `config.info`, SQL dumps, or build output (see `.gitignore`).
- Jars built by `scripts/legacy.sh build` are git-ignored; third-party libraries and `ftp.jar` (no sources) are tracked.
- Line endings are normalized by `.gitattributes`.

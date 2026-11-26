# Development

## Where code lives

- JSP/static assets: `apps/web`
- Servlet sources: `services/legacy/servlet-src`; RMI logic: `services/legacy/server-src`
- Spring Boot API: `services/api` (`./mvnw test`)
- Flutter app: `apps/mobile` (`flutter test`)
- Python pipeline: `services/annotate`
- Migrations: `database/migrations`

## Running an updated codebase

Pull changes and restart the local services:

```sh
git pull
scripts/api.sh                               # start/restart the Spring Boot API
scripts/legacy.sh run                        # rebuild and restart the legacy web/RMI stack
```

If `database/migrations` has new files, back up the database and apply them with the runner described in `database/migration-runner/README.md`:

```sh
mvn -f database/migration-runner/pom.xml package
java -jar database/migration-runner/target/pobado-migration-runner-1.0.0.jar
```

Default ports: Flutter web 3001, API 9090, M-Dosthi Individual Tomcat 8081, Shared Tomcat 8080, M-Dosthi RMI 1100, MySQL 3306.

## Legacy build

`scripts/legacy.sh build` (or `scripts/legacy.ps1 build` on Windows) compiles both legacy modules and copies jars into `services/legacy/runtime/lib` and `apps/web/WEB-INF/lib`. The web build also packages the RMI logger interface, `json-simple`, and `commons-codec`, which are required by login, access-control, and dashboard code. Both makeJar scripts compile with `JAVA_HOME` (JDK 11+) and `services/legacy/external-lib`. By default (`--individual`), the servlet build uses M-Dosthi's bundled `tools/tomcat9/lib/servlet-api.jar`; when `--shared` or `SHARED_TOMCAT_HOME` is set, it uses that shared Tomcat's `lib/servlet-api.jar`.

When `--shared` or `SHARED_TOMCAT_HOME` is set, `scripts/setup.sh` / `scripts/setup.ps1` registers the M-Dosthi `/mDosthi` context in both M-Dosthi's Individual Tomcat and the selected Shared Tomcat, while `scripts/legacy.sh` / `scripts/legacy.ps1` in shared mode only manages M-Dosthi's RMI process (`stop` does not shut down the shared Tomcat). In `--individual` mode (the default), `scripts/legacy.sh` / `scripts/legacy.ps1` manages both M-Dosthi's Individual Tomcat (`:8081`) and M-Dosthi's RMI process (`:1100`). See the [shared Tomcat setup](setup.md#run-m-dosthi-in-an-existing-tomcat-9) for RMI port and configuration requirements.

## Git conventions

- Never commit `.env`, `gblinfo.inf`, `config.info`, SQL dumps, or build output (see `.gitignore`).
- Jars built by `scripts/legacy.sh build` are git-ignored; third-party libraries and `ftp.jar` (no sources) are tracked.
- Line endings are normalized by `.gitattributes`.

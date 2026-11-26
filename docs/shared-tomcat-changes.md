# Shared Tomcat Changes: Beginner's Guide

This document explains the M-Dosthi code changes made so its older JSP website can run in the same Tomcat 9 server as eDosthi. It describes what changed, why it changed, and how the parts fit together.

**The eDosthi application source was not edited.** M-Dosthi setup does add a `mDosthi.xml` deployment descriptor to whichever Tomcat directory you select. To avoid changing any files inside the eDosthi repository, point `SHARED_TOMCAT_HOME` at a separate Tomcat installation outside that repository. Both applications can still use that Tomcat server.

## The Basic Idea

Tomcat can serve more than one web application at the same time. Each application has a *context path* (the first path part after the host and port):

```text
http://localhost:8080/eDosthi/       eDosthi website
http://localhost:8080/mDosthi/      M-Dosthi website
```

They share Tomcat's HTTP port (`8080` in this example), but keep distinct URL paths and application files. A Tomcat `Context` descriptor connects a context path to the folder containing the web application. In this change, the descriptor tells Tomcat that `/mDosthi` is served from M-Dosthi's `apps/web` folder.

M-Dosthi also has a Java RMI business-logic server. That is a separate Java process; it is **not** Tomcat. Both eDosthi and M-Dosthi can have their own RMI processes, but they cannot both listen on the same host and port. Shared setup therefore uses port `1100` for M-Dosthi by default, while standalone setup keeps the old `1099` default.

The newer Spring Boot API is another separate process and is not deployed inside Tomcat 9 by this workflow.

## Exact M-Dosthi Code Changes

### Setup scripts: `SHARED_TOMCAT_HOME`

- [`scripts/setup.sh`](../scripts/setup.sh) supports Linux/macOS shells and Git Bash/WSL. If `SHARED_TOMCAT_HOME` is set, the script checks that it points to a Tomcat installation with `bin/catalina.sh` and `lib/servlet-api.jar`. It writes `conf/Catalina/localhost/mDosthi.xml` into that Tomcat and points the descriptor at this checkout's `apps/web`. It does not download M-Dosthi's bundled Tomcat in shared mode. Without the variable, the existing standalone setup path remains in use.
- [`scripts/setup.ps1`](../scripts/setup.ps1) does the corresponding work for PowerShell on Windows, checking for `bin/catalina.bat` and the Servlet API JAR.
- Both setup scripts fill `@PROJECT_ROOT@` in local configuration templates and replace `@LEGACY_RMI_PORT@` with the selected RMI port. They create generated configuration only when it does not already exist. **They do not overwrite existing local config files**, so a previous setup's URL or port must be checked manually.

`SHARED_TOMCAT_HOME` means the *Tomcat installation folder*, not its `webapps` folder. For example:

```text
/opt/tomcat9/                 <- SHARED_TOMCAT_HOME
├── bin/
├── conf/
├── lib/
└── webapps/
```

The setup script writes the descriptor under `conf/Catalina/localhost/`. If Tomcat is installed inside the eDosthi repository, that descriptor would be a change inside that repository; use a Tomcat installation outside it if that is not acceptable.

### M-Dosthi start/stop behavior

- [`scripts/legacy.sh`](../scripts/legacy.sh) reads `SHARED_TOMCAT_HOME` too, so it knows which Tomcat's Servlet API is used for building.
- In shared mode, `scripts/legacy.sh start` starts the M-Dosthi RMI Java process but does **not** start Tomcat. `scripts/legacy.sh stop` stops the M-Dosthi RMI process but does **not** shut down Tomcat.
- In standalone mode, the script retains the behavior of starting/stopping the bundled Tomcat alongside the RMI process.
- The script records the RMI process ID in `services/legacy/runtime/iMediXBusinessLogic.pid` and checks that PID before stopping it. This is intended to avoid killing eDosthi's RMI process or another unrelated Java process. The PID file is local runtime state and is ignored by Git.
- Before starting, the script checks that M-Dosthi's `blport` matches in its website and RMI configuration. If the values differ, it stops with an error instead of starting a mismatched setup.

Because shared mode is selected through an environment variable, keep `SHARED_TOMCAT_HOME` set in the shell every time you run `scripts/legacy.sh`, including when you stop M-Dosthi:

```bash
export SHARED_TOMCAT_HOME=/opt/tomcat9
scripts/legacy.sh stop
```

If you omit the variable, the script assumes standalone mode and may try to stop the bundled Tomcat instead. After changing or rebuilding M-Dosthi web files, restart the shared Tomcat using the normal method for that Tomcat installation; the M-Dosthi script intentionally does not do that.

### Servlet API and RMI Stub packaging during the build

[`services/legacy/servlet-src/WEB-INF/classes/src/makeJar.sh`](../services/legacy/servlet-src/WEB-INF/classes/src/makeJar.sh) chooses `servlet-api.jar` from `SHARED_TOMCAT_HOME` when the variable is set, and packages both `*Interface.class` and `*_Stub.class` files from `services/legacy/server-src` into `apps/web/WEB-INF/lib/*.jar` so RMI lookups (such as `iMediXLogger`) succeed during login. In standalone mode, the script uses the Servlet API from M-Dosthi's bundled Tomcat. You can explicitly set `SERVLET_API_JAR` to override the selected location.

### Web application configuration

- [`apps/web/config.info.template`](../apps/web/config.info.template) now defaults `gblhome` to a local M-Dosthi URL and `gbltelemedix` to `/mDosthi`. These values are used for links/cookie paths and should reflect the context under which M-Dosthi is hosted.
- [`services/legacy/runtime/gblinfo.inf.template`](../services/legacy/runtime/gblinfo.inf.template) and the web config template both use the same `@LEGACY_RMI_PORT@` placeholder. This lets setup generate matching RMI ports in the two applications' local config files.
- The RMI port can be selected before setup. For example, `LEGACY_RMI_PORT=1123` selects port `1123`; choose an available port that differs from eDosthi's if both RMI services run on the same host.

The generated files are local configuration and are not committed:

```text
apps/web/config.info
services/legacy/runtime/gblinfo.inf
```

The templates are tracked; generated files are ignored. If these generated files already exist, setup leaves them alone. After changing the port, make sure the web config line `03) blport` and RMI config line `blport` have exactly the same number.

### Finding `config.info` when deployed outside `webapps`

[`services/legacy/servlet-src/WEB-INF/classes/src/projinfo.java`](../services/legacy/servlet-src/WEB-INF/classes/src/projinfo.java) loads the web application's `config.info`. Before this change, when no explicit web path was passed, it looked under Tomcat's `webapps/mDosthi`. A shared context may point directly to M-Dosthi's source folder instead of a copy inside `webapps`, so that old location may not exist. The updated lookup still tries Tomcat's traditional location first, then looks relative to the deployed class/JAR location in the web application. This lets the same config be found in either layout.

### Other changed files

- [`.gitignore`](../.gitignore) ignores the RMI PID file so process state is not accidentally added to a commit.
- [`README.md`](../README.md) links to this guide and mentions the shared-Tomcat option.
- [`docs/setup.md`](setup.md) documents setup commands, shared-mode lifecycle behavior, configuration, ports, and troubleshooting.
- [`docs/development.md`](development.md) explains the Servlet API selection and shared lifecycle behavior for developers.
- [`docs/architecture.md`](architecture.md) notes that the JSP site can share Tomcat while RMI uses separate ports.
- [`docs/api.md`](api.md) describes the configurable RMI port.
- **This file, `docs/shared-tomcat-changes.md`, is new.** It is the beginner-oriented, file-by-file explanation of the implementation and setup. It does not change application behavior.

## How to Set It Up

### Linux/macOS, Git Bash, or WSL

Run these commands from the M-Dosthi repository root:

```bash
export SHARED_TOMCAT_HOME=/absolute/path/to/tomcat9
export LEGACY_RMI_PORT=1100
scripts/setup.sh
```

For example, set `SHARED_TOMCAT_HOME=/opt/tomcat9` only if `/opt/tomcat9` contains `bin/`, `conf/`, and `lib/`. Pick an RMI port that is not already in use. The example uses `1100`, the shared-mode default.

### Windows PowerShell

```powershell
$env:SHARED_TOMCAT_HOME = 'C:\tools\tomcat9'
$env:LEGACY_RMI_PORT = '1100'
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
```

The legacy build/start scripts are Bash scripts; run them from Git Bash or WSL on Windows.

### Review configuration and build

Before starting services, review the generated files:

1. In `apps/web/config.info`, set `gblhome` to the URL users will open. For local testing this might be `http://localhost:8080/mDosthi`; for a real deployment use the correct hostname, scheme, and port. Keep `gbltelemedix` as `/mDosthi`.
2. Set matching RMI port values in `apps/web/config.info` and `services/legacy/runtime/gblinfo.inf`. Shared setup defaults them to `1100`; use another unused port if needed.
3. Configure M-Dosthi's database URL, account, password, temp/log directories, and any integrations for its environment. Do not assume it should use eDosthi's database or credentials.
4. Select JDK 11 or later with `javac`, then build:

```bash
export SHARED_TOMCAT_HOME=/absolute/path/to/tomcat9
export JAVA_HOME=/path/to/jdk-11
scripts/legacy.sh build
```

The build produces servlet/business-logic classes and JARs in the M-Dosthi checkout. It does not start Tomcat.

### Start in the correct order

1. Start or restart the shared Tomcat using its normal service or startup command. This lets Tomcat load the `/mDosthi` descriptor and the built web application. It will also serve the already-deployed eDosthi context.
2. In a shell with `SHARED_TOMCAT_HOME` and `JAVA_HOME` set, start M-Dosthi's RMI process:

```bash
export SHARED_TOMCAT_HOME=/absolute/path/to/tomcat9
export JAVA_HOME=/path/to/jdk-11
scripts/legacy.sh start
```

3. Open `gblhome` from `apps/web/config.info`, commonly `http://localhost:8080/mDosthi/` for local testing.
4. When stopping M-Dosthi, keep `SHARED_TOMCAT_HOME` set and run `scripts/legacy.sh stop`. This stops M-Dosthi's RMI process only. Stop/restart the shared Tomcat separately when you intentionally want to affect both web applications.

## Words You May Need to Explain

| Term | Beginner explanation |
|---|---|
| Tomcat | The Java web server that runs JSP pages and servlets. One Tomcat can host multiple web applications. |
| Context path | The URL path assigned to an application, such as `/eDosthi` or `/mDosthi`. It lets Tomcat route each URL to the right app. |
| Context descriptor | The `mDosthi.xml` file telling Tomcat which folder to use for the `/mDosthi` app. |
| `docBase` | The folder containing the web application files. Here it points to M-Dosthi's `apps/web`. |
| Servlet API JAR | Tomcat's Java interfaces that servlet code compiles against. Tomcat provides the implementation when it runs the app. |
| RMI | A Java mechanism for one Java process to call services in another process. M-Dosthi's website uses the RMI business-logic service. |
| Port | A numbered network endpoint. Tomcat uses an HTTP port (usually `8080`); the RMI service uses a separate port (default `1100` for this shared setup). Two processes on the same host cannot listen on the same port. |
| `SHARED_TOMCAT_HOME` | An environment variable containing the path to the Tomcat installation that will host both applications. |

## Validation Performed

- Bash syntax checks and `git diff --check`.
- Compiled the updated Java web configuration class.
- Ran setup in an isolated test directory and verified it wrote the `/mDosthi` descriptor to the selected shared Tomcat without creating M-Dosthi's bundled Tomcat.
- Verified that shared and custom RMI port choices are generated consistently in both templates.
- Verified that configuration lookup works with both classes-directory and packaged-JAR layouts.
- Verified shared-mode `stop` does not invoke Tomcat shutdown.
- Deployed and verified live against Shared Tomcat 9 (`:8080`), eDosthi RMI (`:1099`), M-Dosthi RMI (`:1100`), MySQL (`:3306`), Spring Boot API (`:9090`), and Flutter Web (`:3001`).

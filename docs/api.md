# API Map

## Legacy Java RMI Services

The Java business layer exposes remote services including user information, centre information, database operations, patient queues, data entry, display data, and administrative jobs. Their source interfaces are under:

```text
backend/legacy-java/server_module_source_code
```

The process is launched from:

```text
services/legacy/runtime/RunServer.sh
```

It binds the RMI registry on port `1099`.

## JSP and Servlet Endpoints

The web application is deployed under:

```text
apps/web
```

JSP pages and servlet routes are defined by the deployed application and its `WEB-INF` configuration. Do not rename route folders as part of documentation-only cleanup.

## Spring Boot API

The Spring Boot source is under:

```text
services/api/src/main/java
```

Controllers cover user-related operations, WhatsApp/webhook integration, survey scoring, and related services. The configured application port is `9090` in the source configuration, but endpoint availability depends on the selected runtime configuration and database/services.

Before publishing a complete endpoint catalog, inspect the controller mappings from the exact source copy being deployed. The workspace contains more than one API/runtime copy.

### Authenticated chatbot speech

`POST /api/user/speech` accepts JSON containing only a persisted assistant `message_id`. The caller must be the patient who owns that message's session, and the session must be English. Successful responses are uncached `audio/wav`; invalid, unavailable, oversized, or unsupported-language requests return a JSON error. The endpoint sends only the final stored response text to the configured Ollama Phonon model, not conversation history or patient/session identifiers.

```json
{"message_id":"msg_<assistant-message-uuid>"}
```

Speech generation is explicit and on demand; the complete audio is returned after synthesis rather than streamed. See the [speech setup](setup.md#optional-english-speech-playback) for model installation, configuration, language limits, and data handling.

## Python CLI API

The annotation package exposes:

- `annotate-single`
- `annotate-batch`
- `annotate-generate`

Python imports include `run_pipeline`, `run_session`, and `run_patient_sessions`. See `services/annotate/README.md` for the supported inputs and outputs.

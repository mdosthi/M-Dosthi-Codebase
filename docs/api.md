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

### Patient screening history

`POST /api/user/get-screening-history` returns persisted PO Bado, Distress Thermometer, PHQ-9, and GAD-7 records for a patient. A JWT-authenticated doctor or psychologist may call it; doctors are restricted to assigned patients. The request accepts `patientId`, with optional `offset` (default `0`) and `limit` (default `50`, maximum `100`). Records are ordered newest first.

The response contains saved scores, answers, assessment checkpoints, and recorded interpretations where present, plus `followUpDate` from the latest PO Bado record. It also contains `screeningSchedule`, with a separate timeline for each instrument. Each timeline uses that instrument's earliest saved baseline date to calculate the next 4-, 8-, or 12-week checkpoint. The PO Bado saved follow-up date is used when present; otherwise the due date is calculated from the baseline. If the baseline is absent, no due date is invented. A past due date is displayed as overdue without changing the saved screening record's completed status.

```json
{"patientId":"<patient-id>","offset":0,"limit":50}
```

## Python CLI API

The annotation package exposes:

- `annotate-single`
- `annotate-batch`
- `annotate-generate`

Python imports include `run_pipeline`, `run_session`, and `run_patient_sessions`. See `services/annotate/README.md` for the supported inputs and outputs.

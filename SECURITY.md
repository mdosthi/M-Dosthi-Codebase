# Security Notes

M-Dosthi handles healthcare-related data. Treat database dumps, patient records, logs, credentials, and generated runtime data as sensitive.

## Do Not Commit

- Passwords or database credentials.
- FTP credentials, API keys, access tokens, or verification tokens.
- Private keys and keystores.
- Patient data, uploaded files, or runtime logs.
- Local `.env` files.

Use `.env.example` for placeholder names only.

## Current Configuration Boundaries

- Spring Boot source and runtime configuration use environment-variable placeholders.
- The legacy Java runtime still has fallback values in `M-Dosthi-BL/gblinfo.inf` for compatibility. Rotate those credentials and provide the environment overrides documented in `backend/legacy-java/runtime/README.md` before publishing the repository.
- SQL snapshots under `database/snapshots` may contain sensitive data and must be reviewed before sharing.

## If a Secret Is Exposed

1. Rotate the credential immediately with the relevant database, FTP, mail, WhatsApp, or service provider.
2. Remove it from active configuration and use an environment variable.
3. Review logs and backups for additional copies.
4. Tell the repository owner what was exposed and when.

Do not report credentials or patient data in an issue. This workspace does not yet have a root Git remote or a configured private security contact; establish those before publishing publicly.

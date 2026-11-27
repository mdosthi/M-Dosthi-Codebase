# Database Files

This directory contains database snapshots used for manual review and controlled MySQL imports.

## Snapshots

- `snapshots/imedixdb5.sql`: iMediX database snapshot.
- `snapshots/M-Dosthi_merged.sql`: M-Dosthi merged database snapshot.

These files are not imported automatically by the application. Before importing one, confirm the intended environment, database name, backup date, and whether an existing database must be backed up first.

Example review command:

```bash
mysql --user=YOUR_USER --database=YOUR_DATABASE -p < database/snapshots/imedixdb5.sql
```

Do not place database passwords in shell history, documentation, or committed configuration. SQL snapshots may contain patient or other sensitive data and should be handled according to the project's data-protection requirements.

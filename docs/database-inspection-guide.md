# MySQL Database, Schema & Table Inspection Guide

A general-purpose reference for inspecting databases, schemas, tables, columns, indexes, constraints, triggers, views, routines, and data in MySQL across **macOS, Linux, and Windows**.

> [!TIP]
> Do **not** wrap usernames or database names in `<` or `>` (in `zsh`/`bash`, `<` is interpreted as file input redirection). Use plain words like `mysql -u root -p`.

---

## 1. Connect to MySQL

### Interactive Shell
```bash
# Localhost default port (3306) — prompts for password
mysql -u root -p

# Specify host and port explicitly
mysql -h 127.0.0.1 -P 3306 -u root -p

# Connect directly to a specific database (replace your_db with the database name)
mysql -u root -p your_db
```

### Run a Single Query from the Terminal without Entering the Shell
```bash
mysql -u root -p -e "SHOW DATABASES;"
mysql -u root -p your_db -e "SHOW TABLES;"
```

---

## 2. Inspect Databases (Schemas)

```sql
-- List all databases
SHOW DATABASES;

-- Filter databases by pattern
SHOW DATABASES LIKE '%pattern%';

-- Check which database is currently selected
SELECT DATABASE();

-- Switch to a database
USE your_db;

-- Show CREATE DATABASE statement (charset and collation)
SHOW CREATE DATABASE your_db;

-- View character set and collation for all databases
SELECT
    schema_name AS database_name,
    default_character_set_name AS charset,
    default_collation_name AS collation
FROM information_schema.schemata;

-- View size (in MB) and table count for every database
SELECT
    table_schema AS database_name,
    COUNT(*) AS total_tables,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS total_size_mb
FROM information_schema.tables
GROUP BY table_schema
ORDER BY total_size_mb DESC;
```

---

## 3. Inspect Tables

```sql
-- List all tables in the current database
SHOW TABLES;

-- List tables in another database without switching
SHOW TABLES FROM your_db;

-- Filter tables by name pattern
SHOW TABLES LIKE '%pattern%';

-- Show table type (BASE TABLE vs VIEW)
SHOW FULL TABLES;

-- Show table metadata (engine, row count, data size, collation, creation time)
SHOW TABLE STATUS FROM your_db;

-- List largest tables in a database by size and row count
SELECT
    table_name,
    engine,
    table_rows AS approx_rows,
    ROUND(data_length / 1024 / 1024, 2) AS data_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'your_db'
ORDER BY (data_length + index_length) DESC;
```

---

## 4. Inspect Table Schema, Columns & Data Types

```sql
-- View columns, types, nullability, keys, defaults, and extra attributes
DESCRIBE your_table;
-- or
SHOW COLUMNS FROM your_table;

-- Include column comments, privileges, and collation
SHOW FULL COLUMNS FROM your_table;

-- Show the exact CREATE TABLE DDL statement
SHOW CREATE TABLE your_table\G

-- Search for a column name across all tables in a database
SELECT
    table_name,
    column_name,
    column_type,
    is_nullable,
    column_key,
    column_default
FROM information_schema.columns
WHERE table_schema = 'your_db'
  AND column_name LIKE '%your_column%'
ORDER BY table_name, ordinal_position;
```

---

## 5. Inspect Indexes, Primary Keys & Foreign Keys

```sql
-- Show all indexes on a table
SHOW INDEX FROM your_table;

-- List all primary and unique keys in a database
SELECT
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'your_db'
ORDER BY table_name;

-- List all foreign key relationships in a database
SELECT
    table_name,
    column_name,
    constraint_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'your_db'
  AND referenced_table_name IS NOT NULL
ORDER BY table_name, column_name;
```

---

## 6. Inspect Views, Triggers, Stored Procedures & Events

```sql
-- List all views in a database
SHOW FULL TABLES IN your_db WHERE Table_type = 'VIEW';

-- Show the definition of a view
SHOW CREATE VIEW your_view\G

-- List all triggers in the current database
SHOW TRIGGERS\G

-- Show the definition of a specific trigger
SHOW CREATE TRIGGER your_trigger\G

-- List stored procedures and functions in a database
SHOW PROCEDURE STATUS WHERE Db = 'your_db';
SHOW FUNCTION STATUS WHERE Db = 'your_db';

-- Show the definition of a stored procedure or function
SHOW CREATE PROCEDURE your_procedure\G
SHOW CREATE FUNCTION your_function\G

-- List scheduled events
SHOW EVENTS FROM your_db;
```

---

## 7. Compare Two Databases (Schema Diff Queries)

```sql
-- Find tables present in db_a but missing in db_b
SELECT a.table_name
FROM information_schema.tables a
LEFT JOIN information_schema.tables b
  ON b.table_schema = 'db_b' AND b.table_name = a.table_name
WHERE a.table_schema = 'db_a'
  AND b.table_name IS NULL
ORDER BY a.table_name;

-- Find columns present in db_a but missing in db_b
SELECT a.table_name, a.column_name, a.column_type
FROM information_schema.columns a
LEFT JOIN information_schema.columns b
  ON b.table_schema = 'db_b'
 AND b.table_name = a.table_name
 AND b.column_name = a.column_name
WHERE a.table_schema = 'db_a'
  AND b.column_name IS NULL
ORDER BY a.table_name, a.ordinal_position;
```

---

## 8. Inspect Table Data & Row Counts

```sql
-- Exact row count of a table
SELECT COUNT(*) FROM your_table;

-- Preview first 10 rows
SELECT * FROM your_table LIMIT 10;

-- Display wide rows vertically (one column per line)
SELECT * FROM your_table LIMIT 5\G

-- Count rows grouped by a column
SELECT your_column, COUNT(*) AS total
FROM your_table
GROUP BY your_column
ORDER BY total DESC;
```

---

## 9. Check Users, Grants & Active Connections

```sql
-- Show current logged-in user
SELECT USER(), CURRENT_USER();

-- List all MySQL users and hosts
SELECT user, host, plugin, account_locked FROM mysql.user;

-- Show privileges for a specific user
SHOW GRANTS FOR 'root'@'localhost';

-- View currently active queries / connections
SHOW FULL PROCESSLIST;

-- Check server version, uptime, and port
SHOW VARIABLES LIKE 'version%';
SHOW VARIABLES LIKE 'port';
SHOW STATUS LIKE 'Uptime';
```

---

## 10. Export & Import Databases (`mysqldump` / `mysql`)

```bash
# Export an entire database (schema + data + routines + triggers)
mysqldump -u root -p --routines --triggers --single-transaction your_db > backup.sql

# Export schema structure only (no data)
mysqldump -u root -p --no-data --routines --triggers your_db > schema_only.sql

# Export data only (no CREATE TABLE statements)
mysqldump -u root -p --no-create-info your_db > data_only.sql

# Export a single table
mysqldump -u root -p your_db your_table > table_backup.sql

# Import a SQL dump into a database
mysql -u root -p your_db < backup.sql
```

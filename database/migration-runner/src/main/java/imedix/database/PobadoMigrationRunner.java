package imedix.database;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public final class PobadoMigrationRunner {
    private static final String TARGET_DATABASE = "mDosthi";
    private static final String SCREENING_BASELINE = "20260923.01";
    private static final String SCREENING_ONLY_BASELINE = "20260923.02";
    private static final String CURRENT_BASELINE = "20260928.03";

    private PobadoMigrationRunner() {
    }

    public static void main(String[] args) throws Exception {
        File configFile = args.length == 0
                ? new File("services/legacy/runtime/gblinfo.inf")
                : new File(args[0]);
        Map<String, String> config = readConfig(configFile);

        String url = envOrConfig("LEGACY_DB_URL", config, "gbldburl");
        String username = envOrConfig("LEGACY_DB_USERNAME", config, "gbldbusername");
        String password = envOrConfig("LEGACY_DB_PASSWORD", config, "gbldbpasswd");
        String driver = config.getOrDefault("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver");
        String migrationDatabase = System.getenv().getOrDefault("POBADO_MIGRATION_DATABASE", TARGET_DATABASE);

        requireTargetDatabase(migrationDatabase, url);
        Class.forName(driver);

        MigrationVersion baseline = inspectBaseline(url, username, password);
        File migrations = new File("database/migrations");
        if (!migrations.isDirectory()) {
            throw new IllegalStateException("Migration directory not found: " + migrations.getAbsolutePath());
        }

        Flyway.configure()
                .dataSource(url, username, password)
                .locations("filesystem:" + migrations.getAbsolutePath())
                .baselineOnMigrate(true)
                .baselineVersion(baseline)
                .validateOnMigrate(true)
                .load()
                .migrate();

        System.out.println("PO Bado migrations are current for database " + TARGET_DATABASE + ".");
    }

    private static Map<String, String> readConfig(File file) throws Exception {
        if (!file.isFile()) {
            throw new IllegalArgumentException("Database config file not found: " + file.getAbsolutePath());
        }
        Map<String, String> values = new HashMap<>();
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) continue;
                int separator = trimmed.indexOf('=');
                if (separator <= 0) continue;
                values.put(trimmed.substring(0, separator).trim().toLowerCase(Locale.ROOT),
                        trimmed.substring(separator + 1).trim());
            }
        }
        return values;
    }

    private static String envOrConfig(String environmentName, Map<String, String> config, String key) {
        String value = System.getenv(environmentName);
        if (value == null || value.trim().isEmpty()) value = config.get(key);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Missing database setting: " + environmentName + " or " + key);
        }
        return value.trim();
    }

    private static void requireTargetDatabase(String configuredDatabase, String url) throws Exception {
        if (!TARGET_DATABASE.equalsIgnoreCase(configuredDatabase)) {
            throw new IllegalArgumentException("Refusing migration target '" + configuredDatabase
                    + "'. This runner is restricted to " + TARGET_DATABASE + ".");
        }
        String databasePath = URI.create(url.substring("jdbc:".length())).getPath();
        String actualDatabase = databasePath == null ? "" : databasePath.replaceFirst("^/", "");
        if (!TARGET_DATABASE.equalsIgnoreCase(actualDatabase)) {
            throw new IllegalArgumentException("Refusing JDBC URL database '" + actualDatabase
                    + "'. Expected " + TARGET_DATABASE + ".");
        }
    }

    private static MigrationVersion inspectBaseline(String url, String username, String password) throws Exception {
        try (Connection connection = DriverManager.getConnection(url, username, password)) {
            if (!tableExists(connection, "med")) {
                throw new IllegalStateException("Target database does not contain the legacy med table.");
            }
            boolean screeningTable = tableExists(connection, "pobado_screening");
            boolean pobadoFlag = columnExists(connection, "med", "pobado_flag");
            boolean rctReady = columnExists(connection, "med", "rct_ready");
            boolean psyReferred = columnExists(connection, "med", "psy_referred");
            boolean psyReferredDate = columnExists(connection, "med", "psy_referred_date");
            boolean trigger = triggerExists(connection, "trg_med_pobado_defaults");
            boolean anyFlags = pobadoFlag || rctReady || psyReferred || psyReferredDate || trigger;
            boolean allFlags = pobadoFlag && rctReady && psyReferred && psyReferredDate;

            if (screeningTable && allFlags && trigger) {
                return MigrationVersion.fromVersion(columnsBeforeSerno(connection)
                        ? CURRENT_BASELINE
                        : "20260928.02");
            }
            if (screeningTable && !anyFlags) return MigrationVersion.fromVersion(SCREENING_ONLY_BASELINE);
            if (!screeningTable && !anyFlags) return MigrationVersion.fromVersion(SCREENING_BASELINE);

            throw new IllegalStateException("PO Bado schema is partially migrated. No migration was run. "
                    + "Inspect database/migrations and repair this schema before retrying.");
        }
    }

    private static boolean tableExists(Connection connection, String table) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name=?")) {
            statement.setString(1, table);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() && result.getInt(1) > 0;
            }
        }
    }

    private static boolean columnExists(Connection connection, String table, String column) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=? AND column_name=?")) {
            statement.setString(1, table);
            statement.setString(2, column);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() && result.getInt(1) > 0;
            }
        }
    }

    private static boolean triggerExists(Connection connection, String trigger) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name=?")) {
            statement.setString(1, trigger);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() && result.getInt(1) > 0;
            }
        }
    }

    private static boolean columnsBeforeSerno(Connection connection) throws Exception {
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT column_name, ordinal_position FROM information_schema.columns "
                        + "WHERE table_schema=DATABASE() AND table_name='med' "
                        + "AND column_name IN ('pobado_flag','rct_ready','psy_referred','psy_referred_date','serno')")) {
            Map<String, Integer> positions = new HashMap<>();
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) positions.put(result.getString(1), result.getInt(2));
            }
            Integer serno = positions.get("serno");
            Integer referralDate = positions.get("psy_referred_date");
            return serno != null
                    && referralDate != null
                    && positions.getOrDefault("pobado_flag", Integer.MAX_VALUE) < serno
                    && positions.getOrDefault("rct_ready", Integer.MAX_VALUE) < serno
                    && positions.getOrDefault("psy_referred", Integer.MAX_VALUE) < serno
                    && referralDate < serno;
        }
    }
}
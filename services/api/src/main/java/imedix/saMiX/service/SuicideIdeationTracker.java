package imedix.saMiX.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class SuicideIdeationTracker {

    private static final Logger logger = LoggerFactory.getLogger(SuicideIdeationTracker.class);
    private static final String REQUIRED_TABLES_QUERY =
            "SELECT table_name FROM information_schema.tables " +
                    "WHERE table_schema = DATABASE() " +
                    "AND table_name IN ('signal_history', 'session_history', 'login')";
    private static final Set<String> REQUIRED_TABLES =
            Set.of("signal_history", "session_history", "login");

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private WhatsAppService whatsAppService;

    @Value("${imedix.whatsapp.alert.recipient:91XXXXXXXXXX}")
    private String alertRecipient;

    private volatile boolean signalTablesAvailable;

    @PostConstruct
    public void init() {
        Set<String> existingTables = jdbcTemplate.queryForList(REQUIRED_TABLES_QUERY).stream()
                .map(row -> row.get("table_name"))
                .filter(String.class::isInstance)
                .map(String.class::cast)
                .collect(Collectors.toSet());
        Set<String> missingTables = REQUIRED_TABLES.stream()
                .filter(table -> !existingTables.contains(table))
                .collect(Collectors.toSet());

        if (!missingTables.isEmpty()) {
            logger.warn(
                    "Suicide ideation tracking is disabled because required database tables are missing: {}. "
                            + "Import the correct schema and restart the API to enable tracking.",
                    String.join(", ", missingTables));
            return;
        }

        signalTablesAvailable = true;

        try {
            // Check and add is_processed column to signal_history
            try {
                jdbcTemplate.execute("ALTER TABLE signal_history ADD COLUMN is_processed INT DEFAULT 0");
                System.out.println("DEBUG: Column is_processed added/verified on signal_history table.");
            } catch (Exception e) {
                // Column might already exist or table is empty
            }

            // Check and add created_at column to signal_history
            try {
                jdbcTemplate.execute(
                        "ALTER TABLE signal_history ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
                System.out.println("DEBUG: Column created_at added/verified on signal_history table.");
            } catch (Exception e) {
                // Column might already exist
            }
        } catch (Exception e) {
            logger.error("Failed to initialize database migrations for SuicideIdeationTracker.", e);
        }
    }

    @Scheduled(fixedDelayString = "${suicide.tracker.delay:10000}")
    public void pollSuicidalSignals() {
        if (!signalTablesAvailable) {
            return;
        }

        try {
            // Retrieve dynamic alert recipient from DB, fallback to injected field
            String dynamicRecipient = whatsAppService.getConfig("imedix.whatsapp.alert.recipient", alertRecipient);

            // Query unprocessed signal_history records
            // We left join session_history to get patient details
            String query = "SELECT sh.signal_id, sh.suicidal_ideation, sh.created_at, " +
                    "s.pat_id, l.name AS pat_name " +
                    "FROM signal_history sh " +
                    "LEFT JOIN session_history s ON sh.signal_id = s.signal_id " +
                    "LEFT JOIN login l ON s.pat_id = l.uid " +
                    "WHERE sh.is_processed = 0 OR sh.is_processed IS NULL";

            List<Map<String, Object>> records = jdbcTemplate.queryForList(query);
            if (records.isEmpty()) {
                return;
            }

            for (Map<String, Object> row : records) {
                String signalId = (String) row.get("signal_id");
                Object ideationObj = row.get("suicidal_ideation");

                int ideation = 0;
                if (ideationObj instanceof Number) {
                    ideation = ((Number) ideationObj).intValue();
                } else if (ideationObj instanceof Boolean) {
                    ideation = ((Boolean) ideationObj) ? 1 : 0;
                } else if (ideationObj != null) {
                    try {
                        ideation = Integer.parseInt(ideationObj.toString());
                    } catch (Exception ex) {
                        // ignore
                    }
                }

                // If ideation is 1, process sending
                if (ideation == 1) {
                    String patId = (String) row.get("pat_id");
                    String patName = (String) row.get("pat_name");
                    java.sql.Timestamp createdAt = (java.sql.Timestamp) row.get("created_at");

                    // Check race condition: if patient details are not found in session_history
                    // yet,
                    // check how old the record is. If less than 30 seconds, wait for the next run.
                    if (patId == null) {
                        long ageMs = 0;
                        if (createdAt != null) {
                            ageMs = System.currentTimeMillis() - createdAt.getTime();
                        }
                        if (ageMs < 30000) {
                            System.out.println(
                                    "DEBUG: Suicide alert race condition protection: pat_id is null for signal_id: "
                                            + signalId + " and record age is " + ageMs + "ms. Retrying next cycle.");
                            continue; // skip this row for now, don't mark as processed
                        }
                    }

                    // Format patient info
                    String patientInfo;
                    if (patId != null) {
                        patientInfo = "Patient: " + patName + " (ID: " + patId + ")";
                    } else {
                        patientInfo = "Patient details unavailable (Signal ID: " + signalId + ")";
                    }

                    System.out.println("ALERT: Suicidal ideation detected! Processing alert for: " + patientInfo);

                    // Send alert via WhatsAppService to each recipient (split by comma)
                    if (dynamicRecipient != null && !dynamicRecipient.trim().isEmpty()) {
                        String[] recipients = dynamicRecipient.split(",");
                        for (String recipient : recipients) {
                            recipient = recipient.trim();
                            if (recipient.isEmpty()) {
                                continue;
                            }
                            String sendResult = whatsAppService.sendSuicideIdeationAlert(recipient,
                                    "*SUICIDAL FLAG*", patientInfo);
                            System.out.println("DEBUG: Alert send result to " + recipient + ": " + sendResult);

                            // Log the alert to whatsapp_logs for admin panel visibility
                            String status = "FAILED";
                            String msgId = null;
                            if (sendResult.startsWith("SUCCESS")) {
                                status = "SENT";
                                if (sendResult.contains(":")) {
                                    msgId = sendResult.substring(sendResult.indexOf(":") + 1);
                                }
                            }

                            whatsAppService.logMessage(
                                    patId != null ? patId : "SYSTEM",
                                    recipient,
                                    "Suicidal Ideation alert sent to counselor. Details: " + patientInfo,
                                    status,
                                    msgId,
                                    "flag_red",
                                    "suicide_alert");
                        }
                    } else {
                        System.err.println("WARNING: No alert recipients configured for suicidal ideation alerts.");
                    }
                }

                // Mark the signal as processed so we don't process it again
                jdbcTemplate.update("UPDATE signal_history SET is_processed = 1 WHERE signal_id = ?", signalId);
                System.out.println("DEBUG: Marked signal_id " + signalId + " as processed (is_processed=1).");
            }
        } catch (Exception e) {
            logger.error("Exception in pollSuicidalSignals background task.", e);
        }
    }
}
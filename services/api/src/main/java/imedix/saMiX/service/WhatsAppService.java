/* Author: Sayantan Patra */

package imedix.saMiX.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import imedix.saMiX.model.WhatsAppLog;

import jakarta.annotation.PostConstruct;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Service
public class WhatsAppService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${imedix.whatsapp.alert.recipient:91XXXXXXXXXX}")
    private String defaultAlertRecipient;
    // whatsapp creds
    @Value("${imedix.whatsapp.access-token}")
    private String ACCESS_TOKEN;

    @Value("${imedix.whatsapp.phone-number-id}")
    private String PHONE_NUMBER_ID;

    @PostConstruct
    public void init() {
        try {
            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS whatsapp_logs (" +
                    "id INT PRIMARY KEY AUTO_INCREMENT, " +
                    "uid VARCHAR(50), " +
                    "phone VARCHAR(20), " +
                    "message TEXT, " +
                    "status VARCHAR(50), " +
                    "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "msg_id VARCHAR(100) DEFAULT NULL, " +
                    "msg_type VARCHAR(50) DEFAULT NULL, " +
                    "broadcast_type VARCHAR(50) DEFAULT 'manual') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci");

            try {
                jdbcTemplate.execute(
                        "ALTER TABLE whatsapp_logs CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci");
                System.out.println("DEBUG: Converted whatsapp_logs table to utf8mb4.");
            } catch (Exception e) {
                // Ignore
            }

            try {
                jdbcTemplate.execute("ALTER TABLE whatsapp_logs ADD COLUMN msg_id VARCHAR(100) DEFAULT NULL");
                System.out.println("DEBUG: Column msg_id added to whatsapp_logs.");
            } catch (Exception e) {
                // Column might already exist
            }

            try {
                jdbcTemplate.execute("ALTER TABLE whatsapp_logs ADD COLUMN msg_type VARCHAR(50) DEFAULT NULL");
                System.out.println("DEBUG: Column msg_type added to whatsapp_logs.");
            } catch (Exception e) {
                // Column might already exist
            }

            try {
                jdbcTemplate
                        .execute("ALTER TABLE whatsapp_logs ADD COLUMN broadcast_type VARCHAR(50) DEFAULT 'manual'");
                System.out.println("DEBUG: Column broadcast_type added to whatsapp_logs.");
            } catch (Exception e) {
                // Column might already exist
            }

            // Align column collation of whatsapp_logs.uid to prevent "Illegal mix of
            // collations" during JOIN queries
            try {
                String getCollationSql = "SELECT COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS " +
                        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'login' AND COLUMN_NAME = 'uid'";
                List<String> collations = jdbcTemplate.query(getCollationSql,
                        (rs, rowNum) -> rs.getString("COLLATION_NAME"));
                if (!collations.isEmpty()) {
                    String collation = collations.get(0);
                    if (collation != null && !collation.trim().isEmpty()) {
                        String alterCollationSql = "ALTER TABLE whatsapp_logs MODIFY COLUMN uid VARCHAR(50) CHARACTER SET utf8mb4 COLLATE "
                                + collation;
                        jdbcTemplate.execute(alterCollationSql);
                        System.out.println("DEBUG: Aligned whatsapp_logs.uid collation to " + collation);
                    }
                }
            } catch (Exception e) {
                System.err.println("WARNING: Could not align whatsapp_logs.uid collation: " + e.getMessage());
            }

            try {
                jdbcTemplate.execute("ALTER TABLE login ADD COLUMN wa_sent INT DEFAULT 0");
                System.out.println("DEBUG: Column wa_sent added/verified on login table.");
            } catch (Exception e) {
                // Column might already exist
            }

            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS whatsapp_rotations (" +
                        "msg_type VARCHAR(50) PRIMARY KEY, " +
                        "last_reset TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
                System.out.println("DEBUG: whatsapp_rotations table initialized.");
            } catch (Exception e) {
                System.err.println("ERROR: Failed to create whatsapp_rotations: " + e.getMessage());
            }

            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS whatsapp_config (" +
                        "cfg_key VARCHAR(100) PRIMARY KEY, " +
                        "cfg_value VARCHAR(255) NOT NULL)");
                System.out.println("DEBUG: whatsapp_config table initialized.");

                try {
                    jdbcTemplate.execute("ALTER TABLE whatsapp_config MODIFY COLUMN cfg_value VARCHAR(1024) NOT NULL");
                    System.out.println("DEBUG: Altered whatsapp_config.cfg_value to VARCHAR(1024).");
                } catch (Exception e) {
                    System.err.println("WARNING: Could not modify cfg_value to VARCHAR(1024): " + e.getMessage());
                }

                String checkSql = "SELECT COUNT(*) FROM whatsapp_config WHERE cfg_key = 'imedix.whatsapp.alert.recipient'";
                Integer count = jdbcTemplate.queryForObject(checkSql, Integer.class);
                if (count == null || count == 0) {
                    jdbcTemplate.update(
                            "INSERT INTO whatsapp_config (cfg_key, cfg_value) VALUES ('imedix.whatsapp.alert.recipient', ?)",
                            defaultAlertRecipient != null ? defaultAlertRecipient : "91XXXXXXXXXX");
                    System.out.println(
                            "DEBUG: Inserted default alert recipient into whatsapp_config: " + defaultAlertRecipient);
                }
            } catch (Exception e) {
                System.err.println("ERROR: Failed to initialize whatsapp_config: " + e.getMessage());
            }

            System.out.println("DEBUG: whatsapp_logs table initialized successfully.");
        } catch (Exception e) {
            System.err.println("ERROR: Failed to initialize whatsapp_logs table: " + e.getMessage());
        }
    }

    public String getConfig(String key, String defaultValue) {
        try {
            String sql = "SELECT cfg_value FROM whatsapp_config WHERE cfg_key = ?";
            List<String> results = jdbcTemplate.query(sql, (rs, rowNum) -> rs.getString("cfg_value"), key);
            if (!results.isEmpty()) {
                return results.get(0);
            }
        } catch (Exception e) {
            System.err.println("ERROR: Failed to read from whatsapp_config: " + e.getMessage());
        }
        return defaultValue;
    }

    public void setConfig(String key, String value) {
        try {
            String sql = "INSERT INTO whatsapp_config (cfg_key, cfg_value) VALUES (?, ?) " +
                    "ON DUPLICATE KEY UPDATE cfg_value = ?";
            jdbcTemplate.update(sql, key, value, value);
            System.out.println("DEBUG: Config updated: " + key + " = " + value);
        } catch (Exception e) {
            System.err.println("ERROR: Failed to update whatsapp_config: " + e.getMessage());
        }
    }

    public void resetWaSentFlag() {
        try {
            jdbcTemplate.update("UPDATE login SET wa_sent = 0 WHERE type = 'PAT'");
            System.out.println("DEBUG: Reset wa_sent flags for all PAT users.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void updateWaSentFlag(String uid, int status) {
        try {
            jdbcTemplate.update("UPDATE login SET wa_sent = ? WHERE uid = ?", status, uid);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public java.sql.Timestamp getOrCreateRotationReset(String msgType) {
        String selectSql = "SELECT last_reset FROM whatsapp_rotations WHERE msg_type = ?";
        try {
            List<java.sql.Timestamp> list = jdbcTemplate.query(selectSql, (rs, rowNum) -> rs.getTimestamp("last_reset"),
                    msgType);
            if (!list.isEmpty()) {
                return list.get(0);
            }
            java.sql.Timestamp initial = new java.sql.Timestamp(86400000L); // 1970-01-02 to avoid epoch boundaries
            String insertSql = "INSERT INTO whatsapp_rotations (msg_type, last_reset) VALUES (?, ?)";
            jdbcTemplate.update(insertSql, msgType, initial);
            return initial;
        } catch (Exception e) {
            e.printStackTrace();
            return new java.sql.Timestamp(86400000L);
        }
    }

    public void resetRotation(String msgType) {
        String sql = "INSERT INTO whatsapp_rotations (msg_type, last_reset) VALUES (?, DATE_ADD(NOW(), INTERVAL 1 SECOND)) "
                +
                "ON DUPLICATE KEY UPDATE last_reset = DATE_ADD(NOW(), INTERVAL 1 SECOND)";
        try {
            jdbcTemplate.update(sql, msgType);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public String sendNotification(String toPhone, String patientName, String testName, String status) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            String escapedName = escapeJson(patientName);

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"template\","
                    + "\"template\": {"
                    + "  \"name\": \"rem\","
                    + "  \"language\": {"
                    + "    \"code\": \"en\""
                    + "  },"
                    + "  \"components\": ["
                    + "    {"
                    + "      \"type\": \"body\","
                    + "      \"parameters\": ["
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"" + escapedName + "\","
                    + "          \"parameter_name\": \"text_1\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"use the app regularly and\","
                    + "          \"parameter_name\": \"text_2\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"Consistent usage\","
                    + "          \"parameter_name\": \"text_3\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"from the application\","
                    + "          \"parameter_name\": \"text_4\""
                    + "        }"
                    + "      ]"
                    + "    }"
                    + "  ]"
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp notification to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    public String sendBengaliNotification(String toPhone, String patientName) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            String escapedName = escapeJson(patientName);

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"template\","
                    + "\"template\": {"
                    + "  \"name\": \"rem_ben\","
                    + "  \"language\": {"
                    + "    \"code\": \"bn_IN\""
                    + "  },"
                    + "  \"components\": ["
                    + "    {"
                    + "      \"type\": \"body\","
                    + "      \"parameters\": ["
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"" + escapedName + "\","
                    + "          \"parameter_name\": \"text_1\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"text\": \"M-DOSTHI এপ্লিকেশন টি\","
                    + "          \"parameter_name\": \"text_2\""
                    + "        }"
                    + "      ]"
                    + "    }"
                    + "  ]"
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp Bengali notification to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    public String sendMessage(String toPhone, String text) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            String escapedMessage = escapeJson(text);

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"text\","
                    + "\"text\": {"
                    + "  \"body\": \"" + escapedMessage + "\""
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp text to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    public void logMessage(String uid, String phone, String message, String status, String msgId, String msgType,
                           String broadcastType) {
        String sql = "INSERT INTO whatsapp_logs (uid, phone, message, status, msg_id, msg_type, broadcast_type) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try {
            jdbcTemplate.update(sql, uid, phone, message, status, msgId, msgType, broadcastType);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void logMessage(String uid, String phone, String message, String status, String msgId, String msgType) {
        logMessage(uid, phone, message, status, msgId, msgType, "manual");
    }

    public void logMessage(String uid, String phone, String message, String status, String msgId) {
        logMessage(uid, phone, message, status, msgId, null, "manual");
    }

    public void logMessage(String uid, String phone, String message, String status) {
        logMessage(uid, phone, message, status, null, null, "manual");
    }

    public List<WhatsAppLog> getLogsByUid(String uid) {
        String sql = "SELECT * FROM whatsapp_logs WHERE uid = ? ORDER BY sent_at DESC";
        try {
            return jdbcTemplate.query(sql, (rs, rowNum) -> {
                WhatsAppLog log = new WhatsAppLog();
                log.setId(rs.getInt("id"));
                log.setUid(rs.getString("uid"));
                log.setPhone(rs.getString("phone"));
                log.setMessage(rs.getString("message"));
                log.setStatus(rs.getString("status"));
                log.setSentAt(rs.getTimestamp("sent_at"));
                log.setMsgId(rs.getString("msg_id"));
                return log;
            }, uid);
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    public void updateMessageStatus(String msgId, String status) {
        String mappedStatus = status != null ? status.toUpperCase() : "UNKNOWN";
        String sql = "UPDATE whatsapp_logs SET status = ? WHERE msg_id = ?";
        try {
            jdbcTemplate.update(sql, mappedStatus, msgId);
            System.out.println("DEBUG: Updated status to " + mappedStatus + " for msg_id " + msgId);
        } catch (Exception e) {
            System.err.println("ERROR: Failed to update message status: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private String extractJsonValue(String json, String key) {
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"");
        java.util.regex.Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    public String sendOtp(String toPhone, String message) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            // Extract 6-digit OTP
            String otp = null;
            java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\b\\d{6}\\b");
            java.util.regex.Matcher matcher = pattern.matcher(message);
            if (matcher.find()) {
                otp = matcher.group(0);
            } else {
                pattern = java.util.regex.Pattern.compile("\\d{6}");
                matcher = pattern.matcher(message);
                if (matcher.find()) {
                    otp = matcher.group(0);
                }
            }

            if (otp == null) {
                System.err.println(
                        "WARNING: Could not extract 6-digit OTP from message. Falling back to plain text sendMessage.");
                return sendMessage(toPhone, message);
            }

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"template\","
                    + "\"template\": {"
                    + "  \"name\": \"delivery_update\","
                    + "  \"language\": {"
                    + "    \"code\": \"en\""
                    + "  },"
                    + "  \"components\": ["
                    + "    {"
                    + "      \"type\": \"body\","
                    + "      \"parameters\": ["
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_0\","
                    + "          \"text\": \"OTP\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_1\","
                    + "          \"text\": \"M-DOSTHI registration\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"test_3\","
                    + "          \"text\": \"" + otp + "\""
                    + "        }"
                    + "      ]"
                    + "    }"
                    + "  ]"
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp OTP template to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    public void logIncomingMessage(String phone, String message) {
        String findUserSql = "SELECT uid FROM login WHERE phone LIKE ? OR ? LIKE CONCAT('%', phone, '%') LIMIT 1";
        String uid = null;
        try {
            String cleanPhone = phone.replaceAll("[^0-9]", "");
            List<String> uids = jdbcTemplate.query(findUserSql, (rs, rowNum) -> rs.getString("uid"),
                    "%" + cleanPhone + "%", cleanPhone);
            if (!uids.isEmpty()) {
                uid = uids.get(0);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        String insertSql = "INSERT INTO whatsapp_logs (uid, phone, message, status) VALUES (?, ?, ?, 'RECEIVED')";
        try {
            jdbcTemplate.update(insertSql, uid, phone, message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public String sendSuicideIdeationAlert(String toPhone, String text0, String text1) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"template\","
                    + "\"template\": {"
                    + "  \"name\": \"flag_red\","
                    + "  \"language\": {"
                    + "    \"code\": \"en\""
                    + "  },"
                    + "  \"components\": ["
                    + "    {"
                    + "      \"type\": \"body\","
                    + "      \"parameters\": ["
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_0\","
                    + "          \"text\": \"" + escapeJson(text1) + "\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_1\","
                    + "          \"text\": \"" + escapeJson(text0) + "\""
                    + "        }"
                    + "      ]"
                    + "    }"
                    + "  ]"
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp flag_red template to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    public String sendDeliveryUpdateAlert(String toPhone, String text0, String text1, String text3) {
        try {
            String cleanPhone = toPhone.replaceAll("[^0-9]", "");
            if (cleanPhone.isEmpty()) {
                return "ERROR: Invalid phone number";
            }

            String jsonPayload = "{"
                    + "\"messaging_product\": \"whatsapp\","
                    + "\"recipient_type\": \"individual\","
                    + "\"to\": \"" + cleanPhone + "\","
                    + "\"type\": \"template\","
                    + "\"template\": {"
                    + "  \"name\": \"delivery_update\","
                    + "  \"language\": {"
                    + "    \"code\": \"en\""
                    + "  },"
                    + "  \"components\": ["
                    + "    {"
                    + "      \"type\": \"body\","
                    + "      \"parameters\": ["
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_0\","
                    + "          \"text\": \"" + escapeJson(text0) + "\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"text_1\","
                    + "          \"text\": \"" + escapeJson(text1) + "\""
                    + "        },"
                    + "        {"
                    + "          \"type\": \"text\","
                    + "          \"parameter_name\": \"test_3\","
                    + "          \"text\": \"" + escapeJson(text3) + "\""
                    + "        }"
                    + "      ]"
                    + "    }"
                    + "  ]"
                    + "}"
                    + "}";

            System.out.println("DEBUG: Sending Meta WhatsApp delivery_update template to " + cleanPhone);

            URL url = new URL("https://graph.facebook.com/v25.0/" + PHONE_NUMBER_ID + "/messages");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setRequestProperty("Authorization", "Bearer " + ACCESS_TOKEN);
            conn.setRequestProperty("Content-Type", "application/json");

            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonPayload.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                String responseBody = "";
                try (java.io.InputStream is = conn.getInputStream();
                     java.util.Scanner s = new java.util.Scanner(is).useDelimiter("\\A")) {
                    responseBody = s.hasNext() ? s.next() : "";
                }
                System.out.println("DEBUG: Meta API Response: " + responseBody);
                String msgId = extractJsonValue(responseBody, "id");
                if (msgId != null) {
                    return "SUCCESS:" + msgId;
                }
                return "SUCCESS";
            } else {
                java.io.InputStream errorStream = conn.getErrorStream();
                String errorMsg = "";
                if (errorStream != null) {
                    try (java.util.Scanner s = new java.util.Scanner(errorStream).useDelimiter("\\A")) {
                        errorMsg = s.hasNext() ? s.next() : "";
                    }
                }
                System.err.println("Meta API Error (" + responseCode + "): " + errorMsg);
                return "FAILED (API Status " + responseCode + ")";
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    private String escapeJson(String val) {
        if (val == null)
            return "";
        return val.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
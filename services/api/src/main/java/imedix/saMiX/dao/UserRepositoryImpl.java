package imedix.saMiX.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.DigestUtils;
import imedix.saMiX.model.*;
import imedix.saMiX.model.Record;

import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import java.util.*;
import java.text.SimpleDateFormat;
import java.text.*;

@Repository
public class UserRepositoryImpl implements UserRepository {
    @Autowired
    private final JdbcTemplate jdbcTemplate;
    // Guards genRecordId()+insert so two near-simultaneous record_log submissions
    // can't read the same count(*) and generate the same rid -> Duplicate entry on
    // record_log.PRIMARY
    private final Object recordLogIdLock = new Object();

    public UserRepositoryImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /*
     * @Override
     * public String encodePassword(String password) {
     * // String sql = "select AES_ENCRYPT(?,UNHEX(SHA2(?,512)))";
     * // return jdbcTemplate.queryForObject(sql, new Object[]{password,
     * password},String.class);
     * //String sql = "select AES_ENCRYPT(?,UNHEX(SHA2(?,512)))";
     * //return jdbcTemplate.queryForObject(sql, new Object[]{password,
     * password},String.class);
     * 
     * //String sql = "select SHA1(?)";
     * String sql = "select MD5(?)";
     * return jdbcTemplate.queryForObject(sql, new Object[]{password},
     * String.class);
     * }
     */
    @Override
    public String encodePassword(String password) {
        if (password == null) {
            return null;
        }
        return DigestUtils.md5DigestAsHex(password.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public List<Map<String, Object>> findUsersByIdentifier(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return List.of();
        }
        String id = identifier.trim();
        String sql = "SELECT l.name, l.uid, l.pwd, l.center, l.type, l.rg_no, l.address, l.phone, l.emailid, " +
                "l.qualification, l.designation, l.verifemail, l.verifphone, l.active, l.consent, l.dpdp_agreed " +
                "FROM login l " +
                "LEFT JOIN med m ON m.pat_id = l.uid " +
                "WHERE LOWER(l.uid) = LOWER(?) " +
                "   OR (l.emailid IS NOT NULL AND l.emailid <> '' AND LOWER(l.emailid) = LOWER(?)) " +
                "   OR (l.phone IS NOT NULL AND l.phone <> '' AND l.phone = ?) " +
                "   OR (l.rg_no IS NOT NULL AND l.rg_no <> '' AND LOWER(l.rg_no) = LOWER(?)) " +
                "   OR (UPPER(l.type) = 'PAT' AND m.opdno IS NOT NULL AND m.opdno <> '' AND LOWER(m.opdno) = LOWER(?)) "
                +
                "ORDER BY " +
                "   CASE WHEN LOWER(l.uid) = LOWER(?) THEN 0 ELSE 1 END, " +
                "   CASE WHEN UPPER(COALESCE(l.active, 'Y')) = 'Y' THEN 0 ELSE 1 END, " +
                "   CASE WHEN UPPER(COALESCE(l.center, '')) <> 'XXXX' THEN 0 ELSE 1 END, " +
                "   l.crtdate DESC";

        List<Map<String, Object>> rawRows = jdbcTemplate.queryForList(
                sql, id, id, id, id, id, id);
        if (rawRows.isEmpty()) {
            return List.of();
        }
        Map<String, Map<String, Object>> deduped = new LinkedHashMap<>();
        for (Map<String, Object> row : rawRows) {
            String uid = Objects.toString(row.get("uid"), "");
            if (!uid.isEmpty() && !deduped.containsKey(uid)) {
                deduped.put(uid, row);
            }
        }
        return new ArrayList<>(deduped.values());
    }

    @Override
    public Map<String, Object> getUserInfo(String username) {
        List<Map<String, Object>> matches = findUsersByIdentifier(username);
        if (matches.isEmpty()) {
            throw new EmptyResultDataAccessException(1);
        }
        return matches.get(0);
    }

    @Override
    public boolean ensurePatientLoginFromMed(String patId, String submittedPassword) {
        if (patId == null || patId.isBlank() || submittedPassword == null || submittedPassword.isBlank()) {
            return false;
        }
        String trimmedId = patId.trim();
        String trimmedPwd = submittedPassword.trim();
        if (!trimmedId.equalsIgnoreCase(trimmedPwd)) {
            return false;
        }
        try {
            List<Map<String, Object>> medRows = jdbcTemplate.queryForList(
                    "SELECT pat_id, pat_name, m_name, l_name, phone, emailid FROM med WHERE LOWER(pat_id) = LOWER(?) LIMIT 1",
                    trimmedId);
            if (medRows.isEmpty()) {
                return false;
            }
            Map<String, Object> med = medRows.get(0);
            String canonicalPatId = Objects.toString(med.get("pat_id"), "").trim();
            if (canonicalPatId.isEmpty()) {
                return false;
            }
            Integer existingLogin = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM login WHERE LOWER(uid) = LOWER(?)",
                    Integer.class, canonicalPatId);
            if (existingLogin != null && existingLogin > 0) {
                return true;
            }

            String first = Objects.toString(med.get("pat_name"), "").trim();
            String middle = Objects.toString(med.get("m_name"), "").trim();
            String last = Objects.toString(med.get("l_name"), "").trim();
            StringBuilder fullName = new StringBuilder(first);
            if (!middle.isEmpty())
                fullName.append(" ").append(middle);
            if (!last.isEmpty())
                fullName.append(" ").append(last);

            String center = canonicalPatId.length() > 10
                    ? canonicalPatId.substring(0, canonicalPatId.length() - 10)
                    : "VBCR019";
            String rgNo = generateNextPatRgNo(center);
            String phone = Objects.toString(med.get("phone"), "").trim();
            String encodedPwd = encodePassword(canonicalPatId);

            int inserted = jdbcTemplate.update(
                    "INSERT INTO login (uid, pwd, name, crtdate, type, phone, rg_no, center, active, available, referral, verified, verifemail, verifphone, consent, rctFlag, dpdp_agreed) "
                            +
                            "VALUES (?, ?, ?, NOW(), 'PAT', ?, ?, ?, 'Y', 'Y', 'Y', 'A', 'N', 'N', 'N', 0, 0)",
                    canonicalPatId,
                    encodedPwd,
                    fullName.toString().trim().isEmpty() ? canonicalPatId : fullName.toString().trim(),
                    phone.isEmpty() ? null : phone,
                    rgNo,
                    center);
            return inserted > 0;
        } catch (Exception e) {
            System.out.println("ensurePatientLoginFromMed failed: " + e.getMessage());
            return false;
        }
    }

    private String generateNextPatRgNo(String center) {
        String prefix = "PAT" + center;
        try {
            List<String> existing = jdbcTemplate.queryForList(
                    "SELECT rg_no FROM login WHERE UPPER(type) = 'PAT' AND center = ? ORDER BY rg_no DESC LIMIT 1",
                    String.class, center);
            if (!existing.isEmpty() && existing.get(0) != null && existing.get(0).length() >= 4) {
                String latest = existing.get(0);
                int next = Integer.parseInt(latest.substring(latest.length() - 4)) + 1;
                return prefix + String.format("%04d", next);
            }
        } catch (Exception ignored) {
        }
        return prefix + String.format("%04d", (int) (System.currentTimeMillis() % 10000));
    }

    @Override
    public Map<String, Object> getUserDetailsByIdentifier(String identifier) {
        try {
            String sql = "SELECT name,pwd, loginid, userid, age, sex, ccode, user_type, " +
                    "address, mobile, email, qualification, designation, " +
                    "verifemail, verifphone, active " +
                    "FROM users WHERE loginid = ? OR email = ? OR mobile = ?";

            return jdbcTemplate.queryForMap(sql,
                    new Object[] { identifier, identifier, identifier });
        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (Exception e) {
            System.out.println("Error in getUserDetailsByIdentifier: " + e.getMessage());
            throw e;
        }
    }

    // user agreement
    @Override
    public boolean updateDpdpAgreed(String uid) {
        try {
            String sql = "UPDATE login SET dpdp_agreed = 1 WHERE uid = ?";
            int rows = jdbcTemplate.update(sql, uid);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("Error updating dpdp_agreed: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean withdrawDpdpConsent(String uid) {
        try {
            String sql = "UPDATE login SET dpdp_agreed = 0 WHERE uid = ?";
            int rows = jdbcTemplate.update(sql, uid);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("Error withdrawing dpdp consent: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean updateUserDetails(Map<String, String> userDetails) {
        try {

            String sql = "UPDATE login SET " +
                    "name = ?, " +
                    // "age = ?, " +
                    // "sex = ?, " +
                    "address = ?, " +
                    "phone = ?, " +
                    "emailid = ?, " +
                    "qualification = ?, " +
                    "designation = ? " +
                    "WHERE uid = ?";

            int result = jdbcTemplate.update(sql,
                    userDetails.get("name"),
                    // userDetails.get("age"),
                    // userDetails.get("sex"),
                    userDetails.get("address"),
                    userDetails.get("mobile"),
                    userDetails.get("email"),
                    userDetails.get("qualification"),
                    userDetails.get("designation"),
                    userDetails.get("userid"));

            return result > 0;
        } catch (Exception e) {
            System.out.println("Error in updateUserDetails: " + e.getMessage());
            return false;
        }
    }

    @Override
    public boolean changePassword(String loginId, String currentPassword, String newPassword) {
        try {
            System.out.println("Attempting password change for user: " + loginId);

            // First verify the user exists and get current password
            String sql = "SELECT pwd FROM users WHERE loginid = ?";
            String storedPassword = jdbcTemplate.queryForObject(sql, String.class, loginId);

            if (storedPassword == null) {
                System.out.println("User not found");
                return false;
            }

            // Encode and verify current password
            String encodedCurrentPassword = encodePassword(currentPassword);
            System.out.println("Encoded current password: " + encodedCurrentPassword);
            System.out.println("Stored password: " + storedPassword);

            if (!storedPassword.equals(encodedCurrentPassword)) {
                System.out.println("Current password verification failed");
                return false;
            }

            // Encode new password
            String encodedNewPassword = encodePassword(newPassword);

            // Update password in both users and login tables
            jdbcTemplate.update("UPDATE users SET pwd = ? WHERE loginid = ?",
                    encodedNewPassword, loginId);
            jdbcTemplate.update("UPDATE login SET password = ? WHERE loginid = ?",
                    encodedNewPassword, loginId);

            return true;
        } catch (Exception e) {
            System.out.println("Error in changePassword: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean updatePassword(String loginId, String newPassword) {
        try {
            // String sql = "UPDATE users SET pwd = ? WHERE loginid = ?";
            String sql = "UPDATE login SET pwd = ? WHERE uid = ?";
            int rowsAffected = jdbcTemplate.update(sql, newPassword, loginId);

            return rowsAffected > 0;
        } catch (Exception e) {
            System.out.println("Error updating password: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public List<Map<String, Object>> getAllForms() {
        try {
            String sql = "SELECT name, sid, creation_date, description, template_source, details_source " +
                    "FROM survey_project " +
                    "ORDER BY creation_date DESC";

            return jdbcTemplate.query(sql, (resultSet, rowNum) -> {
                Map<String, Object> form = new HashMap<>();
                form.put("name", resultSet.getString("name"));
                form.put("sid", resultSet.getString("sid"));
                form.put("creation_date", resultSet.getString("creation_date"));
                form.put("description", resultSet.getString("description"));
                form.put("template_source", resultSet.getString("template_source"));
                form.put("details_source", resultSet.getString("details_source"));
                return form;
            });
        } catch (Exception e) {
            System.out.println("Error in getAllForms: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    @Override
    public List<Map<String, Object>> getPrescribedFormsForPatient(String patId) {
        try {
            // First verify if patient exists in med table
            String verifyPatient = "SELECT pat_id FROM med WHERE pat_id = ?";
            List<Map<String, Object>> patients = jdbcTemplate.queryForList(verifyPatient, patId);

            if (patients.isEmpty()) {
                return new ArrayList<>();
            }

            // Get prescribed tests for patient
            String sql = "SELECT DISTINCT sp.* " +
                    "FROM survey_project sp " +
                    "INNER JOIN PrescribedTests pt " +
                    "ON sp.sid = pt.prescribed_tests " +
                    "   OR sp.name = pt.prescribed_tests " + // Added this condition
                    "WHERE pt.pat_id = ? " +
                    "ORDER BY sp.creation_date DESC";

            return jdbcTemplate.query(sql, new Object[] { patId }, (resultSet, rowNum) -> {
                Map<String, Object> form = new HashMap<>();
                form.put("name", resultSet.getString("name"));
                form.put("sid", resultSet.getString("sid"));
                form.put("creation_date", resultSet.getString("creation_date"));
                form.put("description", resultSet.getString("description"));
                form.put("template_source", resultSet.getString("template_source"));
                form.put("details_source", resultSet.getString("details_source"));
                return form;
            });
        } catch (Exception e) {
            System.out.println("Error in getPrescribedFormsForPatient: " + e.getMessage());
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    @Override
    public Map<String, Object> getRecordLogByRid(String rid) {
        String sql = "SELECT r.*, sp.name as form_name FROM record_log r " +
                "INNER JOIN survey_project sp ON r.sid = sp.sid " +
                "WHERE r.rid = ?";
        try {
            return jdbcTemplate.queryForMap(sql, rid);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    @Override
    public List<Map<String, Object>> getPastResponsesBySubjectAndSid(String subjectId, String sid) {
        String sql = "SELECT * FROM record_log " +
                "WHERE subject_id = ? AND sid = ? " +
                "ORDER BY survey_datetime DESC";

        try {
            return jdbcTemplate.queryForList(sql, subjectId, sid);
        } catch (Exception e) {
            System.out.println("Error getting past responses: " + e.getMessage());
            return new ArrayList<>();
        }
    }
    // Soumya
    // Add these helper methods to your UserRepositoryImpl.java class

    private ChatSession mapChatSession(ResultSet rs, int rowNum) throws SQLException {
        ChatSession session = new ChatSession();
        session.setSessionId(rs.getString("session_id"));
        session.setPatId(rs.getString("pat_id"));
        session.setSessionDate(rs.getObject("session_date", LocalDate.class));
        session.setStartTime(rs.getObject("start_time", LocalDateTime.class));
        session.setEndTime(rs.getObject("end_time", LocalDateTime.class));
        session.setDuration(rs.getObject("duration", Integer.class));
        session.setSessionNotes(rs.getString("session_notes"));
        session.setSessionStatus(rs.getString("session_status"));
        session.setLanguagePreference(rs.getString("language_preference"));
        return session;
    }

    private ChatControl mapChatControl(ResultSet rs, int rowNum) throws SQLException {
        ChatControl control = new ChatControl();
        control.setPatId(rs.getString("pat_id"));
        control.setDailyChatLimit(rs.getObject("daily_chat_limit", Integer.class));
        control.setMaxSessionDuration(rs.getObject("max_session_duration", Integer.class));
        control.setMinSessionInterval(rs.getObject("min_session_interval", Integer.class));
        control.setBlackoutStartTime(rs.getObject("blackout_start_time", LocalTime.class));
        control.setBlackoutEndTime(rs.getObject("blackout_end_time", LocalTime.class));
        control.setBlackoutDays(rs.getString("blackout_days"));
        try {
            control.setChatType(rs.getString("chat_type"));
        } catch (SQLException ignored) {
            control.setChatType("original");
        }
        return control;
    }

    private ChatMessage mapChatMessage(ResultSet rs, int rowNum) throws SQLException {
        ChatMessage message = new ChatMessage();
        message.setMessageId(rs.getString("message_id"));
        message.setSessionId(rs.getString("session_id"));
        message.setMessageSequence(rs.getObject("message_sequence", Integer.class));
        message.setSenderType(rs.getString("sender_type"));
        message.setMessageContent(rs.getString("message_content"));
        message.setTimestamp(rs.getObject("timestamp", LocalDateTime.class));
        message.setIsRead(rs.getBoolean("is_read"));
        message.setResponseTime(rs.getObject("response_time", Integer.class));
        message.setFileFormat(rs.getString("file_format"));
        message.setFileSize(rs.getObject("file_size", Integer.class));
        return message;
    }

    private boolean createDefaultChatControls(String patId) {
        try {
            String sql = "INSERT INTO chat_control (pat_id, daily_chat_limit, max_session_duration, " +
                    "min_session_interval) VALUES (?, 3, 1800, 3600)";

            int rowsAffected = jdbcTemplate.update(sql, patId);
            return rowsAffected > 0;
        } catch (Exception e) {
            System.out.println("Error creating default chat controls: " + e.getMessage());
            return false;
        }
    }

    private boolean createChatControls(ChatControl chatControl) {
        try {
            String sql = "INSERT INTO chat_control (pat_id, daily_chat_limit, max_session_duration, " +
                    "min_session_interval, blackout_start_time, blackout_end_time, blackout_days) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)";

            int rowsAffected = jdbcTemplate.update(sql,
                    chatControl.getPatId(),
                    chatControl.getDailyChatLimit(),
                    chatControl.getMaxSessionDuration(),
                    chatControl.getMinSessionInterval(),
                    chatControl.getBlackoutStartTime(),
                    chatControl.getBlackoutEndTime(),
                    chatControl.getBlackoutDays());

            return rowsAffected > 0;
        } catch (Exception e) {
            System.out.println("Error creating chat controls: " + e.getMessage());
            return false;
        }
    }

    private Integer getNextMessageSequence(String sessionId) {
        try {
            String sql = "SELECT COALESCE(MAX(message_sequence), 0) + 1 FROM chat_messages WHERE session_id = ?";
            return jdbcTemplate.queryForObject(sql, Integer.class, sessionId);
        } catch (Exception e) {
            return 1;
        }
    }

    private boolean isInBlackoutPeriod(LocalTime currentTime, LocalTime startTime, LocalTime endTime) {
        if (startTime.isBefore(endTime)) {
            // Same-day blackout period
            return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
        } else {
            // Overnight blackout period
            return currentTime.isAfter(startTime) || currentTime.isBefore(endTime);
        }
    }

    // RCT flag
    @Override
    public boolean isPatientEnrolledInRCT(String patId) {
        try {
            String sql = "SELECT rctFlag FROM login WHERE uid = ?";
            Integer rctFlag = jdbcTemplate.queryForObject(sql, Integer.class, patId);
            boolean enrolled = rctFlag != null && rctFlag == 1;
            System.out.println("RCT enrollment check for " + patId + ": " + enrolled + " (rctFlag: " + rctFlag + ")");
            return enrolled;
        } catch (EmptyResultDataAccessException e) {
            System.out.println("Patient not found in login table for RCT check: " + patId);
            return false;
        } catch (Exception e) {
            System.out.println("Error checking RCT enrollment: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /* Chat Control */
    @Override
    public ChatControl getChatControls(String patId) {
        try {
            String sql = "SELECT * FROM chat_control WHERE pat_id = ?";
            List<ChatControl> controls = jdbcTemplate.query(sql, this::mapChatControl, patId);

            if (controls.isEmpty()) {
                // Create default controls for patient
                ChatControl defaultControl = new ChatControl(patId);
                createDefaultChatControls(patId);
                return defaultControl;
            }

            return controls.get(0);
        } catch (Exception e) {
            System.out.println("Error getting chat controls: " + e.getMessage());
            return new ChatControl(patId);
        }
    }

    @Override
    public boolean updateChatControls(String patId, ChatControl chatControl) {
        try {
            String sql = "UPDATE chat_control SET daily_chat_limit = ?, max_session_duration = ?, " +
                    "min_session_interval = ?, blackout_start_time = ?, blackout_end_time = ?, " +
                    "blackout_days = ? WHERE pat_id = ?";

            int rowsAffected = jdbcTemplate.update(sql,
                    chatControl.getDailyChatLimit(),
                    chatControl.getMaxSessionDuration(),
                    chatControl.getMinSessionInterval(),
                    chatControl.getBlackoutStartTime(),
                    chatControl.getBlackoutEndTime(),
                    chatControl.getBlackoutDays(),
                    patId);

            if (rowsAffected == 0) {
                // Insert if not exists
                return createChatControls(chatControl);
            }

            return rowsAffected > 0;
        } catch (Exception e) {
            System.out.println("Error updating chat controls: " + e.getMessage());
            return false;
        }
    }

    @Override
    public String getChatType(String patId) {
        try {
            String sql = "SELECT chat_type FROM chat_control WHERE pat_id = ?";
            List<String> results = jdbcTemplate.queryForList(sql, String.class, patId);
            return (results.isEmpty() || results.get(0) == null) ? "original" : results.get(0);
        } catch (Exception e) {
            System.out.println("Error getting chat_type for " + patId + ": " + e.getMessage());
            return "original";
        }
    }

    @Override
    public int getCompletedSessionCount(String patId) {
        try {
            String sql = "SELECT COUNT(*) FROM chat_sessions WHERE pat_id = ? AND session_status = 'completed'";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class, patId);
            return count != null ? count : 0;
        } catch (Exception e) {
            System.out.println("Error getting completed session count for " + patId + ": " + e.getMessage());
            return 0;
        }
    }

    @Override
    public String getLatestDeltaSummary(String patId) {
        try {
            String sql = "SELECT persistent_triggers, persistent_concerns, cumulative_quit_history, " +
                    "continued_advice, readiness_after FROM session_deltas " +
                    "WHERE pat_id = ? ORDER BY to_session_date DESC, delta_id DESC LIMIT 1";
            Map<String, Object> row = jdbcTemplate.queryForMap(sql, patId);

            String triggers = jsonArrayToList(row.get("persistent_triggers"));
            String concerns = jsonArrayToList(row.get("persistent_concerns"));
            String advice = jsonArrayToList(row.get("continued_advice"));
            String quitHistory = Objects.toString(row.get("cumulative_quit_history"), "").trim();
            String readiness = Objects.toString(row.get("readiness_after"), "").trim();

            StringBuilder sb = new StringBuilder();
            if (!readiness.isEmpty())
                sb.append("Stage: ").append(readiness).append("\n");
            if (!triggers.isEmpty())
                sb.append("Triggers: ").append(triggers).append("\n");
            if (!concerns.isEmpty())
                sb.append("Concerns: ").append(concerns).append("\n");
            if (!advice.isEmpty())
                sb.append("Interventions: ").append(advice).append("\n");
            if (!quitHistory.isEmpty())
                sb.append("Relapse History: ").append(quitHistory).append("\n");

            String summary = sb.toString().trim();
            return summary.isEmpty() ? null : summary;
        } catch (EmptyResultDataAccessException e) {
            // No delta yet — fall back to latest session's signal data
            return getLatestSessionSignalSummary(patId);
        } catch (Exception e) {
            System.out.println("Error getting latest delta summary for " + patId + ": " + e.getMessage());
            return getLatestSessionSignalSummary(patId);
        }
    }

    private String getLatestSessionSignalSummary(String patId) {
        try {
            String sql = "SELECT si.readiness, si.triggers, si.concerns, si.advice, si.quit_history " +
                    "FROM session_history sh " +
                    "JOIN signal_history si ON sh.signal_id = si.signal_id " +
                    "WHERE sh.pat_id = ? " +
                    "ORDER BY sh.session_date DESC, sh.start_time DESC LIMIT 1";
            Map<String, Object> row = jdbcTemplate.queryForMap(sql, patId);

            String triggers = jsonArrayToList(row.get("triggers"));
            String concerns = jsonArrayToList(row.get("concerns"));
            String advice = jsonArrayToList(row.get("advice"));
            String quitHistory = Objects.toString(row.get("quit_history"), "").trim();
            String readiness = Objects.toString(row.get("readiness"), "").trim();

            StringBuilder sb = new StringBuilder();
            if (!readiness.isEmpty())
                sb.append("Stage: ").append(readiness).append("\n");
            if (!triggers.isEmpty())
                sb.append("Triggers: ").append(triggers).append("\n");
            if (!concerns.isEmpty())
                sb.append("Concerns: ").append(concerns).append("\n");
            if (!advice.isEmpty())
                sb.append("Interventions: ").append(advice).append("\n");
            if (!quitHistory.isEmpty())
                sb.append("Relapse History: ").append(quitHistory).append("\n");

            String summary = sb.toString().trim();
            return summary.isEmpty() ? null : summary;
        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (Exception e) {
            System.out.println("Error getting latest session signal summary for " + patId + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Parses a JSON array string (e.g. '["a","b"]') into a comma-separated list;
     * falls back to the raw value.
     */
    private String jsonArrayToList(Object value) {
        String raw = Objects.toString(value, "").trim();
        if (raw.isEmpty())
            return "";
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            List<String> items = mapper.readValue(raw,
                    new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {
                    });
            return String.join(", ", items);
        } catch (Exception e) {
            return raw;
        }
    }

    @Override
    public boolean validateChatSession(String patId) {
        try {
            System.out.println("=== Starting chat session validation for patient: " + patId + " ===");
            // RCT enrollment check
            if (!isPatientEnrolledInRCT(patId)) {
                System.out.println("Validation failed: Patient not enrolled in RCT study");
                return false;
            }
            System.out.println("RCT enrollment check: OK");// rct
            ChatControl controls = getChatControls(patId);
            LocalDateTime now = LocalDateTime.now();
            LocalTime currentTime = now.toLocalTime();
            String currentDay = now.getDayOfWeek().toString();

            System.out.println("Current time: " + currentTime);
            System.out.println("Current day: " + currentDay);
            System.out.println("Chat controls: " + controls);

            // Check if patient exists
            if (!isPatientExists(patId)) {
                System.out.println("Validation failed: Patient does not exist");
                return false;
            }
            System.out.println("Patient exists: OK");

            // Check if there's an active session that has exceeded maximum duration
            ChatSession activeSession = getActiveSession(patId);
            if (activeSession != null) {
                Integer maxDuration = controls.getMaxSessionDuration();
                if (maxDuration != null && maxDuration > 0) {
                    long sessionDurationSeconds = ChronoUnit.SECONDS.between(activeSession.getStartTime(), now);
                    System.out.println("Active session found: " + activeSession.getSessionId());
                    System.out.println("Session duration: " + sessionDurationSeconds + " seconds");
                    System.out.println("Max allowed duration: " + maxDuration + " seconds");

                    if (sessionDurationSeconds >= maxDuration) {
                        System.out.println("Validation failed: Active session has exceeded maximum duration");

                        // Automatically end the session that has exceeded duration
                        try {
                            endChatSession(activeSession.getSessionId(),
                                    "Session automatically ended - exceeded maximum duration");
                            System.out.println("Automatically ended session: " + activeSession.getSessionId());
                        } catch (Exception e) {
                            System.out.println("Error auto-ending session: " + e.getMessage());
                        }

                        return false;
                    }
                    System.out.println("Active session duration check: OK");
                }
            }

            // Check daily limit
            Integer todayCount = getTodaySessionCount(patId);
            Integer dailyLimit = controls.getDailyChatLimit();
            System.out.println("Today's sessions: " + todayCount + ", Daily limit: " + dailyLimit);

            if (todayCount >= dailyLimit) {
                System.out.println("Validation failed: Daily limit exceeded");
                return false;
            }
            System.out.println("Daily limit check: OK");

            // Check blackout period
            LocalTime blackoutStart = controls.getBlackoutStartTime();
            LocalTime blackoutEnd = controls.getBlackoutEndTime();

            if (blackoutStart != null && blackoutEnd != null) {
                System.out.println("Checking blackout period: " + blackoutStart + " - " + blackoutEnd);
                if (isInBlackoutPeriod(currentTime, blackoutStart, blackoutEnd)) {
                    System.out.println("Validation failed: Currently in blackout period");
                    return false;
                }
            }
            System.out.println("Blackout period check: OK");

            // Check blackout days
            String blackoutDays = controls.getBlackoutDays();
            if (blackoutDays != null && !blackoutDays.isEmpty()) {
                System.out.println("Checking blackout days: " + blackoutDays);
                if (blackoutDays.toUpperCase().contains(currentDay)) {
                    System.out.println("Validation failed: Today is a blackout day");
                    return false;
                }
            }
            System.out.println("Blackout days check: OK");

            // Check minimum interval
            LocalDateTime lastSessionEnd = getLastSessionEndTime(patId);
            Integer minInterval = controls.getMinSessionInterval();

            if (lastSessionEnd != null && minInterval != null) {
                long secondsSinceLastSession = ChronoUnit.SECONDS.between(lastSessionEnd, now);
                System.out.println("Last session ended: " + lastSessionEnd +
                        ", Seconds since: " + secondsSinceLastSession +
                        ", Min interval required: " + minInterval);

                if (secondsSinceLastSession < minInterval) {
                    System.out.println("Validation failed: Minimum interval not met");
                    return false;
                }
            }
            System.out.println("Minimum interval check: OK");

            System.out.println("=== Chat session validation PASSED ===");
            return true;

        } catch (Exception e) {
            System.out.println("Error in validateChatSession: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    // Helper Methods
    @Override
    public boolean isPatientExists(String patId) {
        try {
            String sql = "SELECT COUNT(*) FROM med WHERE pat_id = ?";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class, patId);
            boolean exists = count != null && count > 0;
            System.out.println("Patient existence check for " + patId + ": " + exists + " (count: " + count + ")");
            return exists;
        } catch (Exception e) {
            System.out.println("Error checking patient existence: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    // Update getTodaySessionCount with logging
    @Override
    public Integer getTodaySessionCount(String patId) {
        try {
            String sql = "SELECT COUNT(*) FROM chat_sessions WHERE pat_id = ? AND session_date = CURDATE()";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class, patId);
            System.out.println("Today's session count for " + patId + ": " + count);
            return count != null ? count : 0;
        } catch (Exception e) {
            System.out.println("Error getting today's session count: " + e.getMessage());
            e.printStackTrace();
            return 0;
        }
    }

    // Update getLastSessionEndTime with logging
    @Override
    public LocalDateTime getLastSessionEndTime(String patId) {
        try {
            String sql = "SELECT end_time FROM chat_sessions WHERE pat_id = ? AND end_time IS NOT NULL " +
                    "ORDER BY end_time DESC LIMIT 1";
            LocalDateTime lastEndTime = jdbcTemplate.queryForObject(sql, LocalDateTime.class, patId);
            System.out.println("Last session end time for " + patId + ": " + lastEndTime);
            return lastEndTime;
        } catch (EmptyResultDataAccessException e) {
            System.out.println("No previous sessions found for " + patId);
            return null;
        } catch (Exception e) {
            System.out.println("Error getting last session end time: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    // Chat Session Management Methods
    @Override
    public String startChatSession(String patId, String languagePreference) {
        try {
            String sessionId = "chat_" + UUID.randomUUID().toString();
            LocalDateTime now = LocalDateTime.now();
            LocalDate today = now.toLocalDate();

            // Ensure languagePreference is valid: "en" or "bn"
            if (languagePreference == null || languagePreference.isBlank()) {
                languagePreference = "en";
            }
            languagePreference = languagePreference.toLowerCase().trim();
            if (!languagePreference.equals("bn")) {
                languagePreference = "en";
            }

            String sql = "INSERT INTO chat_sessions (session_id, pat_id, session_date, start_time, session_status, language_preference) "
                    +
                    "VALUES (?, ?, ?, ?, 'active', ?)";

            jdbcTemplate.update(sql, sessionId, patId, today, now, languagePreference);
            return sessionId;
        } catch (Exception e) {
            System.out.println("Error starting chat session: " + e.getMessage());
            return null;
        }
    }

    @Override
    public boolean endChatSession(String sessionId, String sessionNotes) {
        try {
            LocalDateTime endTime = LocalDateTime.now();

            // Get start time to calculate duration
            String getStartTimeSql = "SELECT start_time FROM chat_sessions WHERE session_id = ?";
            LocalDateTime startTime = jdbcTemplate.queryForObject(getStartTimeSql, LocalDateTime.class, sessionId);

            if (startTime != null) {
                long duration = ChronoUnit.SECONDS.between(startTime, endTime);

                String sql = "UPDATE chat_sessions SET end_time = ?, duration = ?, session_notes = ?, " +
                        "session_status = 'completed' WHERE session_id = ?";

                int rowsAffected = jdbcTemplate.update(sql, endTime, duration, sessionNotes, sessionId);
                return rowsAffected > 0;
            }
            return false;
        } catch (Exception e) {
            System.out.println("Error ending chat session: " + e.getMessage());
            return false;
        }
    }

    @Override
    public List<ChatSession> getChatSessions(String patId, Integer limit, Integer offset) {
        try {
            String sql = "SELECT * FROM chat_sessions WHERE pat_id = ? ORDER BY start_time DESC";

            if (limit != null && offset != null) {
                sql += " LIMIT ? OFFSET ?";
                return jdbcTemplate.query(sql, this::mapChatSession, patId, limit, offset);
            } else {
                return jdbcTemplate.query(sql, this::mapChatSession, patId);
            }
        } catch (Exception e) {
            System.out.println("Error getting chat sessions: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    @Override
    public ChatSession getActiveSession(String patId) {
        try {
            String sql = "SELECT * FROM chat_sessions WHERE pat_id = ? AND session_status = 'active' " +
                    "ORDER BY start_time DESC LIMIT 1";

            List<ChatSession> sessions = jdbcTemplate.query(sql, this::mapChatSession, patId);
            return sessions.isEmpty() ? null : sessions.get(0);
        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (Exception e) {
            System.out.println("Error getting active session: " + e.getMessage());
            return null;
        }
    }
    // Chat Messaging Methods

    @Override
    public String sendChatMessage(String sessionId, String senderType, String messageContent) {
        try {
            String messageId = "msg_" + UUID.randomUUID().toString();
            LocalDateTime now = LocalDateTime.now();

            // Get next sequence number
            Integer nextSequence = getNextMessageSequence(sessionId);

            String sql = "INSERT INTO chat_messages (message_id, session_id, message_sequence, " +
                    "sender_type, message_content, timestamp) VALUES (?, ?, ?, ?, ?, ?)";

            jdbcTemplate.update(sql, messageId, sessionId, nextSequence, senderType, messageContent, now);
            return messageId;
        } catch (Exception e) {
            System.out.println("Error sending chat message: " + e.getMessage());
            return null;
        }
    }

    @Override
    public List<ChatMessage> getChatMessages(String sessionId, Integer limit, Integer offset) {
        try {
            String sql = "SELECT * FROM chat_messages WHERE session_id = ? ORDER BY message_sequence";

            if (limit != null && offset != null) {
                sql += " LIMIT ? OFFSET ?";
                return jdbcTemplate.query(sql, this::mapChatMessage, sessionId, limit, offset);
            } else {
                return jdbcTemplate.query(sql, this::mapChatMessage, sessionId);
            }
        } catch (Exception e) {
            System.out.println("Error getting chat messages: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    @Override
    public List<ChatMessage> getRecentChatMessages(String sessionId, int limit) {
        try {
            String sql = "SELECT * FROM chat_messages WHERE session_id = ? " +
                    "ORDER BY message_sequence DESC LIMIT ?";
            List<ChatMessage> messages = jdbcTemplate.query(sql, this::mapChatMessage, sessionId, limit);
            Collections.reverse(messages); // back to chronological (oldest-first) order
            return messages;
        } catch (Exception e) {
            System.out.println("Error getting recent chat messages: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    @Override
    public ChatMessage getAssistantMessageForPatient(String messageId, String patId) {
        String sql = "SELECT cm.* FROM chat_messages cm " +
                "JOIN chat_sessions cs ON cs.session_id = cm.session_id " +
                "WHERE cm.message_id = ? AND cs.pat_id = ? AND cm.sender_type = 'bot'";
        List<ChatMessage> messages = jdbcTemplate.query(sql, this::mapChatMessage, messageId, patId);
        return messages.isEmpty() ? null : messages.get(0);
    }

    @Override
    public boolean markMessagesAsRead(String sessionId, List<String> messageIds) {
        try {
            if (messageIds == null || messageIds.isEmpty()) {
                return false;
            }

            String sql = "UPDATE chat_messages SET is_read = 1 WHERE session_id = ? AND message_id IN (" +
                    String.join(",", Collections.nCopies(messageIds.size(), "?")) + ")";

            Object[] params = new Object[messageIds.size() + 1];
            params[0] = sessionId;
            for (int i = 0; i < messageIds.size(); i++) {
                params[i + 1] = messageIds.get(i);
            }

            int rowsAffected = jdbcTemplate.update(sql, params);
            return rowsAffected > 0;
        } catch (Exception e) {
            System.out.println("Error marking messages as read: " + e.getMessage());
            return false;
        }
    }

    @Override
    public Integer getUnreadMessageCount(String patId) {
        try {
            String sql = "SELECT COUNT(*) FROM chat_messages cm " +
                    "JOIN chat_sessions cs ON cm.session_id = cs.session_id " +
                    "WHERE cs.pat_id = ? AND cm.is_read = 0 AND cm.sender_type != 'patient'";

            return jdbcTemplate.queryForObject(sql, Integer.class, patId);
        } catch (Exception e) {
            System.out.println("Error getting unread message count: " + e.getMessage());
            return 0;
        }
    }

    // Add these methods to UserRepositoryImpl.java

    @Override
    public void logTerminalCommand(String sessionId, String command, String output) {
        try {
            String sql = "INSERT INTO terminal_logs (session_id, command, output, timestamp) VALUES (?, ?, ?, NOW())";
            jdbcTemplate.update(sql, sessionId, command, output);
        } catch (Exception e) {
            System.out.println("Error logging terminal command: " + e.getMessage());
        }
    }

    @Override
    public ChatSession getChatSessionById(String sessionId) {
        try {
            String sql = "SELECT * FROM chat_sessions WHERE session_id = ?";
            List<ChatSession> sessions = jdbcTemplate.query(sql, this::mapChatSession, sessionId);
            return sessions.isEmpty() ? null : sessions.get(0);
        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (Exception e) {
            System.out.println("Error getting chat session by ID: " + e.getMessage());
            return null;
        }
    }

    @Override
    public List<Map<String, Object>> getTerminalHistory(String sessionId) {
        try {
            String sql = "SELECT command, output, timestamp FROM terminal_logs WHERE session_id = ? ORDER BY timestamp DESC LIMIT 50";
            return jdbcTemplate.queryForList(sql, sessionId);
        } catch (Exception e) {
            System.out.println("Error getting terminal history: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    @Override
    public Map<String, Object> getPatientInfo(String patid) {
        String sql = "select *, (select count(*) from patientvisit where pat_id=?) as noofvisit from med where pat_id=?";
        Map<String, Object> res = new HashMap<>();
        try {
            res = jdbcTemplate.queryForMap(sql, patid, patid);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return res;
    }

    @Override
    public Map<String, Object> getSubjectInfo(String subject_id) {

        // String isql="Select * from subject where subject_id='" +subject_id+"'";
        // return mydb.ExecuteQuary(isql);
        return jdbcTemplate.queryForMap("select * from subject where subject_id=?", subject_id);

    }

    public static String dateFormat(String fmat, Date dt) {

        String str = "";
        try {
            Date date = dt;
            DateFormat df = new SimpleDateFormat(fmat);
            str = df.format(date);

        } catch (Exception e) {
            System.out.println(e.toString());
            str = "";
        }

        return str;
    }

    public static String getCurrentDateMySql() {
        Date dt = new Date();
        String fmt = "yyyyMMddHHmmss";
        return dateFormat(fmt, dt);
    }

    @Override
    // public String createNewSurvey(dataobj obj)throws RemoteException,SQLException
    public boolean createNewSurvey(Map<String, String> data) {

        try {
            String creation_date = getCurrentDateMySql();
            String sid = genSurveyId();

            String query = "insert into survey_project (name,sid,creation_date,description,template_source,details_source) values (?,?,?,?,?,?)";
            jdbcTemplate.update(query, data.get("name"), sid, creation_date, data.get("description"),
                    data.get("template_source"), data.get("details_source"));
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    public String genSurveyId() {
        String sql = "select count(sid) from survey_project";
        // return jdbcTemplate.queryForObject(sql, String.class);
        String cnt = jdbcTemplate.queryForObject(sql, String.class);
        System.out.println("iSql= cnt " + cnt);

        String ans = "s" + Integer.toString(Integer.parseInt(cnt) + 1);
        return ans;
    }

    @Override
    public List<String> getAllocateZone(String userid) {
        String sql = "Select zone_id from allocateZone where userid='" + userid + "'";
        // return jdbcTemplate.queryForMap(sql, userid);
        return jdbcTemplate.queryForList(sql, String.class);

    }

    @Override
    public Map<String, Object> getZoneInfo(String zone_id) {

        String sql = "Select * from zone where zone_id='" + zone_id + "'";
        // return jdbcTemplate.queryForMap(sql, userid);
        return jdbcTemplate.queryForMap(sql);

    }

    @Override
    public List<String> getAllocateSurveyor(String userid) {
        String sql = "Select sid from allocateSurveyor where userid='" + userid + "'";
        return jdbcTemplate.queryForList(sql, String.class);

    }

    @Override
    public Map<String, Object> getSurveyInfo(String sid) {
        String sql = "Select * from survey_project where sid='" + sid + "'";
        return jdbcTemplate.queryForMap(sql);
    }

    @Override
    public List<Survey> getFieldProjectInfo(String sid) {
        String sql = "Select * from field_project where sid='" + sid + "'";
        // Survey(String fid, String sid, String attribute_name, String
        // attribute_datatype, String attribute_unit, String required_value)
        List<Survey> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Survey(rs.getString("fid"), rs.getString("sid"), rs.getString("source_type"),
                        rs.getString("attribute_name"),
                        rs.getString("attribute_datatype"), rs.getString("attribute_unit"),
                        rs.getString("required_value")));

        return result;
    }

    @Override
    public boolean createFieldEntry(Map<String, String> data) {

        try {

            String query = "insert into field_entry (rid,fid,value) values (?,?,?)";
            jdbcTemplate.update(query, data.get("rid"), data.get("fid"), data.get("value"));
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    @Override
    public String getFieldEntriesValue(String rid, String fid) {
        String sql = "Select value from field_entry where rid='" + rid + "' and fid='" + fid + "'";
        String value = jdbcTemplate.queryForObject(sql, String.class);
        return value;
    }

    // @Override
    // public String createRecordLog(Map<String, String> data) {
    //
    // int ans = 0;
    // String subject_id = data.get("subject_id");
    // String survey_data = data.get("survey_data");
    // String sid = data.get("sid");
    // String record_type = data.get("record_type");
    // String image = data.get("image");
    // String voice = data.get("voice");
    // String userid = data.get("userid");
    // String username = data.get("username");
    // String scoreStr = data.get("score");
    //
    //
    // String survey_datetime = getCurrentDateMySql();
    // String rid = genRecordId(sid);
    //
    // // Determine if we should include score in the insert
    // String query;
    // if (scoreStr != null && !scoreStr.isEmpty() && !scoreStr.equals("null")) {
    // query = "insert into record_log
    // (rid,subject_id,survey_datetime,sid,record_type,survey_data,image,voice,userid,username,score)
    // " +
    // "values ('" + rid + "','" + subject_id + "','" + survey_datetime + "','" +
    // sid + "','" + record_type + "','" +
    // survey_data + "','" + image + "','" + voice + "','" + userid + "','" +
    // username + "'," + scoreStr + ")";
    // } else {
    // query = "insert into record_log
    // (rid,subject_id,survey_datetime,sid,record_type,survey_data,image,voice,userid,username)
    // " +
    // "values ('" + rid + "','" + subject_id + "','" + survey_datetime + "','" +
    // sid + "','" + record_type + "','" +
    // survey_data + "','" + image + "','" + voice + "','" + userid + "','" +
    // username + "')";
    // }
    //
    // try {
    // jdbcTemplate.update(query);
    // System.out.println("Record created successfully with RID: " + rid + (scoreStr
    // != null ? ", Score: " + scoreStr : ""));
    // } catch (Exception e) {
    // System.out.println(e.getMessage());
    // e.printStackTrace();
    // return "error";
    // }
    //
    // return rid;
    // }
    // @Override
    // public String createRecordLog(Map<String, String> data) {
    //
    // String subject_id = data.get("subject_id");
    // String survey_data = data.get("survey_data");
    // String sid = data.get("sid");
    // String record_type = data.get("record_type");
    // String image = data.get("image");
    // String voice = data.get("voice");
    // String userid = data.get("userid");
    // String username = data.get("username");
    // String scoreStr = data.get("score");
    //
    // String survey_datetime = getCurrentDateMySql();
    // String rid = genRecordId(sid);
    //
    // String query;
    // if (scoreStr != null && !scoreStr.isEmpty() && !scoreStr.equals("null")) {
    // query = "INSERT INTO record_log (rid, subject_id, survey_datetime, sid,
    // record_type, survey_data, image, voice, userid, username, score) " +
    // "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    // } else {
    // query = "INSERT INTO record_log (rid, subject_id, survey_datetime, sid,
    // record_type, survey_data, image, voice, userid, username) " +
    // "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    // }
    //
    // try {
    // if (scoreStr != null && !scoreStr.isEmpty() && !scoreStr.equals("null")) {
    // jdbcTemplate.update(query,
    // rid,
    // subject_id,
    // survey_datetime,
    // sid,
    // record_type,
    // survey_data, // apostrophes handled automatically
    // image,
    // voice,
    // userid,
    // username,
    // Integer.parseInt(scoreStr) // or Double.parseDouble() if score is decimal
    // );
    // } else {
    // jdbcTemplate.update(query,
    // rid,
    // subject_id,
    // survey_datetime,
    // sid,
    // record_type,
    // survey_data, // apostrophes handled automatically
    // image,
    // voice,
    // userid,
    // username
    // );
    // }
    // System.out.println("Record created successfully with RID: " + rid + (scoreStr
    // != null ? ", Score: " + scoreStr : ""));
    // } catch (Exception e) {
    // System.out.println(e.getMessage());
    // e.printStackTrace();
    // return "error";
    // }
    //
    // return rid;
    // }

    @Override
    public String createRecordLog(Map<String, String> data) {

        String subject_id = data.get("subject_id");
        String survey_data = data.get("survey_data");
        String sid = data.get("sid");
        String record_type = data.get("record_type");
        String image = data.get("image");
        String voice = data.get("voice");
        String userid = data.get("userid");
        String username = data.get("username");
        String scoreStr = data.get("score");

        String survey_datetime = getCurrentDateMySql();

        String query;
        if (scoreStr != null && !scoreStr.isEmpty() && !scoreStr.equals("null")) {
            query = "INSERT INTO record_log (rid, subject_id, survey_datetime, sid, record_type, survey_data, image, voice, userid, username, score) "
                    +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        } else {
            query = "INSERT INTO record_log (rid, subject_id, survey_datetime, sid, record_type, survey_data, image, voice, userid, username) "
                    +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        }

        // genRecordId() + insert has to happen as one unit, otherwise two
        // near-simultaneous
        // requests for the same sid can both read the same count(*) and generate the
        // same
        // rid (this is what caused "Duplicate entry 's14_255' for key
        // 'record_log.PRIMARY'").
        // synchronized makes it atomic within this JVM; the retry loop is a safety net
        // in
        // case a collision still slips through.
        synchronized (recordLogIdLock) {
            int maxAttempts = 5;
            for (int attempt = 1; attempt <= maxAttempts; attempt++) {
                String rid = genRecordId(sid);
                try {
                    if (scoreStr != null && !scoreStr.isEmpty() && !scoreStr.equals("null")) {
                        jdbcTemplate.update(query,
                                rid,
                                subject_id,
                                survey_datetime,
                                sid,
                                record_type,
                                survey_data, // apostrophes handled automatically
                                image,
                                voice,
                                userid,
                                username,
                                Integer.parseInt(scoreStr) // or Double.parseDouble() if score is decimal
                        );
                    } else {
                        jdbcTemplate.update(query,
                                rid,
                                subject_id,
                                survey_datetime,
                                sid,
                                record_type,
                                survey_data, // apostrophes handled automatically
                                image,
                                voice,
                                userid,
                                username);
                    }
                    System.out.println("Record created successfully with RID: " + rid
                            + (scoreStr != null ? ", Score: " + scoreStr : ""));
                    return rid;
                } catch (DuplicateKeyException e) {
                    System.out.println("RID collision on " + rid + ", regenerating (attempt " + attempt + " of "
                            + maxAttempts + ")");
                    // loop again - genRecordId(sid) will now see the row that just collided
                } catch (Exception e) {
                    System.out.println(e.getMessage());
                    e.printStackTrace();
                    return "error";
                }
            }
        }

        System.out.println("Could not generate a unique RID for sid=" + sid + " after retries");
        return "error";
    }

    @Override
    public String updateSurveyDataRecordLog(Map<String, String> data) {

        int ans = 0;
        String rid = data.get("rid");
        String survey_data = data.get("survey_data");

        String query = "update record_log set survey_data ='" + survey_data + "' where rid ='" + rid + "'";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            // return false;
            return "error";
        }
        // return true;
        return rid;

    }

    // public String genRecordId(String sid) {
    // String sql = "select count(*) from record_log where rid like '" + sid +
    // "_%'";
    // //return jdbcTemplate.queryForObject(sql, String.class);
    // String cnt = jdbcTemplate.queryForObject(sql, String.class);
    // System.out.println("iSql= cnt " + cnt);
    //
    // String ans = sid + "_" + Integer.toString(Integer.parseInt(cnt) + 1);
    // return ans;
    // }

    public String genRecordId(String sid) {
        String sql = "SELECT COALESCE(MAX(CAST(SUBSTRING_INDEX(rid, '_', -1) AS UNSIGNED)), 0) " +
                "FROM record_log WHERE rid LIKE ?";
        Integer maxSuffix = jdbcTemplate.queryForObject(sql, Integer.class, sid + "_%");
        System.out.println("iSql= max suffix for " + sid + " = " + maxSuffix);

        String ans = sid + "_" + Integer.toString((maxSuffix != null ? maxSuffix : 0) + 1);
        return ans;
    }

    @Override
    public List<Record> getRecordLogBySid(String sid) {
        String sql = "Select * from record_log where sid='" + sid + "'";

        // String rid, String subject_id, String survey_datetime, String survey_data,
        // String instance_time
        List<Record> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Record(rs.getString("rid"), rs.getString("subject_id"),
                        rs.getString("survey_datetime"),
                        rs.getString("sid"), rs.getString("record_type"), rs.getString("survey_data"),
                        rs.getString("image"), rs.getString("voice"), rs.getString("userid"), rs.getString("username"),
                        rs.getString("instance_time")));

        return result;

    }

    @Override
    public List<Record> getRecordLogBySubjectId(String subject_id) {
        String sql = "Select * from record_log where subject_id='" + subject_id + "'";
        List<Record> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Record(rs.getString("rid"), rs.getString("subject_id"),
                        rs.getString("survey_datetime"),
                        rs.getString("sid"), rs.getString("record_type"), rs.getString("survey_data"),
                        rs.getString("image"), rs.getString("voice"), rs.getString("userid"), rs.getString("username"),
                        rs.getString("instance_time")));

        return result;

    }

    @Override
    public List<Record> getRecordLogBySubjectIdInstanceTime(String subject_id, String InstanceTime) {
        String sql = "Select * from record_log where subject_id='" + subject_id + "' and DATE(instance_time) >= '"
                + InstanceTime + "'";
        List<Record> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Record(rs.getString("rid"), rs.getString("subject_id"),
                        rs.getString("survey_datetime"),
                        rs.getString("sid"), rs.getString("record_type"), rs.getString("survey_data"),
                        rs.getString("image"), rs.getString("voice"), rs.getString("userid"), rs.getString("username"),
                        rs.getString("instance_time")));

        return result;

    }

    public String genSubjectId(String zone_id, String village) {
        /*
         * String sql = "select count(*) from subject where subject_id like '" + zone_id
         * + "_%'";
         * //return jdbcTemplate.queryForObject(sql, String.class);
         * String cnt = jdbcTemplate.queryForObject(sql, String.class);
         * System.out.println("iSql= cnt " + cnt);
         * 
         * String ans = zone_id + "_" + Integer.toString(Integer.parseInt(cnt) + 1);
         */
        String ans = "";
        String cod = village.substring(0, 4).toUpperCase();
        String dat = "", id = "";

        Date dt = new Date();
        int dd, mm, yy;

        dd = dt.getDate();
        mm = dt.getMonth() + 1;
        ;
        yy = dt.getYear() + 1900;
        if (dd < 10) {
            dat = "0" + dd;
        } else {
            dat = "" + dd;
        }
        if (mm < 10) {
            dat = dat + "0" + mm;
        } else {
            dat = dat + mm;
        }
        dat = dat + Integer.toString(yy).substring(2);

        // dat1 = tmp.getValue("entrydate");
        // //Integer.toString(yy)+"/"+dat.substring(2,4)+"/"+dat.substring(0,2);

        // cod=cod+"."+dat;
        cod = cod + dat;
        // qr = "select count(pat_id) as p from med where pat_id like '" + cod + "%'";
        String qr = "select count(*) from subject where subject_id like '" + cod + "_%'";
        // System.out.println(qr);
        // String cnt=mydb.ExecuteSingle(qr);
        String cnt = jdbcTemplate.queryForObject(qr, String.class);

        if (cnt.equalsIgnoreCase(""))
            cnt = "0";
        int nu = Integer.parseInt(cnt);
        if (nu < 10) {
            id = cod + "000" + cnt;
        } else if (nu < 100) {
            id = cod + "00" + cnt;
        } else {
            id = cod + "0" + cnt;
        }

        ans = id;

        return ans;
    }

    @Override
    public String InsertSubject(Map<String, String> data) {

        int ans = 0;

        // subjectname,subject_id,spousename,childname,relatives,maritalstatus,village,idtype,idnumber,age,sex,caste,religion,image,voice,occupation,zone_id,address,mobile,email
        String subjectname = data.get("subjectname");
        String spousename = data.get("spousename");
        String childname = data.get("childname");
        String relatives = data.get("relatives");
        String maritalstatus = data.get("maritalstatus");
        String village = data.get("village");
        String idtype = data.get("idtype");
        String idnumber = data.get("idnumber");
        String caste = data.get("caste");
        String religion = data.get("religion");
        String image = data.get("image");
        String voice = data.get("voice");
        String age = data.get("age");
        String sex = data.get("sex");
        String zone_id = data.get("zone_id");
        String occupation = data.get("occupation");
        String address = data.get("address");
        String mobile = data.get("mobile");
        String email = data.get("email");

        String subject_id = genSubjectId(zone_id, village);

        // subjectname,subject_id,spousename,childname,relatives,maritalstatus,village,idtype,idnumber,age,sex,caste,religion,image,voice,occupation,zone_id,address,mobile,email
        // String query = "insert into subject
        // (name,subject_id,age,sex,occupation,zone_id,address,mobile,email) values ('"
        // + name + "','" + subject_id + "','" + age + "','" + sex + "','" + occupation
        // + "','" + zone_id + "','" + address + "','" + mobile + "','" + email + "')";
        String query = "insert into subject (subjectname,subject_id,spousename,childname,relatives,maritalstatus,village,idtype,idnumber,age,sex,caste,"
                +
                "religion,image,voice,occupation,zone_id,address,mobile,email) " +
                "values ('" + subjectname + "','" + subject_id + "','" + spousename + "','" + childname + "','"
                + relatives + "','" + maritalstatus +
                "','" + village + "','" + idtype + "','" + idnumber + "','" + age + "','" + sex + "','" + caste + "','"
                + religion +
                "','" + image + "','" + voice + "','" + occupation + "','" + zone_id + "','" + address + "','" + mobile
                + "','" + email + "')";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            // return false;
            return "error";
        }
        // return true;
        return subject_id;

    }

    @Override
    public List<Subject> getSubjectInfoByZone(String zone_id) {
        // String sql = "select
        // name,subject_id,age,sex,occupation,zone_id,address,mobile,email from subject
        // where zone_id='"+zone_id+"'";
        String sql = "select * from subject where zone_id='" + zone_id + "'";

        List<Subject> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Subject(rs.getString("subjectname"), rs.getString("subject_id"),
                        rs.getString("age"),
                        rs.getString("sex"), rs.getString("occupation"), rs.getString("zone_id"),
                        rs.getString("address"), rs.getString("mobile"), rs.getString("email"),
                        rs.getString("spousename"), rs.getString("childname"), rs.getString("relatives"),
                        rs.getString("maritalstatus"), rs.getString("village"),
                        rs.getString("idtype"), rs.getString("idnumber"), rs.getString("caste"),
                        rs.getString("religion"), rs.getString("image"), rs.getString("voice")));

        return result;

    }

    public String genServiceId() {
        String sql = "select count(*) from service";
        // return jdbcTemplate.queryForObject(sql, String.class);
        String cnt = jdbcTemplate.queryForObject(sql, String.class);
        System.out.println("iSql= cnt " + cnt);

        String ans = "serv" + "_" + Integer.toString(Integer.parseInt(cnt) + 1);

        return ans;
    }

    @Override
    public String createService(Map<String, String> data) {

        int ans = 0;
        String sname = data.get("sname");
        String description = data.get("description");
        String start_date = data.get("start_date");
        String end_date = data.get("end_date");

        String service_id = genServiceId();

        String query = "insert into service (service_id, sname,description,start_date,end_date) values ('" + service_id
                + "','" + sname + "','" + description + "','" + start_date + "','" + end_date + "')";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            // return false;
            return "error";
        }
        // return true;
        return service_id;

    }

    @Override
    public boolean newServiceEnrollment(Map<String, String> data) {

        int ans = 0;
        String service_id = data.get("service_id");
        String subject_id = data.get("subject_id");
        String sid = data.get("sid");
        String start_date = data.get("start_date");
        String end_date = data.get("end_date");

        String query = "insert into service_enrollment (service_id, subject_id,sid,start_date,end_date) values ('"
                + service_id + "','" + subject_id + "','" + sid + "','" + start_date + "','" + end_date + "')";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    /*
     * @Override
     * public List<String> getAllServiceEnrollment_byServiceId(String service_id) {
     * String sql = "Select subject_id from service_enrollment where service_id='" +
     * service_id + "'";
     * // return jdbcTemplate.queryForMap(sql, userid);
     * return jdbcTemplate.queryForList(sql, String.class);
     * 
     * }
     */

    @Override
    public List<String> getAllServiceEnrollment_byServiceId_andSid(String service_id, String sid) {
        String sql = "Select subject_id from service_enrollment where service_id='" + service_id + "' and sid='" + sid
                + "'";
        // return jdbcTemplate.queryForMap(sql, userid);
        return jdbcTemplate.queryForList(sql, String.class);

    }

    @Override
    public List<Service> getAllServices() {
        // String sql = "select
        // name,subject_id,age,sex,occupation,zone_id,address,mobile,email from subject
        // where zone_id='"+zone_id+"'";
        String sql = "select * from service";
        // String service_id, String sname, String description, String start_date,
        // String end_date
        List<Service> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new Service(rs.getString("service_id"), rs.getString("sname"),
                        rs.getString("description"),
                        rs.getString("sid")));

        return result;

    }

    @Override
    public List<ServiceEnrollment> getAllServiceEnrollment_byServiceId(String service_id) {
        // String sql = "select
        // name,subject_id,age,sex,occupation,zone_id,address,mobile,email from subject
        // where zone_id='"+zone_id+"'";
        String sql = "select * from service_enrollment where service_id='" + service_id + "'";
        // service_id | subject_id | sid | start_date | end_date
        List<ServiceEnrollment> result = jdbcTemplate.query(sql,
                (rs, rowNum) -> new ServiceEnrollment(rs.getString("service_id"), rs.getString("subject_id"),
                        rs.getString("sid"),
                        rs.getString("start_date"), rs.getString("end_date")));

        return result;

    }

    public String genFieldId(String sid) {
        String sql = "select count(fid) from field_project where sid like '" + sid + "%'";
        // return jdbcTemplate.queryForObject(sql, String.class);
        String cnt = jdbcTemplate.queryForObject(sql, String.class);
        System.out.println("iSql= cnt " + cnt);

        String field_id = sid + "_f" + Integer.toString(Integer.parseInt(cnt) + 1);

        return field_id;
    }

    @Override
    public boolean createNewSurveyFields(Map<String, String> data) {
        int ans = 0;
        String required_value = "";
        if (data.get("attrreq").equalsIgnoreCase("true"))
            required_value = "1";
        else
            required_value = "0";

        String field_id = genFieldId(data.get("sid"));

        String query = "insert into field_project (name,fid,sid,source_type,attribute_name,attribute_datatype,attribute_unit,required_value) values "
                +
                "('','" + field_id + "','" + data.get("sid") + "','" + data.get("source_type") + "','"
                + data.get("attrname") + "','" + data.get("attrtype") + "','" + data.get("attrunit") + "','"
                + required_value + "')";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    @Override
    public boolean createAllocateSurveyor(Map<String, String> data) {

        String sid = data.get("sid");
        String userid = data.get("userid");

        String query = "insert into allocateSurveyor (sid,userid) values ('" + sid + "','" + userid + "')";

        String str = "";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    @Override
    public boolean createAllocateZone(Map<String, String> data) {
        String zone_id = data.get("zone_id");
        String userid = data.get("userid");

        String query = "insert into allocateZone (zone_id,userid) values ('" + zone_id + "','" + userid + "')";

        String str = "";

        try {
            jdbcTemplate.update(query);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    public boolean updateFieldEntry(Map<String, String> data) {

        try {

            String query = "update field_entry set value= ? where rid = ? and fid = ?";
            jdbcTemplate.update(query, data.get("value"), data.get("rid"), data.get("fid"));
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return false;
        }
        return true;

    }

    @Override
    public boolean createNewEdosthiLogin(Map<String, String> data) {
        String query = "INSERT INTO login "
                + "(uid, pwd, name, crtdate, rg_no, center, type, phone, active, available, referral, "
                + "verified, verifemail, verifphone, consent) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        return jdbcTemplate.update(
                query,
                data.get("uid"),
                data.get("pwd"),
                data.get("name"),
                data.get("crtdate"),
                data.get("rg_no"),
                data.get("center"),
                data.get("type"),
                data.get("phone"),
                data.get("active"),
                data.get("available"),
                data.get("referral"),
                data.get("verified"),
                data.get("verifemail"),
                data.get("verifphone"),
                data.get("consent")) > 0;

    }

    // Annotation pipeline job queue

    @Override
    public void enqueuePipelineJob(String patId) {
        jdbcTemplate.update(
                "INSERT INTO pipeline_jobs (pat_id, session_id, force_reannotate, status, created_at) VALUES (?, NULL, 0, 'pending', NOW())",
                patId);
    }

    @Override
    public void enqueuePipelineJob(String patId, String sessionId, boolean forceReannotate) {
        jdbcTemplate.update(
                "INSERT INTO pipeline_jobs (pat_id, session_id, force_reannotate, status, created_at) VALUES (?, ?, ?, 'pending', NOW())",
                patId, sessionId, forceReannotate ? 1 : 0);
    }

    @Override
    @Transactional
    public PipelineJob fetchAndLockNextPipelineJob() {
        String selectSql = "SELECT id, pat_id, session_id, force_reannotate FROM pipeline_jobs WHERE status = 'pending' "
                +
                "ORDER BY id ASC LIMIT 1 FOR UPDATE SKIP LOCKED";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(selectSql);
        if (rows.isEmpty()) {
            return null;
        }
        Map<String, Object> row = rows.get(0);
        Long id = ((Number) row.get("id")).longValue();
        String patId = (String) row.get("pat_id");
        String sessionId = (String) row.get("session_id");
        Object forceVal = row.get("force_reannotate");
        boolean force = (forceVal instanceof Boolean) ? (Boolean) forceVal : ((Number) forceVal).intValue() == 1;

        jdbcTemplate.update("UPDATE pipeline_jobs SET status = 'running', started_at = NOW() WHERE id = ?", id);

        return new PipelineJob(id, patId, sessionId, force);
    }

    @Override
    public void deleteSignalForReannotation(String patId, String sessionId) {
        String signalId = "SIG_" + patId.trim() + "_" + sessionId.trim();
        jdbcTemplate.update("DELETE FROM signal_history WHERE signal_id = ?", signalId);
    }

    @Override
    public void markPipelineJobCompleted(Long jobId) {
        jdbcTemplate.update("UPDATE pipeline_jobs SET status = 'completed', finished_at = NOW() WHERE id = ?", jobId);
    }

    @Override
    public void markPipelineJobFailed(Long jobId, String errorMessage) {
        jdbcTemplate.update(
                "UPDATE pipeline_jobs SET status = 'failed', finished_at = NOW(), error_message = ? WHERE id = ?",
                errorMessage, jobId);
    }

    @Override
    public void recoverStalePipelineJobs() {
        int recovered = jdbcTemplate
                .update("UPDATE pipeline_jobs SET status = 'pending', started_at = NULL WHERE status = 'running'");
        if (recovered > 0) {
            System.out
                    .println("Recovered " + recovered + " stale pipeline job(s) left in 'running' state after restart");
        }
    }

    @Override
    public Map<String, Object> getPipelineWindow() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT TIME_FORMAT(start_time, '%H:%i') AS start_time, TIME_FORMAT(end_time, '%H:%i') AS end_time " +
                        "FROM pipeline_settings WHERE id = 1");
        if (!rows.isEmpty()) {
            return rows.get(0);
        }
        Map<String, Object> defaults = new HashMap<>();
        defaults.put("start_time", "00:00");
        defaults.put("end_time", "02:00");
        return defaults;
    }

    @Override
    public void deleteOldCompletedPipelineJobs() {
        int deleted = jdbcTemplate.update(
                "DELETE FROM pipeline_jobs WHERE status IN ('completed', 'failed') AND finished_at < NOW() - INTERVAL 2 DAY");
        if (deleted > 0) {
            System.out.println("Deleted " + deleted + " pipeline job(s) completed/failed more than 2 days ago");
        }
    }

    @Override
    public void savePipelineWindow(String startTime, String endTime) {
        int rows = jdbcTemplate.update(
                "UPDATE pipeline_settings SET start_time = ?, end_time = ? WHERE id = 1", startTime, endTime);
        if (rows == 0) {
            jdbcTemplate.update(
                    "INSERT INTO pipeline_settings (id, start_time, end_time) VALUES (1, ?, ?)", startTime, endTime);
        }
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        try {
            // Drop old table to migrate schema correctly

            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS user_progress (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "userid VARCHAR(200) NOT NULL, " +
                    "item_id VARCHAR(255) NOT NULL, " +
                    "item_type VARCHAR(50) NOT NULL, " +
                    "open_count INT DEFAULT 1, " +
                    "last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                    "UNIQUE KEY uq_user_item (userid, item_id)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            System.out.println("Table user_progress created successfully without foreign key constraint.");

            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS user_time_app (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "userid VARCHAR(200) NOT NULL, " +
                    "timespent INT NOT NULL DEFAULT 0, " +
                    "`date` DATE NOT NULL, " +
                    "UNIQUE KEY uk_userid_date (userid, `date`)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            System.out.println("Table user_time_app created successfully.");
        } catch (Exception e) {
            System.out.println("Error initializing tables: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public boolean incrementOpenCount(String userid, String itemId, String itemType) {
        String sql = "INSERT INTO user_progress (userid, item_id, item_type, open_count) " +
                "VALUES (?, ?, ?, 1) " +
                "ON DUPLICATE KEY UPDATE " +
                "open_count = open_count + 1";
        try {
            int rows = jdbcTemplate.update(sql, userid, itemId, itemType);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("Error incrementing open count: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public Map<String, Object> getProgress(String userid, String itemId) {
        String sql = "SELECT * FROM user_progress WHERE userid = ? AND item_id = ?";
        try {
            return jdbcTemplate.queryForMap(sql, userid, itemId);
        } catch (Exception e) {
            return Collections.emptyMap();
        }
    }

    @Override
    public List<Map<String, Object>> getAllProgress(String userid) {
        String sql = "SELECT * FROM user_progress WHERE userid = ?";
        try {
            return jdbcTemplate.queryForList(sql, userid);
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    @Override
    public boolean logUserTime(String userid, int timespent, String date) {
        String sql = "INSERT INTO user_time_app (userid, timespent, `date`) VALUES (?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE timespent = timespent + ?";
        try {
            int rows = jdbcTemplate.update(sql, userid, timespent, date, timespent);
            return rows > 0;
        } catch (Exception e) {
            System.out.println("Error logging user time: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean setupDb() {
        try {
            jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS user_time_app (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "userid VARCHAR(200) NOT NULL, " +
                    "timespent INT NOT NULL DEFAULT 0, " +
                    "`date` DATE NOT NULL, " +
                    "UNIQUE KEY uk_userid_date (userid, `date`)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            System.out.println("Table user_time_app created successfully via setupDb.");
            return true;
        } catch (Exception e) {
            System.out.println("Error in setupDb: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

}

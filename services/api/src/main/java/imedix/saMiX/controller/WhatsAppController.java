// Author Sayantan Patra

package imedix.saMiX.controller;

import imedix.saMiX.model.WhatsAppLog;
import imedix.saMiX.service.WhatsAppService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/whatsapp")
public class WhatsAppController {

    @Autowired
    private WhatsAppService whatsappService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${imedix.whatsapp.verify-token:change-me}")
    private String verifyToken;

    @GetMapping("/logs")
    public ResponseEntity<?> getLogs(@RequestParam("uid") String uid) {
        if (uid == null || uid.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing uid");
            return ResponseEntity.badRequest().body(error);
        }
        try {
            List<WhatsAppLog> logs = whatsappService.getLogsByUid(uid);
            return ResponseEntity.ok(logs);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/send")
    public ResponseEntity<?> sendNotification(
            @RequestParam("uid") String uid,
            @RequestParam(value = "messageType", defaultValue = "default") String messageType,
            @RequestParam(value = "customMessage", required = false) String customMessage) {

        if (uid == null || uid.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing uid");
            return ResponseEntity.badRequest().body(error);
        }

        try {
            // Retrieve user/patient info from the login table and med table
            String sql = "SELECT l.name, l.phone, l.type, m.class FROM login l LEFT JOIN med m ON l.uid = m.pat_id WHERE l.uid = ?";
            List<Map<String, Object>> users = jdbcTemplate.queryForList(sql, uid);

            if (users.isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "User not found in login table");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
            }

            Map<String, Object> user = users.get(0);
            String name = (String) user.get("name");
            String phone = (String) user.get("phone");
            String type = (String) user.get("type");
            String category = (String) user.get("class");
            if (category == null)
                category = "General";

            if (phone == null || phone.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "User does not have a phone number registered");
                return ResponseEntity.badRequest().body(error);
            }

            String serviceResult;
            String loggedMessage;

            if ("custom".equalsIgnoreCase(messageType)) {
                if (customMessage == null || customMessage.trim().isEmpty()) {
                    Map<String, String> error = new HashMap<>();
                    error.put("error", "Custom message text is empty");
                    return ResponseEntity.badRequest().body(error);
                }
                serviceResult = whatsappService.sendMessage(phone, customMessage);
                loggedMessage = customMessage;
            } else if ("bengali".equalsIgnoreCase(messageType)) {
                serviceResult = whatsappService.sendBengaliNotification(phone, name);
                loggedMessage = "হ্যালো " + name
                        + "!\n\nM-DOSTHI এপ্লিকেশন টি ব্যবহার করার জন্য অনুরোধ রইল। মানসিক স্বাস্থ্য সম্পর্কিত সহায়তা পেতে চ্যাট এ অংশগ্রহণ করুন, ভিডিও দেখুন এবং পরীক্ষাগুলো সম্পন্ন করুন।\n\nআপনার অংশগ্রহণ ও সহযোগিতার জন্য আন্তরিক ধন্যবাদ!\nM-DOSTHI";
            } else {
                serviceResult = whatsappService.sendNotification(
                        phone,
                        name,
                        category,
                        "ACTIVE" // default queue status
                );
                loggedMessage = "Hello " + name
                        + ",\n\nThis is a gentle reminder to use the app regularly and complete your activities/tasks for today. Consistent usage will help you get the best experience and benefits from the application.\n\nThank you for your participation and support!\n\nRegards,\nM-DOSTHI";
            }

            String status = "FAILED";
            String msgId = null;
            if (serviceResult != null && serviceResult.startsWith("SUCCESS")) {
                status = "SUCCESS";
                if (serviceResult.contains(":")) {
                    msgId = serviceResult.substring(serviceResult.indexOf(":") + 1);
                }
                whatsappService.updateWaSentFlag(uid, 1);
            } else {
                status = serviceResult;
            }

            // Log status to DB
            whatsappService.logMessage(uid, phone, loggedMessage, status, msgId, messageType);

            checkAndResetRotationIfComplete(messageType);

            Map<String, String> response = new HashMap<>();
            response.put("status", status);
            response.put("message", loggedMessage);
            response.put("phone", phone);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/bulk")
    public ResponseEntity<?> sendBulkNotification(
            @RequestParam("uids") String uidsParam,
            @RequestParam(value = "messageType", defaultValue = "default") String messageType,
            @RequestParam(value = "customMessage", required = false) String customMessage) {

        if (uidsParam == null || uidsParam.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing uids");
            return ResponseEntity.badRequest().body(error);
        }

        String[] uids = uidsParam.split(",");
        int successCount = 0;
        int failureCount = 0;

        for (String uid : uids) {
            uid = uid.trim();
            if (uid.isEmpty())
                continue;

            try {
                String sql = "SELECT l.name, l.phone, m.class FROM login l LEFT JOIN med m ON l.uid = m.pat_id WHERE l.uid = ? AND l.dpdp_agreed = 1 AND l.type = 'PAT'";
                List<Map<String, Object>> users = jdbcTemplate.queryForList(sql, uid);

                if (!users.isEmpty()) {
                    Map<String, Object> user = users.get(0);
                    String name = (String) user.get("name");
                    String phone = (String) user.get("phone");
                    String category = (String) user.get("class");
                    if (category == null)
                        category = "General";

                    if (phone != null && !phone.trim().isEmpty()) {
                        String serviceResult;
                        String loggedMessage;

                        if ("custom".equalsIgnoreCase(messageType)) {
                            serviceResult = whatsappService.sendMessage(phone, customMessage);
                            loggedMessage = customMessage;
                        } else if ("bengali".equalsIgnoreCase(messageType)) {
                            serviceResult = whatsappService.sendBengaliNotification(phone, name);
                            loggedMessage = "হ্যালো " + name
                                    + "!\n\nM-DOSTHI এপ্লিকেশন টি ব্যবহার করার জন্য অনুরোধ রইল। মানসিক স্বাস্থ্য সম্পর্কিত সহায়তা পেতে চ্যাট এ অংশগ্রহণ করুন, ভিডিও দেখুন এবং পরীক্ষাগুলো সম্পন্ন করুন।\n\nআপনার অংশগ্রহণ ও সহযোগিতার জন্য আন্তরিক ধন্যবাদ!\nM-DOSTHI";
                        } else {
                            serviceResult = whatsappService.sendNotification(phone, name, category, "ACTIVE");
                            loggedMessage = "Hello " + name
                                    + ",\n\nThis is a gentle reminder to use the app regularly and complete your activities/tasks for today. Consistent usage will help you get the best experience and benefits from the application.\n\nThank you for your participation and support!\n\nRegards,\nM-DOSTHI";
                        }

                        String status = "FAILED";
                        String msgId = null;
                        if (serviceResult != null && serviceResult.startsWith("SUCCESS")) {
                            status = "SUCCESS";
                            if (serviceResult.contains(":")) {
                                msgId = serviceResult.substring(serviceResult.indexOf(":") + 1);
                            }
                            whatsappService.updateWaSentFlag(uid, 1);
                        } else {
                            status = serviceResult;
                        }

                        whatsappService.logMessage(uid, phone, loggedMessage, status, msgId, messageType, "bulk");

                        if ("SUCCESS".equalsIgnoreCase(status)) {
                            successCount++;
                        } else {
                            failureCount++;
                        }
                    } else {
                        failureCount++;
                    }
                } else {
                    failureCount++;
                }
            } catch (Exception e) {
                failureCount++;
            }
        }

        checkAndResetRotationIfComplete(messageType);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "SUCCESS");
        response.put("total", uids.length);
        response.put("successful", successCount);
        response.put("failed", failureCount);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/all-logs")
    public ResponseEntity<?> getAllLogs(
            @RequestParam(value = "search", required = false) String search,
            @RequestParam(value = "limit", defaultValue = "500") int limit) {
        try {
            String sql = "SELECT wl.*, l.name FROM whatsapp_logs wl LEFT JOIN login l ON wl.uid = l.uid";
            List<Object> params = new ArrayList<>();
            if (search != null && !search.trim().isEmpty()) {
                sql += " WHERE wl.uid LIKE ? OR wl.phone LIKE ? OR l.name LIKE ? OR wl.message LIKE ?";
                String searchLike = "%" + search.trim() + "%";
                params.add(searchLike);
                params.add(searchLike);
                params.add(searchLike);
                params.add(searchLike);
            }
            sql += " ORDER BY wl.sent_at DESC LIMIT ?";
            params.add(limit);

            List<Map<String, Object>> logs = jdbcTemplate.queryForList(sql, params.toArray());
            return ResponseEntity.ok(logs);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/rotation-status")
    public ResponseEntity<?> getRotationStatus(
            @RequestParam("messageType") String messageType,
            @RequestParam(value = "ccode", required = false) String ccode) {
        try {
            // Count total patients in queue
            String countAllSql = "SELECT COUNT(DISTINCT lp.pat_id) " +
                    "FROM lpatq lp " +
                    "INNER JOIN med m ON lp.pat_id = m.pat_id " +
                    "INNER JOIN login l ON lp.pat_id = l.uid " +
                    "WHERE UPPER(lp.delflag) = 'N' AND l.dpdp_agreed = 1 AND l.type = 'PAT'";

            List<Object> countAllParams = new ArrayList<>();
            if (ccode != null && !ccode.trim().isEmpty() && !ccode.equalsIgnoreCase("XXXX")) {
                countAllSql += " AND (UPPER(m.referring_doctor) LIKE ? OR UPPER(lp.pat_id) LIKE ?)";
                countAllParams.add("DOC" + ccode.toUpperCase() + "%");
                countAllParams.add(ccode.toUpperCase() + "%");
            }
            int totalPatients = jdbcTemplate.queryForObject(countAllSql, Integer.class, countAllParams.toArray());

            // Get current rotation reset time
            java.sql.Timestamp lastReset = whatsappService.getOrCreateRotationReset(messageType);

            // Count remaining candidates in current rotation
            String countRemainingSql = "SELECT COUNT(DISTINCT lp.pat_id) " +
                    "FROM lpatq lp " +
                    "INNER JOIN med m ON lp.pat_id = m.pat_id " +
                    "INNER JOIN login l ON lp.pat_id = l.uid " +
                    "WHERE UPPER(lp.delflag) = 'N' AND l.dpdp_agreed = 1 AND l.type = 'PAT' " +
                    "AND (l.wa_sent = 0 OR l.wa_sent IS NULL)";

            List<Object> countRemainingParams = new ArrayList<>();

            if (ccode != null && !ccode.trim().isEmpty() && !ccode.equalsIgnoreCase("XXXX")) {
                countRemainingSql += " AND (UPPER(m.referring_doctor) LIKE ? OR UPPER(lp.pat_id) LIKE ?)";
                countRemainingParams.add("DOC" + ccode.toUpperCase() + "%");
                countRemainingParams.add(ccode.toUpperCase() + "%");
            }
            int remainingPatients = jdbcTemplate.queryForObject(countRemainingSql, Integer.class,
                    countRemainingParams.toArray());

            if (remainingPatients == 0 && totalPatients > 0) {
                whatsappService.resetWaSentFlag();
                remainingPatients = jdbcTemplate.queryForObject(countRemainingSql, Integer.class,
                        countRemainingParams.toArray());
            }

            Map<String, Object> statusObj = new HashMap<>();
            statusObj.put("totalPatients", totalPatients);
            statusObj.put("remainingPatients", remainingPatients);
            statusObj.put("lastReset", lastReset.toString());
            statusObj.put("rotationComplete", remainingPatients == 0);

            return ResponseEntity.ok(statusObj);

        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/broadcast-batch")
    public ResponseEntity<?> broadcastBatch(
            @RequestParam("limit") int limit,
            @RequestParam(value = "messageType", defaultValue = "default") String messageType,
            @RequestParam(value = "ccode", required = false) String ccode) {

        if (limit < 1 || limit > 200) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Limit must be between 1 and 200");
            return ResponseEntity.badRequest().body(error);
        }

        try {
            // 2. Count remaining eligible candidates in this rotation
            String countRemainingSql = "SELECT COUNT(DISTINCT lp.pat_id) " +
                    "FROM lpatq lp " +
                    "INNER JOIN med m ON lp.pat_id = m.pat_id " +
                    "INNER JOIN login l ON lp.pat_id = l.uid " +
                    "WHERE UPPER(lp.delflag) = 'N' AND l.dpdp_agreed = 1 AND l.type = 'PAT' " +
                    "AND (l.wa_sent = 0 OR l.wa_sent IS NULL)";

            List<Object> countRemainingParams = new ArrayList<>();

            if (ccode != null && !ccode.trim().isEmpty() && !ccode.equalsIgnoreCase("XXXX")) {
                countRemainingSql += " AND (UPPER(m.referring_doctor) LIKE ? OR UPPER(lp.pat_id) LIKE ?)";
                countRemainingParams.add("DOC" + ccode.toUpperCase() + "%");
                countRemainingParams.add(ccode.toUpperCase() + "%");
            }

            int remainingCount = jdbcTemplate.queryForObject(countRemainingSql, Integer.class,
                    countRemainingParams.toArray());

            boolean rotationJustReset = false;
            if (remainingCount == 0) {
                // 3. Rotation complete, auto-refresh/reset rotation!
                whatsappService.resetWaSentFlag();
                rotationJustReset = true;
                System.out.println(
                        "DEBUG: WhatsApp rotation completed. Auto-refreshing batch.");
            }

            // 4. Query candidates
            String sql = "SELECT DISTINCT lp.pat_id, l.phone, l.name, m.class, lp.entrydate " +
                    "FROM lpatq lp " +
                    "INNER JOIN med m ON lp.pat_id = m.pat_id " +
                    "INNER JOIN login l ON lp.pat_id = l.uid " +
                    "WHERE UPPER(lp.delflag) = 'N' AND l.dpdp_agreed = 1 AND l.type = 'PAT' " +
                    "AND (l.wa_sent = 0 OR l.wa_sent IS NULL)";

            List<Object> params = new ArrayList<>();

            if (ccode != null && !ccode.trim().isEmpty() && !ccode.equalsIgnoreCase("XXXX")) {
                sql += " AND (UPPER(m.referring_doctor) LIKE ? OR UPPER(lp.pat_id) LIKE ?)";
                params.add("DOC" + ccode.toUpperCase() + "%");
                params.add(ccode.toUpperCase() + "%");
            }

            sql += " ORDER BY lp.entrydate DESC";

            List<Map<String, Object>> candidates = jdbcTemplate.queryForList(sql, params.toArray());

            int successCount = 0;
            int failureCount = 0;
            int invalidPhoneCount = 0;
            List<Map<String, String>> details = new ArrayList<>();

            for (Map<String, Object> candidate : candidates) {
                if (successCount >= limit) {
                    break;
                }

                String uid = (String) candidate.get("pat_id");
                String name = (String) candidate.get("name");
                String phone = (String) candidate.get("phone");
                String category = (String) candidate.get("class");
                if (category == null)
                    category = "General";

                Map<String, String> detail = new HashMap<>();
                detail.put("uid", uid);
                detail.put("name", name);
                detail.put("phone", phone);

                if (!isValidPhoneNumber(phone)) {
                    invalidPhoneCount++;
                    detail.put("status", "SKIPPED_INVALID_PHONE");
                    details.add(detail);
                    continue;
                }

                String serviceResult;
                String loggedMessage;

                if ("bengali".equalsIgnoreCase(messageType)) {
                    serviceResult = whatsappService.sendBengaliNotification(phone, name);
                    loggedMessage = "হ্যালো " + name
                            + "!\n\nM-DOSTHI এপ্লিকেশন টি ব্যবহার করার জন্য অনুরোধ রইল। মানসিক স্বাস্থ্য সম্পর্কিত সহায়তা পেতে চ্যাট এ অংশগ্রহণ করুন, ভিডিও দেখুন এবং পরীক্ষাগুলো সম্পন্ন করুন।\n\nআপনার অংশগ্রহণ ও সহযোগিতার জন্য আন্তরিক ধন্যবাদ!\nM-DOSTHI";
                } else {
                    serviceResult = whatsappService.sendNotification(phone, name, category, "ACTIVE");
                    loggedMessage = "Hello " + name
                            + ",\n\nThis is a gentle reminder to use the app regularly and complete your activities/tasks for today. Consistent usage will help you get the best experience and benefits from the application.\n\nThank you for your participation and support!\n\nRegards,\nM-DOSTHI";
                }

                String status = "FAILED";
                String msgId = null;
                if (serviceResult != null && serviceResult.startsWith("SUCCESS")) {
                    status = "SUCCESS";
                    if (serviceResult.contains(":")) {
                        msgId = serviceResult.substring(serviceResult.indexOf(":") + 1);
                    }
                    successCount++;
                    whatsappService.updateWaSentFlag(uid, 1);
                } else {
                    status = serviceResult;
                    failureCount++;
                }

                whatsappService.logMessage(uid, phone, loggedMessage, status, msgId, messageType, "rotation");

                detail.put("status", status);
                details.add(detail);
            }

            // Check if this run completed the new rotation
            boolean currentRotationCompleted = false;
            int newRemainingCount = jdbcTemplate.queryForObject(countRemainingSql, Integer.class,
                    countRemainingParams.toArray());
            if (newRemainingCount == 0) {
                currentRotationCompleted = true;
                whatsappService.resetWaSentFlag();
                System.out.println("DEBUG: WhatsApp rotation completed after this broadcast. Auto-refreshing batch.");
            }

            Map<String, Object> responseData = new HashMap<>();
            responseData.put("status", "SUCCESS");
            responseData.put("totalCandidates", candidates.size());
            responseData.put("limit", limit);
            responseData.put("successful", successCount);
            responseData.put("failed", failureCount);
            responseData.put("invalidPhone", invalidPhoneCount);
            responseData.put("rotationReset", rotationJustReset);
            responseData.put("rotationCompletedAfterSend", currentRotationCompleted);
            responseData.put("details", details);

            return ResponseEntity.ok(responseData);

        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    private boolean isValidPhoneNumber(String phone) {
        if (phone == null)
            return false;
        String clean = phone.replaceAll("[^0-9]", "");
        if (clean.length() < 10)
            return false;
        if (clean.matches("0+"))
            return false;
        return true;
    }

    @PostMapping("/send-otp-direct")
    public ResponseEntity<?> sendOtpDirect(
            @RequestParam("phone") String phone,
            @RequestParam("message") String message) {
        if (phone == null || phone.trim().isEmpty() || message == null || message.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing phone or message");
            return ResponseEntity.badRequest().body(error);
        }
        try {
            String serviceResult = whatsappService.sendOtp(phone, message);
            String status = "FAILED";
            if (serviceResult != null && serviceResult.startsWith("SUCCESS")) {
                status = "SUCCESS";
            } else {
                status = serviceResult;
            }
            Map<String, String> response = new HashMap<>();
            response.put("status", status);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/webhook")
    public ResponseEntity<String> verifyWebhook(
            @RequestParam(value = "hub.mode", required = false) String mode,
            @RequestParam(value = "hub.verify_token", required = false) String token,
            @RequestParam(value = "hub.challenge", required = false) String challenge) {

        if ("subscribe".equals(mode) && verifyToken.equals(token)) {
            System.out.println("DEBUG: Webhook verified successfully.");
            return ResponseEntity.ok(challenge);
        } else {
            System.err.println("DEBUG: Webhook verification failed.");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Verification failed");
        }
    }

    @PostMapping("/webhook")
    public ResponseEntity<Void> receiveMessage(@RequestBody String jsonPayload) {
        System.out.println("DEBUG: Webhook payload received: " + jsonPayload);
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(jsonPayload);

            if (root.has("entry")) {
                for (com.fasterxml.jackson.databind.JsonNode entry : root.get("entry")) {
                    if (entry.has("changes")) {
                        for (com.fasterxml.jackson.databind.JsonNode change : entry.get("changes")) {
                            com.fasterxml.jackson.databind.JsonNode value = change.get("value");
                            if (value != null) {
                                // 1. Handle incoming messages
                                if (value.has("messages")) {
                                    for (com.fasterxml.jackson.databind.JsonNode msg : value.get("messages")) {
                                        String from = msg.has("from") ? msg.get("from").asText() : null;
                                        String body = null;
                                        if (msg.has("text") && msg.get("text").has("body")) {
                                            body = msg.get("text").get("body").asText();
                                        }
                                        if (from != null && body != null) {
                                            System.out.println("DEBUG: Incoming WhatsApp from " + from + ": " + body);
                                            whatsappService.logIncomingMessage(from, body);
                                        }
                                    }
                                }

                                // 2. Handle status updates
                                if (value.has("statuses")) {
                                    for (com.fasterxml.jackson.databind.JsonNode statusNode : value.get("statuses")) {
                                        String msgId = statusNode.has("id") ? statusNode.get("id").asText() : null;
                                        String status = statusNode.has("status") ? statusNode.get("status").asText()
                                                : null;
                                        if (msgId != null && status != null) {
                                            System.out.println("DEBUG: WhatsApp status update. MsgId: " + msgId
                                                    + ", Status: " + status);
                                            whatsappService.updateMessageStatus(msgId, status);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("ERROR: Failed to parse webhook payload: " + e.getMessage());
            e.printStackTrace();
        }

        return ResponseEntity.ok().build();
    }

    private String extractJsonValue(String json, String key) {
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"");
        java.util.regex.Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    private String unescapeJson(String str) {
        if (str == null)
            return "";
        return str.replace("\\\\", "\\")
                .replace("\\\"", "\"")
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("\\t", "\t");
    }

    @GetMapping("/config")
    // Added config lookup endpoint
    public ResponseEntity<?> getConfig(@RequestParam("key") String key) {
        if (key == null || key.trim().isEmpty()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing key");
            return ResponseEntity.badRequest().body(error);
        }
        try {
            String value = whatsappService.getConfig(key, "");
            Map<String, String> response = new HashMap<>();
            response.put("key", key);
            response.put("value", value);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/config")
    public ResponseEntity<?> setConfig(@RequestParam("key") String key, @RequestParam("value") String value) {
        if (key == null || key.trim().isEmpty() || value == null) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Missing key or value");
            return ResponseEntity.badRequest().body(error);
        }
        try {
            whatsappService.setConfig(key, value.trim());
            Map<String, String> response = new HashMap<>();
            response.put("status", "SUCCESS");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    private void checkAndResetRotationIfComplete(String messageType) {
        try {
            String countRemainingSql = "SELECT COUNT(DISTINCT lp.pat_id) " +
                    "FROM lpatq lp " +
                    "INNER JOIN med m ON lp.pat_id = m.pat_id " +
                    "INNER JOIN login l ON lp.pat_id = l.uid " +
                    "WHERE UPPER(lp.delflag) = 'N' AND l.dpdp_agreed = 1 AND l.type = 'PAT' " +
                    "AND (l.wa_sent = 0 OR l.wa_sent IS NULL)";
            int remainingCount = jdbcTemplate.queryForObject(countRemainingSql, Integer.class);
            if (remainingCount == 0) {
                whatsappService.resetWaSentFlag();
                System.out.println("DEBUG: WhatsApp rotation completed. Resetting wa_sent flags.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
<%@page contentType="application/json"
        import="java.sql.*,java.io.*,java.net.*,java.util.*,
                org.json.simple.JSONObject,org.json.simple.JSONArray,
                org.json.simple.parser.JSONParser"%>
<%@include file="whatsappConfig.jsp"%>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject result = new JSONObject();

// ── Parameters ──────────────────────────────────────────────────────────────
// pat_ids  : comma-separated patient IDs          (always required)
// template : WhatsApp template name               (use for template mode)
// message  : free-form text body                  (use for custom text mode)
// var2..var4: optional extra template variables
String patIdsParam   = request.getParameter("pat_ids");
String templateName  = request.getParameter("template");
String customMessage = request.getParameter("message");

boolean isTemplate = (templateName  != null && !templateName.trim().isEmpty());
boolean isText     = (customMessage != null && !customMessage.trim().isEmpty());

if (patIdsParam == null || patIdsParam.trim().isEmpty()) {
    result.put("success", false);
    result.put("message", "pat_ids is required");
    out.print(result.toJSONString());
    return;
}
if (!isTemplate && !isText) {
    result.put("success", false);
    result.put("message", "Either template or message is required");
    out.print(result.toJSONString());
    return;
}

// Template variables (var2-var4; var1 is auto-filled with patient name)
String[] vars = new String[4];
for (int i = 1; i <= 4; i++) vars[i-1] = request.getParameter("var" + i);

String[] patIds = patIdsParam.split(",");
JSONArray sent   = new JSONArray();
JSONArray failed = new JSONArray();

Connection conn = null;
try {
    String dbURL = System.getenv("LEGACY_DB_URL") != null ? System.getenv("LEGACY_DB_URL")
        : "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8";
    String dbUser = System.getenv("LEGACY_DB_USERNAME") != null ? System.getenv("LEGACY_DB_USERNAME") : "root";
    String dbPass = System.getenv("LEGACY_DB_PASSWORD") != null ? System.getenv("LEGACY_DB_PASSWORD") : "";
    try {
        File webappDir = new File(request.getRealPath("/"));
        File repoRoot = webappDir.getParentFile().getParentFile();
        File blInf = new File(repoRoot, "services/legacy/runtime/gblinfo.inf");
        if (!blInf.exists()) blInf = new File(repoRoot, "M-Dosthi-BL/gblinfo.inf");
        if (blInf.exists()) {
            try (BufferedReader br = new BufferedReader(new FileReader(blInf))) {
                String cfgLine;
                while ((cfgLine = br.readLine()) != null) {
                    int eq = cfgLine.indexOf('=');
                    if (eq > 0) {
                        String k = cfgLine.substring(0, eq).trim().toLowerCase();
                        String v = cfgLine.substring(eq + 1).trim();
                        if ("gbldburl".equals(k) && System.getenv("LEGACY_DB_URL") == null) dbURL = v;
                        else if ("gbldbusername".equals(k) && System.getenv("LEGACY_DB_USERNAME") == null) dbUser = v;
                        else if ("gbldbpasswd".equals(k) && System.getenv("LEGACY_DB_PASSWORD") == null) dbPass = v;
                    }
                }
            }
        }
    } catch (Exception ignored) {}
    Class.forName("com.mysql.cj.jdbc.Driver");
    conn = DriverManager.getConnection(dbURL, dbUser, dbPass);

    String placeholders = String.join(",", Collections.nCopies(patIds.length, "?"));
    PreparedStatement ps = conn.prepareStatement(
        "SELECT uid, name, phone FROM login WHERE uid IN (" + placeholders + ")");
    for (int i = 0; i < patIds.length; i++) ps.setString(i + 1, patIds[i].trim());
    ResultSet rs = ps.executeQuery();

    PreparedStatement logStmt = conn.prepareStatement(
        "INSERT INTO whatsapp_logs (pat_id, message_id, phone, template_name, status, error_msg, sent_at) " +
        "VALUES (?, ?, ?, ?, ?, ?, NOW())");

    while (rs.next()) {
        String patId    = rs.getString("uid");
        String name     = rs.getString("name");
        String rawPhone = rs.getString("phone");

        if (rawPhone == null || rawPhone.trim().isEmpty()) {
            JSONObject f = new JSONObject();
            f.put("pat_id", patId); f.put("reason", "no phone number");
            failed.add(f);
            continue;
        }

        // Normalise to E.164 — prepend 91 for bare 10-digit Indian numbers
        String phone = rawPhone.replaceAll("[^0-9]", "");
        if (phone.length() == 10) phone = "91" + phone;

        // ── Build API payload ──────────────────────────────────────────
        JSONObject body = new JSONObject();
        body.put("messaging_product", "whatsapp");
        body.put("to", phone);

        String loggedTemplateName;

        if (isTemplate) {
            // Template message
            loggedTemplateName = templateName;
            body.put("type", "template");

            JSONObject tmpl = new JSONObject();
            tmpl.put("name", templateName);
            JSONObject lang = new JSONObject(); lang.put("code", WA_TEMPLATE_LANG);
            tmpl.put("language", lang);

            JSONArray components = new JSONArray();
            JSONArray parameters = new JSONArray();
            String nameParam = (vars[0] != null) ? vars[0] : (name != null ? name : "");
            JSONObject p1 = new JSONObject(); p1.put("type", "text"); p1.put("text", nameParam);
            parameters.add(p1);
            for (int i = 1; i < 4; i++) {
                if (vars[i] != null) {
                    JSONObject pN = new JSONObject(); pN.put("type", "text"); pN.put("text", vars[i]);
                    parameters.add(pN);
                }
            }
            if (!parameters.isEmpty()) {
                JSONObject bodyComp = new JSONObject();
                bodyComp.put("type", "body");
                bodyComp.put("parameters", parameters);
                components.add(bodyComp);
                tmpl.put("components", components);
            }
            body.put("template", tmpl);

        } else {
            // Free-form text message (requires active 24-hour conversation window)
            loggedTemplateName = "custom_text";
            body.put("type", "text");
            JSONObject textObj = new JSONObject();
            textObj.put("body", customMessage.trim());
            body.put("text", textObj);
        }

        // ── Call Graph API ─────────────────────────────────────────────
        String apiUrl    = WA_API_BASE + "/" + WA_PHONE_NUMBER_ID + "/messages";
        String statusStr = "failed";
        String errorMsg  = null;

        try {
            URL url = new URL(apiUrl);
            HttpURLConnection http = (HttpURLConnection) url.openConnection();
            http.setRequestMethod("POST");
            http.setDoOutput(true);
            http.setRequestProperty("Content-Type", "application/json");
            http.setRequestProperty("Authorization", "Bearer " + WA_ACCESS_TOKEN);
            http.setConnectTimeout(10000);
            http.setReadTimeout(15000);

            try (OutputStream os = http.getOutputStream()) {
                os.write(body.toJSONString().getBytes("UTF-8"));
            }

            int code = http.getResponseCode();
            InputStream is = (code >= 200 && code < 300) ? http.getInputStream() : http.getErrorStream();
            StringBuilder resp = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"))) {
                String line; while ((line = br.readLine()) != null) resp.append(line);
            }

            if (code == 200) {
                statusStr = "sent";
                // Extract wamid from response: {"messages":[{"id":"wamid.xxx"}]}
                try {
                    JSONObject apiResp = (JSONObject) new JSONParser().parse(resp.toString());
                    JSONArray msgs = (JSONArray) apiResp.get("messages");
                    if (msgs != null && !msgs.isEmpty()) {
                        errorMsg = (String) ((JSONObject) msgs.get(0)).get("id"); // reuse field to store wamid
                    }
                } catch (Exception ignored) {}
                JSONObject s = new JSONObject();
                s.put("pat_id", patId); s.put("phone", phone);
                sent.add(s);
            } else {
                errorMsg = "HTTP " + code + ": " + resp.toString();
                JSONObject f = new JSONObject();
                f.put("pat_id", patId); f.put("reason", errorMsg);
                failed.add(f);
            }
        } catch (Exception e) {
            errorMsg = e.getMessage();
            JSONObject f = new JSONObject();
            f.put("pat_id", patId); f.put("reason", errorMsg);
            failed.add(f);
        }

        // ── Log result ─────────────────────────────────────────────────
        // For sent messages, errorMsg holds the wamid temporarily; clear it after
        String wamid    = "sent".equals(statusStr) ? errorMsg : null;
        String finalErr = "sent".equals(statusStr) ? null     : errorMsg;
        logStmt.setString(1, patId);
        logStmt.setString(2, wamid);
        logStmt.setString(3, phone);
        logStmt.setString(4, loggedTemplateName);
        logStmt.setString(5, statusStr);
        logStmt.setString(6, finalErr);
        logStmt.addBatch();
    }

    rs.close(); ps.close();
    logStmt.executeBatch();
    logStmt.close();

} catch (Exception e) {
    result.put("success", false);
    result.put("message", "DB error: " + e.getMessage());
    out.print(result.toJSONString());
    return;
} finally {
    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
}

result.put("success",      true);
result.put("sent_count",   sent.size());
result.put("failed_count", failed.size());
result.put("sent",   sent);
result.put("failed", failed);
out.print(result.toJSONString());
%>

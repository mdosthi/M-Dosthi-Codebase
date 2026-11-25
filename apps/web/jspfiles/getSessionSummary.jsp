<%@page contentType="application/json" import="imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.JSONArray" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

String sessionId = request.getParameter("session_id");
String patId     = request.getParameter("pat_id");

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));

    // ── Single session lookup (for per-row View button) ──────────────
    if (sessionId != null && !sessionId.trim().isEmpty()) {
        Object result = rd.getSessionSummaryBySessionId(sessionId.trim());

        if (result instanceof Vector && ((Vector) result).size() > 0) {
            dataobj d = (dataobj) ((Vector) result).get(0);
            JSONObject row = new JSONObject();
            row.put("session_id",      d.getValue("session_id"));
            row.put("session_date",    d.getValue("session_date"));
            row.put("start_time",      d.getValue("start_time"));
            row.put("session_summary", d.getValue("session_summary"));
            row.put("readiness",       d.getValue("readiness"));
            row.put("concerns",        d.getValue("concerns"));
            row.put("triggers",        d.getValue("triggers"));
            row.put("advice",          d.getValue("advice"));
            row.put("quit_history",       d.getValue("quit_history"));
            row.put("suicidal_ideation",  "1".equals(d.getValue("suicidal_ideation")));

            jsonResponse.put("success", true);
            jsonResponse.put("session", row);
        } else {
            // No annotation yet — pipeline still running
            jsonResponse.put("success", false);
            jsonResponse.put("message", "processing");
        }

    // ── All sessions for a patient ───────────────────────────────────
    } else if (patId != null && !patId.trim().isEmpty()) {
        Object result = rd.getSessionSummaryByPatId(patId.trim());

        JSONArray sessions = new JSONArray();
        if (result instanceof Vector) {
            Vector resultVector = (Vector) result;
            for (int i = 0; i < resultVector.size(); i++) {
                dataobj d = (dataobj) resultVector.get(i);
                JSONObject row = new JSONObject();
                row.put("session_id",      d.getValue("session_id"));
                row.put("session_date",    d.getValue("session_date"));
                row.put("start_time",      d.getValue("start_time"));
                row.put("session_summary", d.getValue("session_summary"));
                row.put("readiness",       d.getValue("readiness"));
                row.put("concerns",        d.getValue("concerns"));
                row.put("triggers",        d.getValue("triggers"));
                row.put("advice",          d.getValue("advice"));
                row.put("quit_history",       d.getValue("quit_history"));
                row.put("suicidal_ideation",  "1".equals(d.getValue("suicidal_ideation")));
                sessions.add(row);
            }
        }

        jsonResponse.put("success",  true);
        jsonResponse.put("sessions", sessions);
        jsonResponse.put("total",    sessions.size());

    } else {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "session_id or pat_id is required");
    }

} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Error: " + e.getMessage());
    System.out.println("ERROR - getSessionSummary: " + e.getMessage());
}

out.print(jsonResponse.toJSONString());
%>

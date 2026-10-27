<%@page contentType="application/json" import="imedix.rcDisplayData,imedix.dataobj,java.util.*,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
String sessionId = request.getParameter("session_id");

if (sessionId == null || sessionId.trim().isEmpty()) {
    r.put("success", false);
    r.put("message", "session_id required");
    out.print(r.toJSONString());
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    Object result = rd.getSessionDeltaByToSessionId(sessionId.trim());

    if (result instanceof Vector && ((Vector) result).size() > 0) {
        dataobj rec = (dataobj) ((Vector) result).get(0);
        JSONObject d = new JSONObject();
        d.put("from_session_id",      rec.getValue("from_session_id"));
        d.put("to_session_id",        rec.getValue("to_session_id"));
        d.put("readiness_before",     rec.getValue("readiness_before"));
        d.put("readiness_after",      rec.getValue("readiness_after"));
        d.put("readiness_changed",    parseIntValue(rec.getValue("readiness_changed")));
        d.put("new_concerns",         rec.getValue("new_concerns"));
        d.put("resolved_concerns",    rec.getValue("resolved_concerns"));
        d.put("persistent_concerns",  rec.getValue("persistent_concerns"));
        d.put("concern_changed",      parseIntValue(rec.getValue("concern_changed")));
        d.put("new_triggers",         rec.getValue("new_triggers"));
        d.put("resolved_triggers",    rec.getValue("resolved_triggers"));
        d.put("persistent_triggers",  rec.getValue("persistent_triggers"));
        d.put("trigger_changed",      parseIntValue(rec.getValue("trigger_changed")));
        d.put("new_advice",           rec.getValue("new_advice"));
        d.put("continued_advice",     rec.getValue("continued_advice"));
        d.put("dropped_advice",       rec.getValue("dropped_advice"));
        d.put("advice_changed",       parseIntValue(rec.getValue("advice_changed")));
        d.put("quit_history_before",    rec.getValue("quit_history_before"));
        d.put("quit_history_after",     rec.getValue("quit_history_after"));
        d.put("quit_history_changed",   parseIntValue(rec.getValue("quit_history_changed")));
        d.put("new_quit_attempts",      rec.getValue("new_quit_attempts"));
        d.put("cumulative_quit_history", rec.getValue("cumulative_quit_history"));
        d.put("relapse_detected",         parseIntValue(rec.getValue("relapse_detected")));
        d.put("progress_detected",        parseIntValue(rec.getValue("progress_detected")));
        d.put("rapid_progress_detected",  parseIntValue(rec.getValue("rapid_progress_detected")));
        d.put("stagnation_detected",      parseIntValue(rec.getValue("stagnation_detected")));
        d.put("concern_shift_detected",   parseIntValue(rec.getValue("concern_shift_detected")));
        d.put("trigger_resolved",         parseIntValue(rec.getValue("trigger_resolved")));
        d.put("clinical_summary",         rec.getValue("clinical_summary"));
        r.put("success", true);
        r.put("delta", d);
    } else {
        r.put("success", false);
        r.put("message", "no_delta");
    }
} catch (Exception e) {
    r.put("success", false);
    r.put("message", "Error: " + e.getMessage());
}
out.print(r.toJSONString());
%>

<%!
private int parseIntValue(String value) {
    if (value == null || value.trim().isEmpty()) return 0;
    try {
        return Integer.parseInt(value);
    } catch (NumberFormatException e) {
        return 0;
    }
}
%>

<%@page contentType="application/json" import="imedix.rcDisplayData,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
String sessionId = request.getParameter("session_id");
String summary   = request.getParameter("clinical_summary");

if (sessionId == null || sessionId.trim().isEmpty()) {
    r.put("success", false);
    r.put("message", "session_id required");
    out.print(r.toJSONString());
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    boolean updated = rd.updateDeltaClinicalSummary(sessionId.trim(), summary != null ? summary : "");
    r.put("success", updated);
    r.put("message", updated ? "Saved" : "No delta found for this session");
} catch (Exception e) {
    r.put("success", false);
    r.put("message", "Error: " + e.getMessage());
}
out.print(r.toJSONString());
%>

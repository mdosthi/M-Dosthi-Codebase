<%@page contentType="application/json" import="imedix.rcDisplayData,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

String sessionId = request.getParameter("session_id");
String summary   = request.getParameter("summary");

if (sessionId == null || sessionId.trim().isEmpty()) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "session_id is required");
    out.print(jsonResponse.toJSONString());
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    rd.saveSessionSummary(sessionId.trim(), summary);

    jsonResponse.put("success", true);
    jsonResponse.put("message", "Summary saved.");
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Error: " + e.getMessage());
    System.out.println("ERROR - saveSessionSummary: " + e.getMessage());
}

out.print(jsonResponse.toJSONString());
%>

<%@page contentType="application/json" import="imedix.rcDisplayData,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

String patId     = request.getParameter("pat_id");
String sessionId = request.getParameter("session_id");
String force     = request.getParameter("force");
boolean forceReannotate = "true".equalsIgnoreCase(force);

if (patId == null || patId.trim().isEmpty() || sessionId == null || sessionId.trim().isEmpty()) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "pat_id and session_id are required");
    out.print(jsonResponse.toJSONString());
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    rd.queueAnnotation(patId.trim(), sessionId.trim(), forceReannotate);

    jsonResponse.put("success", true);
    jsonResponse.put("message", forceReannotate
        ? "Reannotation queued for session " + sessionId
        : "Annotation queued for session " + sessionId);
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Failed to queue annotation: " + e.getMessage());
    System.out.println("ERROR - annotateSession: " + e.getMessage());
}

out.print(jsonResponse.toJSONString());
%>

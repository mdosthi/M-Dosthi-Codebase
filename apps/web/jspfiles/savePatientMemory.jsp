<%@page contentType="application/json" import="imedix.rcDisplayData,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
String deltaIdStr           = request.getParameter("delta_id");
String persistentTriggers   = request.getParameter("persistent_triggers");
String persistentConcerns   = request.getParameter("persistent_concerns");
String cumulativeQuitHistory = request.getParameter("cumulative_quit_history");
String continuedAdvice      = request.getParameter("continued_advice");
String readinessAfter       = request.getParameter("readiness_after");

if (deltaIdStr == null || deltaIdStr.trim().isEmpty()) {
    r.put("success", false);
    r.put("message", "delta_id required");
    out.print(r.toJSONString());
    return;
}

try {
    long deltaId = Long.parseLong(deltaIdStr.trim());

    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    boolean updated = rd.updateSessionDeltaFields(
        deltaId,
        persistentTriggers != null ? persistentTriggers : "",
        persistentConcerns != null ? persistentConcerns : "",
        cumulativeQuitHistory != null ? cumulativeQuitHistory : "",
        continuedAdvice != null ? continuedAdvice : "",
        readinessAfter != null ? readinessAfter : ""
    );
    r.put("success", updated);
    r.put("message", updated ? "Saved" : "No matching record found");
} catch (NumberFormatException e) {
    r.put("success", false);
    r.put("message", "Invalid delta_id");
} catch (Exception e) {
    r.put("success", false);
    r.put("message", "Error: " + e.getMessage());
}
out.print(r.toJSONString());
%>

<%@page contentType="application/json" import="imedix.rcDisplayData,imedix.dataobj,java.util.*,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
String patId = request.getParameter("pat_id");

if (patId == null || patId.trim().isEmpty()) {
    r.put("success", false);
    r.put("message", "pat_id required");
    out.print(r.toJSONString());
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    Object result = rd.getLatestPatientMemory(patId.trim());

    if (result instanceof Vector && ((Vector) result).size() > 0) {
        dataobj d = (dataobj) ((Vector) result).get(0);
        r.put("success", true);
        r.put("delta_id", Long.parseLong(d.getValue("delta_id")));
        r.put("persistent_triggers", d.getValue("persistent_triggers"));
        r.put("persistent_concerns", d.getValue("persistent_concerns"));
        r.put("cumulative_quit_history", d.getValue("cumulative_quit_history"));
        r.put("continued_advice", d.getValue("continued_advice"));
        r.put("readiness_after", d.getValue("readiness_after"));
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

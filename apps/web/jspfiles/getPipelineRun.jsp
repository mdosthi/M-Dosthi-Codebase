<%@page import="imedix.rcDisplayData,imedix.dataobj,java.util.*" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

String sessionId = request.getParameter("session_id");

if (sessionId == null || sessionId.trim().isEmpty()) {
    out.print("{\"success\":false,\"message\":\"session_id is required\"}");
    return;
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    Object result = rd.getLatestPipelineRun(sessionId);

    if (result instanceof Vector && ((Vector) result).size() > 0) {
        dataobj d = (dataobj) ((Vector) result).get(0);

        StringBuilder sb = new StringBuilder();
        sb.append("{\"success\":true,\"run\":{");
        sb.append("\"run_id\":").append(jsonStr(d.getValue("run_id"))).append(",");
        sb.append("\"conversation_id\":").append(jsonStr(d.getValue("conversation_id"))).append(",");
        sb.append("\"patient_id\":").append(jsonStr(d.getValue("patient_id"))).append(",");
        sb.append("\"created_at\":").append(jsonStr(d.getValue("created_at"))).append(",");
        sb.append("\"total_rounds\":").append(d.getValue("total_rounds") != null ? d.getValue("total_rounds") : "0").append(",");

        // Embed JSON columns verbatim — they are valid JSON from MySQL
        String rounds              = d.getValue("rounds");
        String consensus           = d.getValue("consensus");
        String datasetRow          = d.getValue("dataset_row");
        String sessionDelta        = d.getValue("session_delta");
        String longitudinalSanity  = d.getValue("longitudinal_sanity");
        String longitudinalOutput  = d.getValue("longitudinal_output");

        sb.append("\"rounds\":").append(rounds  != null && !rounds.isEmpty()  ? rounds  : "[]").append(",");
        sb.append("\"consensus\":").append(consensus  != null && !consensus.isEmpty()  ? consensus  : "null").append(",");
        sb.append("\"dataset_row\":").append(datasetRow  != null && !datasetRow.isEmpty()  ? datasetRow  : "null").append(",");
        sb.append("\"session_delta\":").append(sessionDelta  != null && !sessionDelta.isEmpty()  ? sessionDelta  : "null").append(",");
        sb.append("\"longitudinal_sanity\":").append(longitudinalSanity != null && !longitudinalSanity.isEmpty() ? longitudinalSanity : "null").append(",");
        sb.append("\"longitudinal_output\":").append(longitudinalOutput  != null && !longitudinalOutput.isEmpty()  ? longitudinalOutput  : "null");
        sb.append("}}");

        out.print(sb.toString());
    } else {
        out.print("{\"success\":false,\"message\":\"No pipeline run found for this session\"}");
    }
} catch (Exception e) {
    out.print("{\"success\":false,\"message\":" + jsonStr("Server error: " + e.getMessage()) + "}");
}
%>

<%!
private String jsonStr(String s) {
    if (s == null) return "null";
    return "\"" + s.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\r", "\\r")
                   .replace("\n", "\\n")
                   .replace("\t", "\\t") + "\"";
}
%>

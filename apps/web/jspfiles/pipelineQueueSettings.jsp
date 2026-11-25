<%@page contentType="application/json" import="imedix.rcDisplayData,imedix.dataobj,java.util.*,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject result = new JSONObject();
String startTime = request.getParameter("start_time");
String endTime = request.getParameter("end_time");

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));

    if (startTime != null && endTime != null) {
        // Save
        rd.savePipelineQueueSettings(startTime, endTime);
        result.put("start_time", startTime);
        result.put("end_time", endTime);
    } else {
        // Load
        Object settingsResult = rd.getPipelineQueueSettings();
        if (settingsResult instanceof Vector && ((Vector) settingsResult).size() > 0) {
            dataobj d = (dataobj) ((Vector) settingsResult).get(0);
            result.put("start_time", d.getValue("start_time"));
            result.put("end_time", d.getValue("end_time"));
        } else {
            result.put("start_time", "00:00");
            result.put("end_time", "02:00");
        }
    }
    result.put("success", true);
} catch (Exception e) {
    result.put("success", false);
    result.put("error", e.getMessage());
}

out.print(result.toJSONString());
%>

<%@page contentType="application/json" import="imedix.rcDisplayData,org.json.simple.JSONObject" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject result = new JSONObject();

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    int deleted = rd.clearPipelineQueue();
    result.put("success", true);
    result.put("deleted", deleted);
} catch (Exception e) {
    result.put("success", false);
    result.put("error", e.getMessage());
}

out.print(result.toJSONString());
%>

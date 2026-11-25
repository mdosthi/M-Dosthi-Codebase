<%@page contentType="application/json" import="imedix.rcDisplayData,java.util.*,org.json.simple.JSONObject,org.json.simple.JSONArray"%>
<%
// NO chkcook.jsp include for JSON responses
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    rcDisplayData rdd = new rcDisplayData(request.getRealPath("/"));
    
    // Get all available surveys from survey_project table
    Object surveyData = rdd.getAllSurveys();
    
    if (surveyData instanceof String) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", (String)surveyData);
    } else {
        Vector dataVector = (Vector)surveyData;
        JSONArray surveysArray = new JSONArray();
        
        for (int i = 0; i < dataVector.size(); i++) {
            imedix.dataobj survey = (imedix.dataobj)dataVector.get(i);
            
            JSONObject surveyObj = new JSONObject();
            surveyObj.put("sid", survey.getValue("sid"));
            surveyObj.put("name", survey.getValue("name"));
            surveyObj.put("description", survey.getValue("description"));
            
            surveysArray.add(surveyObj);
        }
        
        jsonResponse.put("success", true);
        jsonResponse.put("surveys", surveysArray);
    }
    
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Error: " + e.getMessage());
    e.printStackTrace();
}

out.print(jsonResponse.toString());
out.flush();
%>
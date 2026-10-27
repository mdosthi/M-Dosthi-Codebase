<%@page contentType="application/json" import="imedix.rcDisplayData,java.util.*,org.json.simple.JSONObject"%>
<%
// NO chkcook.jsp include for JSON responses
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    String patId = request.getParameter("pat_id");
    String surveyIds = request.getParameter("survey_ids");
    
    if (patId == null || patId.isEmpty() || surveyIds == null || surveyIds.isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID and Survey IDs are required");
    } else {
        rcDisplayData rdd = new rcDisplayData(request.getRealPath("/"));
        
        // Split survey IDs
        String[] surveyIdArray = surveyIds.split(",");
        
        boolean allSuccess = true;
        int successCount = 0;
        
        for (String surveyId : surveyIdArray) {
            surveyId = surveyId.trim();
            
            // Assign test to patient (insert into PrescribedTests table)
            boolean result = rdd.assignTestToPatient(patId, surveyId);
            
            if (result) {
                successCount++;
            } else {
                allSuccess = false;
            }
        }
        
        if (allSuccess) {
            jsonResponse.put("success", true);
            jsonResponse.put("message", successCount + " form(s) assigned successfully");
        } else {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Some forms could not be assigned. " + successCount + " out of " + surveyIdArray.length + " assigned.");
        }
    }
    
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Error: " + e.getMessage());
    e.printStackTrace();
}

out.print(jsonResponse.toString());
out.flush();
%>
<%@ page import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.JSONArray,org.json.simple.parser.JSONParser" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    // Get parameters
    String patId = request.getParameter("pat_id");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    String statusFilter = request.getParameter("status_filter");
    String action = request.getParameter("action");
    String sessionId = request.getParameter("session_id");
    
    System.out.println("=== getChatHistoryDirect.jsp ===");
    System.out.println("PatID: " + patId);
    System.out.println("FromDate: " + fromDate);
    System.out.println("ToDate: " + toDate);
    System.out.println("StatusFilter: " + statusFilter);
    System.out.println("Action: " + action);
    System.out.println("SessionID: " + sessionId);
    
    if (patId == null || patId.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID is required");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    // Handle different actions
    if ("getMessages".equals(action) && sessionId != null) {
        // Get messages for a specific session
        System.out.println("Getting messages for session: " + sessionId);
        
        Object result = rd.getChatMessages(sessionId);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector messages = (Vector) result;
            JSONArray messageArray = new JSONArray();
            
            for (int i = 0; i < messages.size(); i++) {
                dataobj messageObj = (dataobj) messages.get(i);
                JSONObject msgJson = new JSONObject();
                
                msgJson.put("message_id", messageObj.getValue("message_id"));
                msgJson.put("session_id", messageObj.getValue("session_id"));
                msgJson.put("message_sequence", messageObj.getValue("message_sequence"));
                msgJson.put("sender_type", messageObj.getValue("sender_type"));
                msgJson.put("message_content", messageObj.getValue("message_content"));
                msgJson.put("timestamp", messageObj.getValue("timestamp"));
                msgJson.put("is_read", messageObj.getValue("is_read"));
                msgJson.put("response_time", messageObj.getValue("response_time"));
                
                messageArray.add(msgJson);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("messages", messageArray);
        }
        
    } else {
        // Get chat sessions (default action)
        System.out.println("Getting chat sessions for patient: " + patId);
        
        Object result;
        
        // Choose appropriate method based on filters
        if ((fromDate != null && !fromDate.trim().isEmpty()) && 
            (toDate != null && !toDate.trim().isEmpty())) {
            System.out.println("Using date range query");
            result = rd.getChatSessionsDateRange(patId, fromDate, toDate);
        } else {
            System.out.println("Using general query");
            result = rd.getChatSessions(patId);
        }
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector sessions = (Vector) result;
            JSONArray sessionArray = new JSONArray();
            
            System.out.println("Found " + sessions.size() + " sessions");
            
            for (int i = 0; i < sessions.size(); i++) {
                dataobj sessionObj = (dataobj) sessions.get(i);
                
                // Apply status filter if specified
                String sessionStatus = sessionObj.getValue("session_status");
                if (statusFilter != null && !statusFilter.trim().isEmpty() && 
                    !statusFilter.equalsIgnoreCase(sessionStatus)) {
                    continue; // Skip this session
                }
                
                JSONObject sessionJson = new JSONObject();
                
                sessionJson.put("session_id", sessionObj.getValue("session_id"));
                sessionJson.put("pat_id", sessionObj.getValue("pat_id"));
                sessionJson.put("session_date", sessionObj.getValue("session_date"));
                sessionJson.put("start_time", sessionObj.getValue("start_time"));
                sessionJson.put("end_time", sessionObj.getValue("end_time"));
                sessionJson.put("duration", sessionObj.getValue("duration"));
                sessionJson.put("session_notes", sessionObj.getValue("session_notes"));
                sessionJson.put("session_status", sessionStatus);
                
                // Try to get message count for this session
                try {
                    Object messageCountResult = rd.getChatMessageCount(sessionObj.getValue("session_id"));
                    if (messageCountResult instanceof Vector && ((Vector)messageCountResult).size() > 0) {
                        dataobj countObj = (dataobj) ((Vector)messageCountResult).get(0);
                        sessionJson.put("message_count", countObj.getValue("message_count"));
                    } else {
                        sessionJson.put("message_count", 0);
                    }
                } catch (Exception e) {
                    System.out.println("Error getting message count: " + e.getMessage());
                    sessionJson.put("message_count", "?");
                }
                
                sessionArray.add(sessionJson);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("sessions", sessionArray);
            jsonResponse.put("total", sessionArray.size());
        }
    }
    
    System.out.println("Response: " + jsonResponse.toJSONString());
    
} catch (Exception e) {
    System.out.println("Exception in getChatHistoryDirect: " + e.getMessage());
    e.printStackTrace();
    
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Database error: " + e.getMessage());
    jsonResponse.put("exception", e.getClass().getName());
}

out.print(jsonResponse.toJSONString());
%>
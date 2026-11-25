<%-- <%@ page import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.parser.JSONParser" %>
<%@ page import="org.json.simple.*" %>

<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    // Get parameters
    String action = request.getParameter("action");
    String patId = request.getParameter("pat_id");
    String sessionId = request.getParameter("session_id");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    
    System.out.println("DEBUG - getChatHistory.jsp action: " + action);
    System.out.println("DEBUG - patId: " + patId);
    System.out.println("DEBUG - sessionId: " + sessionId);
    
    if (patId == null || patId.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID is required");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    // Get patient ID from session if needed (following your existing pattern)
    String sessionToken = null;
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if ("session_token".equals(cookie.getName())) {
                sessionToken = cookie.getValue();
                break;
            }
        }
    }
    
    String realPatientId = patId;
    if (sessionToken != null && !sessionToken.trim().isEmpty()) {
        // You can add session validation here if needed
        // Following your existing pattern from other JSP files
    }
    
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    if ("getSessions".equals(action)) {
        // Get chat sessions
        Object result;
        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
            result = rd.getChatSessionsDateRange(realPatientId, fromDate, toDate);
        } else {
            result = rd.getChatSessions(realPatientId);
        }
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector sessions = (Vector) result;
            JSONArray sessionArray = new JSONArray();
            
            for (int i = 0; i < sessions.size(); i++) {
                dataobj sessionData = (dataobj) sessions.get(i);
                JSONObject sessionObj = new JSONObject();
                
                sessionObj.put("session_id", sessionData.getValue(0));
                sessionObj.put("session_date", sessionData.getValue(1));
                sessionObj.put("start_time", sessionData.getValue(2));
                sessionObj.put("end_time", sessionData.getValue(3));
                sessionObj.put("duration", sessionData.getValue(4));
                sessionObj.put("session_notes", sessionData.getValue(5));
                sessionObj.put("session_status", sessionData.getValue(6));
                
                sessionArray.add(sessionObj);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("sessions", sessionArray);
        }
        
    } else if ("getMessages".equals(action)) {
        // Get messages for a specific session
        if (sessionId == null || sessionId.trim().isEmpty()) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Session ID is required");
        } else {
            Object result = rd.getChatMessages(sessionId);
            
            if (result instanceof String) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Error: " + result);
            } else {
                Vector messages = (Vector) result;
                JSONArray messageArray = new JSONArray();
                
                for (int i = 0; i < messages.size(); i++) {
                    dataobj messageData = (dataobj) messages.get(i);
                    JSONObject messageObj = new JSONObject();
                    
                    messageObj.put("message_id", messageData.getValue(0));
                    messageObj.put("message_sequence", messageData.getValue(1));
                    messageObj.put("sender_type", messageData.getValue(2));
                    messageObj.put("message_content", messageData.getValue(3));
                    messageObj.put("timestamp", messageData.getValue(4));
                    messageObj.put("is_read", messageData.getValue(5));
                    messageObj.put("response_time", messageData.getValue(6));
                    
                    messageArray.add(messageObj);
                }
                
                jsonResponse.put("success", true);
                jsonResponse.put("messages", messageArray);
            }
        }
        
    } else if ("getSummary".equals(action)) {
        // Get chat summary
        Object result = rd.getChatSessionsSummary(realPatientId);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector summary = (Vector) result;
            if (summary.size() > 0) {
                dataobj summaryData = (dataobj) summary.get(0);
                JSONObject summaryObj = new JSONObject();
                
                summaryObj.put("total_sessions", summaryData.getValue(0));
                summaryObj.put("total_duration", summaryData.getValue(1));
                summaryObj.put("avg_duration", summaryData.getValue(2));
                summaryObj.put("last_session_date", summaryData.getValue(3));
                summaryObj.put("first_session_date", summaryData.getValue(4));
                
                jsonResponse.put("success", true);
                jsonResponse.put("summary", summaryObj);
            } else {
                jsonResponse.put("success", true);
                jsonResponse.put("summary", new JSONObject());
            }
        }
        
    } else {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Invalid action");
    }
    
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Database error: " + e.getMessage());
    System.out.println("ERROR - Exception in getChatHistory: " + e.getMessage());
    e.printStackTrace();
}

out.print(jsonResponse.toJSONString());
%> --%>
<%@ page import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.JSONArray,org.json.simple.parser.JSONParser" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    // Get parameters
    String action = request.getParameter("action");
    String patId = request.getParameter("pat_id");
    String sessionId = request.getParameter("session_id");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    String statusFilter = request.getParameter("status_filter");
    String pageStr = request.getParameter("page");
    String limitStr = request.getParameter("limit");
    
    System.out.println("=== getChatHistory.jsp DEBUG ===");
    System.out.println("Action: " + action);
    System.out.println("PatID: " + patId);
    System.out.println("SessionID: " + sessionId);
    System.out.println("FromDate: " + fromDate);
    System.out.println("ToDate: " + toDate);
    System.out.println("StatusFilter: " + statusFilter);
    System.out.println("Page: " + pageStr);
    System.out.println("Limit: " + limitStr);
    
    if (patId == null || patId.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID is required");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    // Get patient ID from session if needed (following your existing pattern)
    String sessionToken = null;
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if ("session_token".equals(cookie.getName())) {
                sessionToken = cookie.getValue();
                break;
            }
        }
    }
    
    String realPatientId = patId;
    if (sessionToken != null && !sessionToken.trim().isEmpty()) {
        // You can add session validation here if needed
        System.out.println("Session token found: " + sessionToken);
    }
    
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    if ("getSessions".equals(action)) {
        // Get chat sessions
        System.out.println("Getting sessions for patient: " + realPatientId);
        
        Object result;
        int page = 1;
        int limit = 10;
        
        try {
            if (pageStr != null) page = Integer.parseInt(pageStr);
            if (limitStr != null) limit = Integer.parseInt(limitStr);
        } catch (NumberFormatException e) {
            System.out.println("Error parsing page/limit parameters");
        }
        
        // Choose appropriate method based on available filters
        if ((fromDate != null && !fromDate.trim().isEmpty()) && 
            (toDate != null && !toDate.trim().isEmpty()) && 
            (statusFilter != null && !statusFilter.trim().isEmpty())) {
            // Use filtered method if available
            System.out.println("Using filtered query with date range and status");
            try {
                int offset = (page - 1) * limit;
                result = rd.getChatSessionsWithFilter(realPatientId, fromDate, toDate, statusFilter, offset, limit);
            } catch (Exception e) {
                System.out.println("Filtered method not available, falling back to date range");
                result = rd.getChatSessionsDateRange(realPatientId, fromDate, toDate);
            }
        } else if ((fromDate != null && !fromDate.trim().isEmpty()) && 
                   (toDate != null && !toDate.trim().isEmpty())) {
            // Use date range method
            System.out.println("Using date range query");
            result = rd.getChatSessionsDateRange(realPatientId, fromDate, toDate);
        } else {
            // Use general method
            System.out.println("Using general query");
            result = rd.getChatSessions(realPatientId);
        }
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + result);
        } else {
            Vector sessions = (Vector) result;
            JSONArray sessionArray = new JSONArray();
            
            System.out.println("Found " + sessions.size() + " sessions from database");
            
            int processedSessions = 0;
            
            for (int i = 0; i < sessions.size(); i++) {
                try {
                    dataobj sessionObj = (dataobj) sessions.get(i);
                    
                    // Apply status filter if specified (for methods that don't support it natively)
                    String sessionStatus = sessionObj.getValue("session_status");
                    if (statusFilter != null && !statusFilter.trim().isEmpty() && 
                        !statusFilter.equalsIgnoreCase(sessionStatus)) {
                        continue; // Skip this session
                    }
                    
                    JSONObject sessionJson = new JSONObject();
                    
                    // Map database fields to JSON (based on actual database structure)
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
                            Object messageCount = countObj.getValue("message_count");
                            sessionJson.put("message_count", messageCount != null ? messageCount : 0);
                        } else {
                            sessionJson.put("message_count", 0);
                        }
                    } catch (Exception e) {
                        System.out.println("Error getting message count for session " + sessionObj.getValue("session_id") + ": " + e.getMessage());
                        sessionJson.put("message_count", "?");
                    }
                    
                    sessionArray.add(sessionJson);
                    processedSessions++;
                    
                } catch (Exception e) {
                    System.out.println("Error processing session " + i + ": " + e.getMessage());
                    continue;
                }
            }
            
            System.out.println("Processed " + processedSessions + " sessions successfully");
            
            jsonResponse.put("success", true);
            jsonResponse.put("sessions", sessionArray);
            jsonResponse.put("total", processedSessions);
            jsonResponse.put("page", page);
            jsonResponse.put("limit", limit);
        }
        
    } else if ("getMessages".equals(action)) {
        // Get messages for a specific session
        System.out.println("Getting messages for session: " + sessionId);
        
        if (sessionId == null || sessionId.trim().isEmpty()) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Session ID is required for getting messages");
        } else {
            Object result = rd.getChatMessages(sessionId);
            
            if (result instanceof String) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Error: " + result);
            } else {
                Vector messages = (Vector) result;
                JSONArray messageArray = new JSONArray();
                
                System.out.println("Found " + messages.size() + " messages for session");
                
                for (int i = 0; i < messages.size(); i++) {
                    try {
                        dataobj messageObj = (dataobj) messages.get(i);
                        JSONObject msgJson = new JSONObject();
                        
                        // Map database fields to JSON (based on actual database structure)
                        msgJson.put("message_id", messageObj.getValue("message_id"));
                        msgJson.put("session_id", messageObj.getValue("session_id"));
                        msgJson.put("message_sequence", messageObj.getValue("message_sequence"));
                        msgJson.put("sender_type", messageObj.getValue("sender_type"));
                        msgJson.put("message_content", messageObj.getValue("message_content"));
                        msgJson.put("timestamp", messageObj.getValue("timestamp"));
                        msgJson.put("is_read", messageObj.getValue("is_read"));
                        msgJson.put("response_time", messageObj.getValue("response_time"));
                        msgJson.put("file_format", messageObj.getValue("file_format"));
                        msgJson.put("file_size", messageObj.getValue("file_size"));
                        
                        messageArray.add(msgJson);
                    } catch (Exception e) {
                        System.out.println("Error processing message " + i + ": " + e.getMessage());
                        continue;
                    }
                }
                
                jsonResponse.put("success", true);
                jsonResponse.put("messages", messageArray);
                jsonResponse.put("session_id", sessionId);
            }
        }
        
    } else if ("getSummary".equals(action)) {
        // Get chat summary
        System.out.println("Getting summary for patient: " + realPatientId);
        
        try {
            Object result = rd.getChatSessionsSummary(realPatientId);
            
            if (result instanceof String) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Error: " + result);
            } else {
                Vector summary = (Vector) result;
                if (summary.size() > 0) {
                    dataobj summaryData = (dataobj) summary.get(0);
                    JSONObject summaryObj = new JSONObject();
                    
                    // Map summary fields
                    summaryObj.put("total_sessions", summaryData.getValue("total_sessions"));
                    summaryObj.put("total_duration", summaryData.getValue("total_duration"));
                    summaryObj.put("avg_duration", summaryData.getValue("avg_duration"));
                    summaryObj.put("last_session_date", summaryData.getValue("last_session_date"));
                    summaryObj.put("first_session_date", summaryData.getValue("first_session_date"));
                    summaryObj.put("completed_sessions", summaryData.getValue("completed_sessions"));
                    summaryObj.put("active_sessions", summaryData.getValue("active_sessions"));
                    summaryObj.put("terminated_sessions", summaryData.getValue("terminated_sessions"));
                    
                    jsonResponse.put("success", true);
                    jsonResponse.put("summary", summaryObj);
                } else {
                    // No data found
                    JSONObject emptySummary = new JSONObject();
                    emptySummary.put("total_sessions", 0);
                    emptySummary.put("total_duration", 0);
                    emptySummary.put("avg_duration", 0);
                    emptySummary.put("last_session_date", null);
                    emptySummary.put("first_session_date", null);
                    emptySummary.put("completed_sessions", 0);
                    emptySummary.put("active_sessions", 0);
                    emptySummary.put("terminated_sessions", 0);
                    
                    jsonResponse.put("success", true);
                    jsonResponse.put("summary", emptySummary);
                }
            }
        } catch (Exception e) {
            System.out.println("Error getting summary: " + e.getMessage());
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error getting summary: " + e.getMessage());
        }
        
    } else {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Invalid action: " + action);
    }
    
    System.out.println("Final response success: " + jsonResponse.get("success"));
    System.out.println("Response length: " + jsonResponse.toJSONString().length());
    
} catch (Exception e) {
    System.out.println("=== EXCEPTION in getChatHistory.jsp ===");
    System.out.println("Exception type: " + e.getClass().getName());
    System.out.println("Exception message: " + e.getMessage());
    e.printStackTrace();
    
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Unexpected error: " + e.getMessage());
    jsonResponse.put("exception_type", e.getClass().getName());
}

// Ensure proper JSON response
String responseStr = jsonResponse.toJSONString();
System.out.println("Final JSON response: " + responseStr);
out.print(responseStr);
%>
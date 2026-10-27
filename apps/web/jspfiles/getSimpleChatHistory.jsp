<%@page import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.JSONArray" %>
<%@page import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.JSONArray" %>
<%
// Set content type to JSON
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    // Get parameters directly - no authentication check needed since patient ID is provided
    String action = request.getParameter("action");
    String patId = request.getParameter("pat_id");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    String sessionId = request.getParameter("session_id");
    
    System.out.println("DEBUG - getSimpleChatHistory called");
    System.out.println("DEBUG - action: " + action);
    System.out.println("DEBUG - pat_id: " + patId);
    
    // Simple validation - patient ID should be provided
    if (patId == null || patId.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID parameter is required");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    System.out.println("DEBUG - Using patient ID: " + patId);
    
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    if ("summary".equals(action)) {
        // Handle summary request
        handleSummaryRequest(rd, patId, jsonResponse);
        
    } else if ("messages".equals(action)) {
        // Handle messages request
        handleMessagesRequest(rd, sessionId, jsonResponse);
        
    } else {
        // Handle default session list request
        handleSessionsRequest(rd, patId, fromDate, toDate, jsonResponse);
    }
    
} catch (Exception e) {
    System.out.println("ERROR - getSimpleChatHistory: " + e.getMessage());
    e.printStackTrace();
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Server error: " + e.getMessage());
}

out.print(jsonResponse.toJSONString());
%>

<%!
// Helper methods
void handleSessionsRequest(rcDisplayData rd, String patId, String fromDate, String toDate, JSONObject jsonResponse) {
    try {
        System.out.println("DEBUG - Getting sessions for patId: " + patId);
        
        Object result;
        if (fromDate != null && toDate != null && !fromDate.trim().isEmpty() && !toDate.trim().isEmpty()) {
            // Use date range method if available
            result = rd.getChatSessionsDateRange(patId, fromDate, toDate);
        } else {
            // Use simple method
            result = rd.getChatSessions(patId);
        }
        
        System.out.println("DEBUG - getChatSessions result type: " + (result != null ? result.getClass().getName() : "null"));
        
        if (result instanceof String) {
            // Error result
            jsonResponse.put("success", false);
            jsonResponse.put("message", result.toString());
            return;
        }
        
        if (result instanceof Vector) {
            Vector sessionVec = (Vector) result;
            System.out.println("DEBUG - Found " + sessionVec.size() + " sessions");
            
            JSONArray sessionsArray = new JSONArray();
            
            for (int i = 0; i < sessionVec.size(); i++) {
                dataobj sessionObj = (dataobj) sessionVec.get(i);
                
                JSONObject sessionJson = new JSONObject();
                sessionJson.put("session_id", sessionObj.getValue("session_id"));
                sessionJson.put("session_date", sessionObj.getValue("session_date"));
                sessionJson.put("start_time", sessionObj.getValue("start_time"));
                sessionJson.put("end_time", sessionObj.getValue("end_time"));
                sessionJson.put("duration", parseIntValue(sessionObj.getValue("duration")));
                sessionJson.put("session_status", sessionObj.getValue("session_status"));
                sessionJson.put("session_notes", sessionObj.getValue("session_notes"));

                // Get message count for this session
                String sessionId = sessionObj.getValue("session_id");
                int messageCount = getMessageCount(rd, sessionId);
                sessionJson.put("message_count", messageCount);

                // Check annotation status
                boolean isAnnotated = checkAnnotated(rd, patId, sessionId);
                sessionJson.put("is_annotated", isAnnotated);

                sessionsArray.add(sessionJson);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("sessions", sessionsArray);
            jsonResponse.put("total", sessionsArray.size());
            
        } else {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Unexpected data format received");
        }
        
    } catch (Exception e) {
        System.out.println("ERROR - handleSessionsRequest: " + e.getMessage());
        e.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Error retrieving sessions: " + e.getMessage());
    }
}

void handleMessagesRequest(rcDisplayData rd, String sessionId, JSONObject jsonResponse) {
    try {
        System.out.println("DEBUG - Getting messages for sessionId: " + sessionId);
        
        if (sessionId == null || sessionId.trim().isEmpty()) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Session ID is required");
            return;
        }
        
        Object result = rd.getChatMessages(sessionId);
        System.out.println("DEBUG - getChatMessages result type: " + (result != null ? result.getClass().getName() : "null"));
        
        if (result instanceof String) {
            // Error result
            jsonResponse.put("success", false);
            jsonResponse.put("message", result.toString());
            return;
        }
        
        if (result instanceof Vector) {
            Vector messageVec = (Vector) result;
            System.out.println("DEBUG - Found " + messageVec.size() + " messages");
            
            JSONArray messagesArray = new JSONArray();
            
            for (int i = 0; i < messageVec.size(); i++) {
                dataobj messageObj = (dataobj) messageVec.get(i);
                
                JSONObject messageJson = new JSONObject();
                messageJson.put("message_id", messageObj.getValue("message_id"));
                messageJson.put("message_sequence", parseIntValue(messageObj.getValue("message_sequence")));
                messageJson.put("sender_type", messageObj.getValue("sender_type"));
                messageJson.put("message_content", messageObj.getValue("message_content"));
                messageJson.put("timestamp", messageObj.getValue("timestamp"));
                messageJson.put("is_read", parseIntValue(messageObj.getValue("is_read")));
                messageJson.put("response_time", parseIntValue(messageObj.getValue("response_time")));
                
                messagesArray.add(messageJson);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("messages", messagesArray);
            
        } else {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Unexpected data format received");
        }
        
    } catch (Exception e) {
        System.out.println("ERROR - handleMessagesRequest: " + e.getMessage());
        e.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Error retrieving messages: " + e.getMessage());
    }
}

void handleSummaryRequest(rcDisplayData rd, String patId, JSONObject jsonResponse) {
    try {
        System.out.println("DEBUG - Getting summary for patId: " + patId);
        
        // Get all sessions for summary
        Object result = rd.getChatSessions(patId);
        
        if (result instanceof String) {
            // Error result
            jsonResponse.put("success", false);
            jsonResponse.put("message", result.toString());
            return;
        }
        
        if (result instanceof Vector) {
            Vector sessionVec = (Vector) result;
            
            JSONObject summary = new JSONObject();
            int totalSessions = sessionVec.size();
            int totalDuration = 0;
            int totalMessages = 0;
            String lastSessionDate = null;
            
            for (int i = 0; i < sessionVec.size(); i++) {
                dataobj sessionObj = (dataobj) sessionVec.get(i);
                
                // Add duration
                String durationStr = sessionObj.getValue("duration");
                if (durationStr != null && !durationStr.trim().isEmpty()) {
                    try {
                        totalDuration += Integer.parseInt(durationStr);
                    } catch (NumberFormatException e) {
                        // Ignore invalid duration
                    }
                }
                
                // Get last session date (first in DESC order)
                if (i == 0) {
                    lastSessionDate = sessionObj.getValue("session_date");
                }
                
                // Count messages for this session
                String sessionId = sessionObj.getValue("session_id");
                totalMessages += getMessageCount(rd, sessionId);
            }
            
            summary.put("total_sessions", totalSessions);
            summary.put("total_duration", totalDuration);
            summary.put("total_messages", totalMessages);
            summary.put("last_session_date", lastSessionDate);
            
            jsonResponse.put("success", true);
            jsonResponse.put("summary", summary);
            
        } else {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Unexpected data format received");
        }
        
    } catch (Exception e) {
        System.out.println("ERROR - handleSummaryRequest: " + e.getMessage());
        e.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Error generating summary: " + e.getMessage());
    }
}

boolean checkAnnotated(rcDisplayData rd, String patId, String sessionId) {
    try {
        String signalId = "SIG_" + patId + "_" + sessionId;
        return rd.isSessionAnnotated(signalId);
    } catch (Exception e) {
        System.out.println("WARNING - checkAnnotated error: " + e.getMessage());
        return false;
    }
}

int getMessageCount(rcDisplayData rd, String sessionId) {
    try {
        if (sessionId == null || sessionId.trim().isEmpty()) {
            return 0;
        }
        
        Object result = rd.getChatMessages(sessionId);
        
        if (result instanceof Vector) {
            Vector messageVec = (Vector) result;
            return messageVec.size();
        }
        
        return 0;
        
    } catch (Exception e) {
        System.out.println("WARNING - Error getting message count for session " + sessionId + ": " + e.getMessage());
        return 0;
    }
}

int parseIntValue(String value) {
    if (value == null || value.trim().isEmpty()) {
        return 0;
    }
    try {
        return Integer.parseInt(value);
    } catch (NumberFormatException e) {
        return 0;
    }
}
%>

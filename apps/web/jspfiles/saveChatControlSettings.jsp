<%@page contentType="application/json" import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,java.sql.*,java.rmi.RemoteException,java.io.File" %>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    // Basic authentication check
    cook cookx = new cook();
    String sessionToken = cookx.getCookieValue("patid", request.getCookies());
    
    if (sessionToken == null || sessionToken.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Authentication required. Please login again.");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    // Get parameters from request
    String patId = request.getParameter("pat_id");
    String dailyChatLimitStr = request.getParameter("daily_chat_limit");
    String maxSessionDurationStr = request.getParameter("max_session_duration");
    String minSessionIntervalStr = request.getParameter("min_session_interval");
    String blackoutStartTime = request.getParameter("blackout_start_time");
    String blackoutEndTime = request.getParameter("blackout_end_time");
    String blackoutDays = request.getParameter("blackout_days");
    String chatType     = request.getParameter("chat_type");
    if (chatType == null || chatType.trim().isEmpty()) chatType = "original";
    // Sanitize to known values only
    if (!chatType.equals("original") && !chatType.equals("srijit")) {
        chatType = "original";
    }

    System.out.println("DEBUG - Session token: " + sessionToken);
    System.out.println("DEBUG - Received pat_id parameter: " + patId);
    
    // Determine the real patient ID (same logic as GET)
    String realPatientId = null;
    
    if (patId != null && !patId.trim().isEmpty()) {
        // Use provided patient ID if it looks like a real patient ID format
        if (patId.matches("^[A-Z]{2,6}\\d{6,15}$")) {
            realPatientId = patId;
            System.out.println("DEBUG - Using provided patient ID: " + realPatientId);
        } else {
            System.out.println("DEBUG - Provided pat_id doesn't match expected format: " + patId);
        }
    }
    
    // If we don't have a valid patient ID yet, try to extract it from session
    if (realPatientId == null) {
        // Method 1: Check if session token is actually a patient ID
        if (sessionToken.matches("^[A-Z]{2,6}\\d{6,15}$")) {
            realPatientId = sessionToken;
            System.out.println("DEBUG - Session token is actually patient ID: " + realPatientId);
        } else {
            // Method 2: Look up patient ID from session token or other cookies
            try {
                String altPatId = cookx.getCookieValue("real_patid", request.getCookies());
                if (altPatId != null && altPatId.matches("^[A-Z]{2,6}\\d{6,15}$")) {
                    realPatientId = altPatId;
                    System.out.println("DEBUG - Found real patient ID in alternate cookie: " + realPatientId);
                }
            } catch (Exception e) {
                System.out.println("DEBUG - Error looking up patient ID: " + e.getMessage());
            }
        }
    }
    
    // If we still don't have a patient ID, return error
    if (realPatientId == null) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Unable to determine patient ID. Please ensure you are properly logged in.");
        System.out.println("DEBUG - Could not determine real patient ID from session token: " + sessionToken);
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    System.out.println("DEBUG - Final patient ID to use: " + realPatientId);
    
    // Parse and validate numeric parameters
    int dailyChatLimit = 3;
    int maxSessionDuration = 1800;
    int minSessionInterval = 300;
    
    try {
        if (dailyChatLimitStr != null && !dailyChatLimitStr.trim().isEmpty()) {
            dailyChatLimit = Integer.parseInt(dailyChatLimitStr);
            if (dailyChatLimit < 1 || dailyChatLimit > 50) {
                throw new NumberFormatException("Daily chat limit must be between 1 and 50");
            }
        }
        
        if (maxSessionDurationStr != null && !maxSessionDurationStr.trim().isEmpty()) {
            maxSessionDuration = Integer.parseInt(maxSessionDurationStr);
            if (maxSessionDuration < 300 || maxSessionDuration > 7200) {
                throw new NumberFormatException("Max session duration must be between 300 and 7200 seconds");
            }
        }
        
        if (minSessionIntervalStr != null && !minSessionIntervalStr.trim().isEmpty()) {
            minSessionInterval = Integer.parseInt(minSessionIntervalStr);
            if (minSessionInterval < 300) {
                throw new NumberFormatException("Min session interval must be at least 300 seconds");
            }
        }
        
    } catch (NumberFormatException e) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Invalid numeric value: " + e.getMessage());
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    // Handle empty time fields
    if (blackoutStartTime != null && blackoutStartTime.trim().isEmpty()) {
        blackoutStartTime = null;
    }
    if (blackoutEndTime != null && blackoutEndTime.trim().isEmpty()) {
        blackoutEndTime = null;
    }
    if (blackoutDays != null && blackoutDays.trim().isEmpty()) {
        blackoutDays = null;
    }
    
    // Use rcDisplayData for database operations
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    try {
        System.out.println("DEBUG - Saving chat controls for patient: " + realPatientId);
        System.out.println("DEBUG - Daily limit: " + dailyChatLimit);
        System.out.println("DEBUG - Max duration: " + maxSessionDuration);
        System.out.println("DEBUG - Min interval: " + minSessionInterval);
        System.out.println("DEBUG - Start time: " + blackoutStartTime);
        System.out.println("DEBUG - End time: " + blackoutEndTime);
        System.out.println("DEBUG - Blackout days: " + blackoutDays);
        
        // Call the saveChatControlSettings method
        boolean success = rd.saveChatControlSettings(
            realPatientId, 
            dailyChatLimit, 
            maxSessionDuration, 
            minSessionInterval, 
            blackoutStartTime, 
            blackoutEndTime, 
            blackoutDays
        );
        
        if (success) {
            jsonResponse.put("success", true);
            jsonResponse.put("message", "Chat control settings saved successfully!");
            System.out.println("DEBUG - Chat control settings saved successfully for patient: " + realPatientId);

            // ── Persist chat_type via rcDisplayData ─────────────────────────
            try {
                rd.saveChatType(realPatientId, chatType);
                System.out.println("DEBUG - chat_type '" + chatType + "' saved for " + realPatientId);
            } catch (Exception chatTypeEx) {
                System.out.println("WARNING - Could not save chat_type: " + chatTypeEx.getMessage());
            }

        } else {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Failed to save chat control settings. Please try again.");
            System.out.println("DEBUG - Failed to save chat control settings for patient: " + realPatientId);
        }
        
    } catch (Exception e) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Database error: " + e.getMessage());
        System.out.println("ERROR - Exception in saveChatControlSettings: " + e.getMessage());
        e.printStackTrace();
    }
    
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Error: " + e.getMessage());
    System.out.println("ERROR - General exception: " + e.getMessage());
    e.printStackTrace();
}

out.print(jsonResponse.toJSONString());
%> 




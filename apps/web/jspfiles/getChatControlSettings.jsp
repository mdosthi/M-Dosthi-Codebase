<%@page contentType="application/json" import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,java.sql.*,java.rmi.RemoteException" %>
<%!
/** Fetch chat_type from chat_control for a given patient via rcDisplayData; returns "original" on any error. */
String fetchChatType(rcDisplayData rd, String patId) {
    try {
        return rd.getChatType(patId);
    } catch (Exception e) {
        System.out.println("DEBUG getChatType: " + e.getMessage());
    }
    return "original";
}
%>
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
    
    // Get the actual patient ID
    String patId = request.getParameter("pat_id");
    
    System.out.println("DEBUG - Session token: " + sessionToken);
    System.out.println("DEBUG - Received pat_id parameter: " + patId);
    
    // Determine the real patient ID
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
            // Method 2: Look up patient ID from session token
            // You might need to query a session table or login table
            try {
                rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
                
                // Try to find patient ID from login table using session token
                // This assumes you have a way to map session tokens to patient IDs
                // You might need to modify this query based on your actual table structure
                String lookupSql = "SELECT uid FROM login WHERE session_token = '" + sessionToken + "' OR uid = '" + sessionToken + "'";
                System.out.println("DEBUG - Attempting to lookup patient ID with session token");
                
                // Since we don't have a direct way to execute custom SQL through rcDisplayData,
                // let's try a different approach - check if there are any other cookies
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
    
    // Use rcDisplayData for database operations (following your existing pattern)
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    try {
        System.out.println("DEBUG - Calling getChatControlSettings for patId: " + realPatientId);
        
        // Call the existing method from rcDisplayData
        Object result = rd.getChatControlSettings(realPatientId);
        
        System.out.println("DEBUG - Result from getChatControlSettings: " + result);
        
        if (result instanceof String) {
            // If result is a string, it's likely an error message
            System.out.println("DEBUG - String result (likely error): " + result);
            
            // Return default values when no record exists
            JSONObject data = new JSONObject();
            data.put("pat_id", realPatientId);
            data.put("daily_chat_limit", 3);
            data.put("max_session_duration", 1800);
            data.put("min_session_interval", 3600);
            data.put("blackout_start_time", null);
            data.put("blackout_end_time", null);
            data.put("blackout_days", null);
            data.put("chat_type", fetchChatType(rd, realPatientId));

            jsonResponse.put("success", true);
            jsonResponse.put("data", data);
            jsonResponse.put("message", "No existing settings found. Default values loaded.");
            
        } else if (result instanceof Vector) {
            Vector resultVector = (Vector) result;
            System.out.println("DEBUG - Vector result size: " + resultVector.size());
            
            if (resultVector.size() > 0) {
                // Extract data from the first record
                dataobj dataRecord = (dataobj) resultVector.get(0);
                
                JSONObject data = new JSONObject();
                data.put("pat_id", dataRecord.getValue("pat_id"));
                
                // Parse numeric values with defaults
                try {
                    data.put("daily_chat_limit", Integer.parseInt(dataRecord.getValue("daily_chat_limit")));
                } catch (Exception e) {
                    data.put("daily_chat_limit", 3);
                }
                
                try {
                    data.put("max_session_duration", Integer.parseInt(dataRecord.getValue("max_session_duration")));
                } catch (Exception e) {
                    data.put("max_session_duration", 1800);
                }
                
                try {
                    data.put("min_session_interval", Integer.parseInt(dataRecord.getValue("min_session_interval")));
                } catch (Exception e) {
                    data.put("min_session_interval", 3600);
                }
                
                // Handle potentially null time values
                String startTime = dataRecord.getValue("blackout_start_time");
                String endTime = dataRecord.getValue("blackout_end_time");
                String blackoutDays = dataRecord.getValue("blackout_days");
                
                data.put("blackout_start_time", (startTime != null && !startTime.trim().isEmpty()) ? startTime : null);
                data.put("blackout_end_time", (endTime != null && !endTime.trim().isEmpty()) ? endTime : null);
                data.put("blackout_days", (blackoutDays != null && !blackoutDays.trim().isEmpty()) ? blackoutDays : null);

                data.put("chat_type", fetchChatType(rd, realPatientId));

                jsonResponse.put("success", true);
                jsonResponse.put("data", data);
                jsonResponse.put("message", "Settings loaded successfully.");
                
                System.out.println("DEBUG - Successfully parsed data: " + data.toJSONString());
                
            } else {
                // No records found, return defaults
                JSONObject data = new JSONObject();
                data.put("pat_id", realPatientId);
                data.put("daily_chat_limit", 3);
                data.put("max_session_duration", 1800);
                data.put("min_session_interval", 3600);
                data.put("blackout_start_time", null);
                data.put("blackout_end_time", null);
                data.put("blackout_days", null);
                data.put("chat_type", fetchChatType(rd, realPatientId));

                jsonResponse.put("success", true);
                jsonResponse.put("data", data);
                jsonResponse.put("message", "No existing settings found. Default values loaded.");
                
                System.out.println("DEBUG - No records found, returning defaults");
            }
        } else {
            // Unexpected result type
            System.out.println("DEBUG - Unexpected result type: " + (result != null ? result.getClass().getName() : "null"));
            
            JSONObject data = new JSONObject();
            data.put("pat_id", realPatientId);
            data.put("daily_chat_limit", 3);
            data.put("max_session_duration", 1800);
            data.put("min_session_interval", 3600);
            data.put("blackout_start_time", null);
            data.put("blackout_end_time", null);
            data.put("blackout_days", null);
            data.put("chat_type", fetchChatType(rd, realPatientId));

            jsonResponse.put("success", true);
            jsonResponse.put("data", data);
            jsonResponse.put("message", "Unexpected data format. Default values loaded.");
        }
        
    } catch (RemoteException re) {
        System.out.println("DEBUG - RemoteException: " + re.getMessage());
        re.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Remote service error: " + re.getMessage());
        
    } catch (SQLException sqle) {
        System.out.println("DEBUG - SQLException: " + sqle.getMessage());
        sqle.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Database error: " + sqle.getMessage());
        
    } catch (Exception e) {
        System.out.println("DEBUG - General Exception: " + e.getMessage());
        e.printStackTrace();
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Error retrieving settings: " + e.getMessage());
    }
    
} catch (Exception e) {
    System.out.println("DEBUG - Outer Exception: " + e.getMessage());
    e.printStackTrace();
    jsonResponse.put("success", false);
    jsonResponse.put("message", "System error: " + e.getMessage());
}

out.print(jsonResponse.toJSONString());
%>

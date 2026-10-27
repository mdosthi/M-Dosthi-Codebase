<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="javafiles.*" %>
<%@ page import="org.json.simple.*" %>

<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject jsonResponse = new JSONObject();

try {
    String action = request.getParameter("action");
    String patId = request.getParameter("pat_id");
    String fromDate = request.getParameter("from_date");
    String toDate = request.getParameter("to_date");
    
    if (patId == null || patId.trim().isEmpty()) {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Patient ID is required");
        out.print(jsonResponse.toJSONString());
        return;
    }
    
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    if ("getEngagementMetrics".equals(action)) {
        // Get engagement metrics
        String sql = "SELECT " +
                     "DATE(session_date) as session_day, " +
                     "COUNT(*) as sessions_count, " +
                     "AVG(duration) as avg_duration, " +
                     "SUM(duration) as total_duration, " +
                     "COUNT(CASE WHEN session_status = 'completed' THEN 1 END) as completed_sessions " +
                     "FROM chat_sessions WHERE pat_id = '" + patId + "' ";
        
        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
            sql += "AND session_date BETWEEN '" + fromDate + "' AND '" + toDate + "' ";
        }
        
        sql += "GROUP BY DATE(session_date) ORDER BY session_day DESC LIMIT 30";
        
        Object result = rd.mydb.ExecuteQuary(sql);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector data = (Vector) result;
            JSONArray metrics = new JSONArray();
            
            for (int i = 0; i < data.size(); i++) {
                dataobj row = (dataobj) data.get(i);
                JSONObject metric = new JSONObject();
                
                metric.put("date", row.getValue(0));
                metric.put("sessions_count", row.getValue(1));
                metric.put("avg_duration", row.getValue(2));
                metric.put("total_duration", row.getValue(3));
                metric.put("completed_sessions", row.getValue(4));
                
                metrics.add(metric);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("metrics", metrics);
        }
        
    } else if ("getMessageAnalytics".equals(action)) {
        // Get message analytics
        String sql = "SELECT " +
                     "cs.session_date, " +
                     "cs.session_id, " +
                     "COUNT(cm.message_id) as total_messages, " +
                     "SUM(CASE WHEN cm.sender_type = 'patient' THEN 1 ELSE 0 END) as patient_messages, " +
                     "SUM(CASE WHEN cm.sender_type = 'bot' THEN 1 ELSE 0 END) as bot_messages, " +
                     "AVG(LENGTH(cm.message_content)) as avg_message_length " +
                     "FROM chat_sessions cs " +
                     "LEFT JOIN chat_messages cm ON cs.session_id = cm.session_id " +
                     "WHERE cs.pat_id = '" + patId + "' ";
        
        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
            sql += "AND cs.session_date BETWEEN '" + fromDate + "' AND '" + toDate + "' ";
        }
        
        sql += "GROUP BY cs.session_id, cs.session_date ORDER BY cs.session_date DESC";
        
        Object result = rd.mydb.ExecuteQuary(sql);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector data = (Vector) result;
            JSONArray analytics = new JSONArray();
            
            for (int i = 0; i < data.size(); i++) {
                dataobj row = (dataobj) data.get(i);
                JSONObject analytic = new JSONObject();
                
                analytic.put("session_date", row.getValue(0));
                analytic.put("session_id", row.getValue(1));
                analytic.put("total_messages", row.getValue(2));
                analytic.put("patient_messages", row.getValue(3));
                analytic.put("bot_messages", row.getValue(4));
                analytic.put("avg_message_length", row.getValue(5));
                
                analytics.add(analytic);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("analytics", analytics);
        }
        
    } else if ("getResponseTimeAnalytics".equals(action)) {
        // Get response time analytics
        String sql = "SELECT " +
                     "AVG(response_time) as avg_response_time, " +
                     "MIN(response_time) as min_response_time, " +
                     "MAX(response_time) as max_response_time, " +
                     "COUNT(CASE WHEN response_time IS NOT NULL THEN 1 END) as responses_with_time " +
                     "FROM chat_messages cm " +
                     "JOIN chat_sessions cs ON cm.session_id = cs.session_id " +
                     "WHERE cs.pat_id = '" + patId + "' AND cm.response_time IS NOT NULL ";
        
        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
            sql += "AND cs.session_date BETWEEN '" + fromDate + "' AND '" + toDate + "' ";
        }
        
        Object result = rd.mydb.ExecuteQuary(sql);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector data = (Vector) result;
            if (data.size() > 0) {
                dataobj row = (dataobj) data.get(0);
                JSONObject responseTime = new JSONObject();
                
                responseTime.put("avg_response_time", row.getValue(0));
                responseTime.put("min_response_time", row.getValue(1));
                responseTime.put("max_response_time", row.getValue(2));
                responseTime.put("responses_with_time", row.getValue(3));
                
                jsonResponse.put("success", true);
                jsonResponse.put("response_time_analytics", responseTime);
            } else {
                jsonResponse.put("success", true);
                jsonResponse.put("response_time_analytics", new JSONObject());
            }
        }
        
    } else if ("getUsagePatterns".equals(action)) {
        // Get usage patterns by hour and day of week
        String sql = "SELECT " +
                     "HOUR(start_time) as hour_of_day, " +
                     "DAYNAME(session_date) as day_of_week, " +
                     "COUNT(*) as session_count " +
                     "FROM chat_sessions " +
                     "WHERE pat_id = '" + patId + "' ";
        
        if (fromDate != null && !fromDate.trim().isEmpty() && toDate != null && !toDate.trim().isEmpty()) {
            sql += "AND session_date BETWEEN '" + fromDate + "' AND '" + toDate + "' ";
        }
        
        sql += "GROUP BY HOUR(start_time), DAYNAME(session_date) " +
               "ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), hour_of_day";
        
        Object result = rd.mydb.ExecuteQuary(sql);
        
        if (result instanceof String) {
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error: " + result);
        } else {
            Vector data = (Vector) result;
            JSONArray patterns = new JSONArray();
            
            for (int i = 0; i < data.size(); i++) {
                dataobj row = (dataobj) data.get(i);
                JSONObject pattern = new JSONObject();
                
                pattern.put("hour_of_day", row.getValue(0));
                pattern.put("day_of_week", row.getValue(1));
                pattern.put("session_count", row.getValue(2));
                
                patterns.add(pattern);
            }
            
            jsonResponse.put("success", true);
            jsonResponse.put("usage_patterns", patterns);
        }
        
    } else {
        jsonResponse.put("success", false);
        jsonResponse.put("message", "Invalid action");
    }
    
} catch (Exception e) {
    jsonResponse.put("success", false);
    jsonResponse.put("message", "Database error: " + e.getMessage());
    System.out.println("ERROR - Exception in getChatAnalytics: " + e.getMessage());
    e.printStackTrace();
}

out.print(jsonResponse.toJSONString());
%>
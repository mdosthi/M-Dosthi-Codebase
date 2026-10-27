<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="javafiles.*" %>

<%
String sessionId = request.getParameter("session_id");
String format = request.getParameter("format"); // "txt" or "csv"
String patId = request.getParameter("pat_id");

if (sessionId == null || sessionId.trim().isEmpty()) {
    out.print("Error: Session ID is required");
    return;
}

if (format == null || format.trim().isEmpty()) {
    format = "txt";
}

try {
    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    
    // Get session details
    Object sessionResult = rd.getChatSessions(patId);
    Object messagesResult = rd.getChatMessages(sessionId);
    
    if (messagesResult instanceof String) {
        out.print("Error retrieving messages: " + messagesResult);
        return;
    }
    
    Vector messages = (Vector) messagesResult;
    
    // Set appropriate content type and filename
    String filename = "chat_session_" + sessionId + "." + format;
    
    if ("csv".equals(format)) {
        response.setContentType("text/csv");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        
        // CSV Export
        out.println("Message Sequence,Sender Type,Timestamp,Message Content");
        
        for (int i = 0; i < messages.size(); i++) {
            dataobj messageData = (dataobj) messages.get(i);
            
            String sequence = messageData.getValue(1) != null ? messageData.getValue(1).toString() : "";
            String senderType = messageData.getValue(2) != null ? messageData.getValue(2).toString() : "";
            String timestamp = messageData.getValue(4) != null ? messageData.getValue(4).toString() : "";
            String content = messageData.getValue(3) != null ? messageData.getValue(3).toString() : "";
            
            // Escape CSV content
            content = content.replace("\"", "\"\"");
            if (content.contains(",") || content.contains("\"") || content.contains("\n")) {
                content = "\"" + content + "\"";
            }
            
            out.println(sequence + "," + senderType + "," + timestamp + "," + content);
        }
        
    } else {
        // Text Export
        response.setContentType("text/plain");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        
        out.println("CHAT SESSION EXPORT");
        out.println("===================");
        out.println("Session ID: " + sessionId);
        out.println("Patient ID: " + patId);
        out.println("Export Date: " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        out.println("Total Messages: " + messages.size());
        out.println("");
        out.println("CONVERSATION:");
        out.println("=============");
        
        for (int i = 0; i < messages.size(); i++) {
            dataobj messageData = (dataobj) messages.get(i);
            
            String sequence = messageData.getValue(1) != null ? messageData.getValue(1).toString() : "";
            String senderType = messageData.getValue(2) != null ? messageData.getValue(2).toString() : "";
            String timestamp = messageData.getValue(4) != null ? messageData.getValue(4).toString() : "";
            String content = messageData.getValue(3) != null ? messageData.getValue(3).toString() : "";
            
            out.println("");
            out.println("[" + sequence + "] " + senderType.toUpperCase() + " (" + timestamp + "):");
            out.println(content);
            out.println("---");
        }
        
        out.println("");
        out.println("END OF CONVERSATION");
    }
    
} catch (Exception e) {
    out.print("Error generating export: " + e.getMessage());
    e.printStackTrace();
}
%>
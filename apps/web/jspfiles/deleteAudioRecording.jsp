<%@page contentType="text/html" import="java.io.*,java.util.*,java.sql.*,imedix.projinfo,imedix.cook,imedix.rcDataEntryFrm,imedix.dataobj" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    // Get parameters
    String recordingId = request.getParameter("id");
    String patId = request.getParameter("patId");
    
    // Check user permissions
    cook cookx = new cook();
    String usertype = cookx.getCookieValue("usertype", request.getCookies());
    
    if (usertype.equals("PAT")) {
        out.println("Permission denied");
        return;
    }
    
    if (recordingId != null && patId != null) {
        try {
            rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
            
            // Delete recording
            boolean success = rcdef.deleteAudioRecording(Integer.parseInt(recordingId), patId);
            
            if (success) {
                out.println("success");
            } else {
                out.println("Failed to delete recording");
            }
        } catch (Exception e) {
            out.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    } else {
        out.println("Missing required parameters");
    }
%>
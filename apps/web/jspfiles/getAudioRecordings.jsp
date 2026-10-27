<%@page contentType="text/html" import="java.io.*,java.util.*,java.sql.*,java.text.SimpleDateFormat,imedix.projinfo,imedix.cook,imedix.rcDataEntryFrm,imedix.dataobj" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    // Get patient ID
    String patId = request.getParameter("patId");
    if (patId == null || patId.isEmpty()) {
        cook cookx = new cook();
        patId = cookx.getCookieValue("patid", request.getCookies());
    }
    
    // Get rcDataEntryFrm instance
    rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
    projinfo pinfo = new projinfo(request.getRealPath("/"));
    
    try {
        // Get recordings for this patient
        Object result = rcdef.getAudioRecordings(patId);
        
        boolean hasRecordings = false;
        
        if (result instanceof Vector) {
            Vector recordings = (Vector) result;
            
            if (recordings.size() > 0) {
                hasRecordings = true;
                
                for (int i = 0; i < recordings.size(); i++) {
                    dataobj recording = (dataobj) recordings.get(i);
                    String id = recording.getValue("id");
                    String filePath = recording.getValue("file_path");
                    String description = recording.getValue("description");
                    String recordedDateStr = recording.getValue("recorded_date");
                    
                    // Format dates nicely
                    String formattedRecordedDate = recordedDateStr;
                    try {
                        if (recordedDateStr != null && recordedDateStr.length() >= 10) {
                            formattedRecordedDate = recordedDateStr.substring(8, 10) + "/" + 
                                                    recordedDateStr.substring(5, 7) + "/" + 
                                                    recordedDateStr.substring(0, 4);
                        }
                    } catch (Exception e) {
                        // Use original format if parsing fails
                    }
                    
                    // Output HTML for this recording
                    %>
                    <div class="audio-card" id="audio-card-<%=id%>">
                        <div class="audio-title"><%=description%></div>
                        <div class="audio-meta">Session Date: <%=formattedRecordedDate%></div>
                        <div class="audio-controls">
                            <button id="play-btn-<%=id%>" class="btn btn-primary btn-sm" onclick="playAudio(<%=id%>)">
                                <span class="glyphicon glyphicon-play"></span>
                            </button>
                            <audio id="audio-player-<%=id%>" class="audio-player" controls onended="$('#play-btn-<%=id%>').html('<span class=\'glyphicon glyphicon-play\'></span>')">
                                <source src="playAudio.jsp?patId=<%=patId%>&file=<%=filePath.substring(filePath.lastIndexOf("/")+1)%>" type="audio/mpeg">
                                Your browser does not support the audio element.
                            </audio>
                            <% 
                            // Check user type
                            cook cookx = new cook();
                            String usertype = cookx.getCookieValue("usertype", request.getCookies());
                            if (!usertype.equals("PAT")) { 
                            %>
                                <span class="delete-recording" onclick="deleteRecording(<%=id%>)">
                                    <span class="glyphicon glyphicon-trash"></span> Delete
                                </span>
                            <% } %>
                        </div>
                    </div>
                    <%
                }
            }
        }
        
        if (!hasRecordings) {
            %>
            <div class="alert alert-info">No recordings available for this patient</div>
            <%
        }
        
    } catch (Exception e) {
        out.println("<div class='alert alert-danger'>Error loading recordings: " + e.getMessage() + "</div>");
        e.printStackTrace();
    }
%>
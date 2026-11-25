<%@ page contentType="audio/mpeg" %>
<%@ page import="java.io.*,java.util.*,imedix.cook,imedix.Crypto" %>
<%
    // Authentication check (extracted from chkcook.jsp)
    cook cookx = new cook();
    String userid = cookx.getCookieValue("userid", request.getCookies());
    String username = cookx.getCookieValue("username", request.getCookies());
    String usertype = cookx.getCookieValue("usertype", request.getCookies());
    String center = cookx.getCookieValue("center", request.getCookies());
    String isReadOnly = cookx.getCookieValue("isReadOnly", request.getCookies());
    String active = cookx.getCookieValue("active", request.getCookies());
    
    // Check if user is authenticated
    if(userid == null || userid.equals("")) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    // Process the audio file request
    String fileName = request.getParameter("file");
    String patId = request.getParameter("patId");
    
    if (fileName != null && patId != null) {
        try {
            // Construct the file path
            String filePath = application.getRealPath("/data/" + patId + "/audio/" + fileName);
            File file = new File(filePath);
            
            if (file.exists()) {
                // Set appropriate content type based on file extension
                String contentType = "audio/mpeg";
                if (fileName.toLowerCase().endsWith(".wav")) {
                    contentType = "audio/wav";
                } else if (fileName.toLowerCase().endsWith(".ogg")) {
                    contentType = "audio/ogg";
                }
                response.setContentType(contentType);
                
                // Set content length
                response.setContentLength((int)file.length());
                
                // Copy the file to the output stream
                FileInputStream in = new FileInputStream(file);
                OutputStream out_put = response.getOutputStream();
                
                byte[] buffer = new byte[4096];
                int bytesRead = -1;
                
                while ((bytesRead = in.read(buffer)) != -1) {
                    out_put.write(buffer, 0, bytesRead);
                }
                
                in.close();
                out_put.close();
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    } else {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST);
    }
%>
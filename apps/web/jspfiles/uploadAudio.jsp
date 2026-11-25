<%@page contentType="text/html" import="java.io.*,java.util.*,java.sql.*,java.text.SimpleDateFormat,org.apache.commons.fileupload.*,org.apache.commons.fileupload.disk.*,org.apache.commons.fileupload.servlet.*,imedix.projinfo,imedix.cook,imedix.myDate,imedix.rcDataEntryFrm,imedix.dataobj" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    // Get patient ID from cookie
    cook cookx = new cook();
    String patId = request.getParameter("pat_id");
    if (patId == null || patId.isEmpty()) {
        patId = cookx.getCookieValue("patid", request.getCookies());
    }
    String uid = cookx.getCookieValue("userid", request.getCookies());
    
    // Get project info for file path
    projinfo pinfo = new projinfo(request.getRealPath("/"));
    String audioDir = request.getRealPath("/data/" + patId + "/audio");
    
    // Enhanced directory creation with better error handling
    File audioDirFile = new File(audioDir);
    if (!audioDirFile.exists()) {
        System.out.println("Debug - Creating directory at: " + audioDir);
        boolean dirCreated = audioDirFile.mkdirs();
        System.out.println("Debug - Directory creation result: " + dirCreated);
        
        if (!dirCreated) {
            // If mkdirs() fails, try creating the parent directories one by one
            File parentDir = new File(request.getRealPath("/data/" + patId));
            if (!parentDir.exists()) {
                boolean parentCreated = parentDir.mkdirs();
                System.out.println("Debug - Parent directory creation result: " + parentCreated);
            }
            boolean audioCreated = audioDirFile.mkdir();
            System.out.println("Debug - Audio directory creation result: " + audioCreated);
        }
        
        // Double-check if directory now exists
        if (!audioDirFile.exists()) {
            System.out.println("Error: Could not create directory " + audioDir);
            out.println("Error: Could not create directory for audio files");
            return;
        }
    } else {
        System.out.println("Debug - Directory already exists: " + audioDir);
    }
    
    // Get current timestamp for filename
    SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss");
    String timestamp = sdf.format(new java.util.Date());
    
    // Process the uploaded file
    boolean isMultipart = ServletFileUpload.isMultipartContent(request);
    if (isMultipart) {
        FileItemFactory factory = new DiskFileItemFactory();
        ServletFileUpload upload = new ServletFileUpload(factory);
        
        try {
            List<FileItem> items = upload.parseRequest(request);
            String description = "";
            String sessionDate = "";
            String fileName = "";
            FileItem audioFile = null;
            
            for (FileItem item : items) {
                if (item.isFormField()) {
                    if (item.getFieldName().equals("audiodesc")) {
                        description = item.getString();
                    } else if (item.getFieldName().equals("sessiondate")) {
                        sessionDate = item.getString();
                    } else if (item.getFieldName().equals("pat_id")) {
                        patId = item.getString();
                    }
                } else {
                    if (item.getFieldName().equals("audiofile")) {
                        audioFile = item;
                        fileName = timestamp + "_" + new File(item.getName()).getName();
                    }
                }
            }
            
            // Save the file with enhanced error handling
            if (audioFile != null && !fileName.isEmpty()) {
                File uploadedFile = new File(audioDir + File.separator + fileName);
                System.out.println("Debug - Saving file to: " + uploadedFile.getAbsolutePath());
                
                audioFile.write(uploadedFile);
                
                // Verify file was saved correctly
                if (!uploadedFile.exists() || uploadedFile.length() == 0) {
                    System.out.println("Error: File was not saved correctly at " + uploadedFile.getAbsolutePath());
                    out.println("Error: File was not saved correctly");
                    return;
                }
                
                System.out.println("Debug - File saved successfully, exists: " + uploadedFile.exists() + ", size: " + uploadedFile.length() + " bytes");
                
                // Save to database using our new method
                rcDataEntryFrm rcdef = new rcDataEntryFrm(request.getRealPath("/"));
                
                dataobj obj = new dataobj();
                obj.add("pat_id", patId);
                obj.add("audiodesc", description);
                obj.add("file_path", "audio/" + fileName);
                obj.add("sessiondate", sessionDate);
                obj.add("userid", uid);
                
                boolean success = rcdef.saveAudioRecording(obj);
                System.out.println("Debug - Database save result: " + success);
                
                if (success) {
                    out.println("success");
                } else {
                    out.println("Error saving to database");
                }
            } else {
                out.println("No file uploaded");
            }
        } catch (Exception e) {
            System.out.println("Error in uploadAudio.jsp: " + e.getMessage());
            e.printStackTrace();
            out.println("Error: " + e.getMessage());
        }
    } else {
        out.println("Not a multipart request");
    }
%>
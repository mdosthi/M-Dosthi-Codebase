<%@page contentType="text/html" import= "imedix.dataobj,imedix.projinfo,imedix.rcDataEntryFrm,java.net.URLConnection,javax.net.ssl.*,java.text.*,imedix.rcDisplayData,java.io.*,java.util.*,org.json.simple.JSONObject,org.json.simple.parser.JSONParser,org.json.simple.JSONArray,java.nio.charset.Charset,java.io.BufferedReader,java.io.IOException ,java.io.InputStreamReader,java.io.OutputStream,java.net.HttpURLConnection,java.net.MalformedURLException,java.net.URL"%>
<%@ include file="..//includes/chkcook.jsp" %>
<!-- CORRECTED VERSION with Submission Type Tracking -->
<%
cook cookx = new cook();
rcDisplayData rdd = new rcDisplayData(request.getRealPath("/"));
String patId = request.getParameter("patId");
if (patId == null || patId.isEmpty()){
    patId = cookx.getCookieValue("patId", request.getCookies());
}

String userId;
userId = patId;
String ccode = cookx.getCookieValue("center", request.getCookies());
String utype = cookx.getCookieValue("usertype", request.getCookies());
String surveyName = request.getParameter("survey");
String s_id = request.getParameter("sid");
JSONParser parser = new JSONParser();

// Handle form submission
String message = "";

if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("submit_survey") != null) {
    try {
        // Debug
        System.out.println("Form submission detected");
        
        // Collect all form responses
        JSONObject responses = new JSONObject();
        Enumeration<String> paramNames = request.getParameterNames();
        
        while (paramNames.hasMoreElements()) {
            String paramName = paramNames.nextElement();
            if (!paramName.equals("submit_survey") && !paramName.equals("survey_sid") && !paramName.equals("patId")) {
                responses.put(paramName, request.getParameter(paramName));
                System.out.println("Form param: " + paramName + " = " + request.getParameter(paramName));
            }
        }
        
        // Get survey sid from form
        String formSurveyId = request.getParameter("survey_sid");
        String formPatId = request.getParameter("patId");
        
        // Determine who is submitting based on usertype cookie
        String submittedBy = "patient"; // default
        if (utype != null && !utype.isEmpty()) {
            String utypeLower = utype.toLowerCase().trim(); // normalize
            if (utypeLower.equals("psy")) {
                submittedBy = "psychologist";
            } else if (utypeLower.equals("adm") || utypeLower.equals("doc")) {
                submittedBy = "admin";
            } else if (utypeLower.equals("pat")) {
                submittedBy = "patient";
            } else if (utypeLower.equals("opr") || utypeLower.equals("usr")) {
                submittedBy = "staff";
            } else {
                submittedBy = "patient"; // fallback
            }
        }
        
        System.out.println("surveyID: " + formSurveyId);
        System.out.println("patientID: " + formPatId);
        System.out.println("userType from cookie: " + utype);
        System.out.println("submittedBy: " + submittedBy);
        System.out.println("responses: " + responses.toString());
        System.out.println("Saving survey - Survey ID: " + formSurveyId + ", Patient ID: " + formPatId);
        
        // Save to database with submittedBy parameter
        boolean saved = rdd.saveSurveyResponse(formPatId, formSurveyId, responses.toString(), userId, submittedBy);
        
        if (saved) {
            message = "<div class='alert alert-success'>Survey submitted successfully!</div>";
            System.out.println("Survey saved successfully");
        } else {
            message = "<div class='alert alert-danger'>Error submitting survey. Please try again.</div>";
            System.out.println("Failed to save survey");
        }
    } catch (Exception e) {
        message = "<div class='alert alert-danger'>Error: " + e.getMessage() + "</div>";
        System.out.println("Exception in form submission: " + e.toString());
        e.printStackTrace();
    }
}

// Fetch survey data based on name or sid
Object surveyData = null;

// Debug: Print what parameters we received
System.out.println("=== SURVEY PAGE DEBUG ===");
System.out.println("surveyName parameter: " + surveyName);
System.out.println("s_id parameter: " + s_id);
System.out.println("patId: " + patId);
System.out.println("utype: " + utype);
System.out.println("========================");

if (surveyName != null && !surveyName.isEmpty()) {
    System.out.println("Fetching survey by name: " + surveyName);
    surveyData = rdd.getSurveyFormDetails(surveyName);
} else if (s_id != null && !s_id.isEmpty()) {
    System.out.println("Fetching survey by sid: " + s_id);
    surveyData = rdd.getSurveyFormBySid(s_id);
} else {
    // If no specific survey is requested, show the list of prescribed surveys
    System.out.println("No specific survey requested, fetching prescribed surveys for patient: " + patId);
    surveyData = rdd.getPatientPrescribedSurveys(patId);
}
%>

<html>
<head>
    <title>Assesment</title>
    <link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
    <script src="../bootstrap/jquery-2.2.1.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>

    <script>
    function audio_drop_evt(evt) {
        evt.preventDefault();
        try {
            document.getElementById("audioFile").files = evt.dataTransfer.files;
            var fileName = evt.dataTransfer.files[0].name;
            var fileType = evt.dataTransfer.files[0].type;
            
            // Check if file is audio
            if (!fileType.startsWith('audio/')) {
                alert("Please select an audio file");
                document.getElementById("audioFile").value = "";
                document.getElementById("audio_drop_div_html").innerHTML = "Drop Audio File Here or Click to Select";
                return;
            }
            
            document.getElementById("audio_drop_div_html").innerHTML = fileName + "<br><center>" + audioFileSizeCheck() + "</center>";
        } catch(err) {
            console.error("Error handling file drop", err);
        }
    }

    // General drop event handler for drag and drop
    function drop_evt(evt) {
        evt.preventDefault();
        try {
            if (evt.target.id === "audio_drop_div" || $(evt.target).parents("#audio_drop_div").length > 0) {
                audio_drop_evt(evt);
            }
        } catch(err) {
            console.error("Error in drop event", err);
        }
    }

    function dragOver_evt(evt) {
        evt.preventDefault();
    }

    // Audio file size checking
    function audioFileSizeCheck() {
        var sizeinbytes = document.getElementById('audioFile').files[0].size;
        var sizeMB = sizeinbytes / (1024 * 1024);
        if (sizeMB > 50) {
            document.getElementById('audioFile').value = "";
            return "Please upload an audio file smaller than 50 MB";
        }
        return sizeMB.toFixed(2) + " MB";
    }

    // Audio file validation
    function audioFileCheck() {
        if (document.getElementById('audioFile').value == "" || document.getElementById('audioFile').value == null) {
            alert("Please select an audio file");
            return false;
        }
        
        var file = document.getElementById('audioFile').files[0];
        var fileType = file.type;
        
        if (!fileType.startsWith('audio/')) {
            alert("Please select a valid audio file");
            return false;
        }
        
        if ($("input[name=audiodesc]").val().trim() === "") {
            alert("Please enter a session description");
            return false;
        }
        
        if ($("input[name=sessiondate]").val() === "") {
            alert("Please select a session date");
            return false;
        }
        
        return true;
    }

    // Function to play audio
    function playAudio(audioId) {
        var audioPlayer = document.getElementById("audio-player-" + audioId);
        alert("Do you want to listen to this audio?")
        console.log(audioPlayer);
        if (audioPlayer.paused) {
            audioPlayer.play();
            $("#play-btn-" + audioId).html('<span class="glyphicon glyphicon-pause"></span>');
        } else {
            audioPlayer.pause();
            $("#play-btn-" + audioId).html('<span class="glyphicon glyphicon-play"></span>');
        }
    }

    // Function to delete recording
    function deleteRecording(recordingId) {
        if (confirm("Are you sure you want to delete this recording?")) {
            $.ajax({
                type: "POST",
                url: "deleteAudioRecording.jsp",
                data: { id: recordingId, patId: "<%= patId %>" },
                success: function(data) {
                    if (data.trim() === "success") {
                        $("#audio-card-" + recordingId).fadeOut(300, function() {
                            $(this).remove();
                        });
                    } else {
                        alert("Error deleting recording: " + data);
                    }
                },
                error: function() {
                    alert("Error connecting to server");
                }
            });
        }
    }

    // Function to load audio recordings
    function loadAudioRecordings() {
        $.ajax({
            type: "GET",
            url: "getAudioRecordings.jsp",
            data: { patId: "<%= patId %>" },
            success: function(data) {
                $(".audio-files-list").html(data);
            },
            error: function() {
                $(".audio-files-list").html("<div class='alert alert-danger'>Error loading recordings</div>");
            }
        });
    }
    
    $(document).ready(function() {
        
        // Trigger modal when link is clicked
        $("#open-notes").click(function(e) {
            e.preventDefault();  // Prevent the default anchor behavior
    
            // Optional: You can load content from the server using Ajax
            var patId = '<%= patId %>';  // Or grab the ID dynamically if needed
            var url = "<%=request.getContextPath()%>/forms/psychologistNotes.jsp?patId=" + patId;
    
            // Load the content from the server into the modal
            $(".modal-body").load(url, function() {
                // Once content is loaded, show the modal
                $('#save_note').modal('show');
            });
        });

        var today = new Date().toISOString().split('T')[0];
        $("input[name=sessiondate]").val(today);
        // Load existing audio recordings
        loadAudioRecordings();
        // Handle audio form submission
        $("#audioUploadForm").submit(function(e) {
            e.preventDefault();
        
            if (!audioFileCheck()) return false;
        
            var formData = new FormData(this);
        
            // Show loading indicator
            $("#audio_drop_div_html").html("<div class='uploading-audio'>Uploading...<div class='progress'><div class='progress-bar progress-bar-striped active' role='progressbar' style='width:100%'></div></div></div>");
        
            $.ajax({
                type: "POST",
                enctype: "multipart/form-data",
                url: "uploadAudio.jsp",
                data: formData,
                processData: false,
                contentType: false,
                cache: false,
                timeout: 600000,
                success: function(response) {
                    // Reset form
                    $("#audio_drop_div_html").html("Drop Audio File Here or Click to Select");
                    $("#audioUploadForm")[0].reset();
                    $("input[name=sessiondate]").val(today);
                    
                    // Show success message
                    alert("Audio recording uploaded successfully!");
                    
                    // Reload audio recordings list
                    loadAudioRecordings();
                },
                error: function(xhr, status, error) {
                    console.error("Upload error:", error);
                    alert("Error uploading audio file: " + error);
                    $("#audio_drop_div_html").html("Drop Audio File Here or Click to Select");
                }
            });
        });
    });
    </script>
    <style>
        .survey-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .survey-title {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #ddd;
        }
        .survey-question {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .question-text {
            font-weight: bold;
            margin-bottom: 10px;
        }
        .radio-options label {
            display: block;
            margin-bottom: 5px;
        }
        .previous-results {
            margin-top: 30px;
        }
        .table-responsive {
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="row">
            
            <div id="save_note" class="modal fade" role="dialog">
                <div class="modal-dialog modal-lg" >

                <!-- Modal content-->
                <div class="modal-content" style="overflow-x: auto;overflow-y: auto; margin-right:2%;">
                    <div class="modal-header" >
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                        <h4 class="modal-title">Psychologist Notes</h4>
                    </div>
                    <div class="modal-body add-comp" style="margin-right:2%;" >
                        Body
                    </div>
                </div>
                </div>
            </div>


            <div class="col-md-12">
                <h1>Assesment Forms</h1>
                <a href="<%=request.getContextPath()%>/jspfiles/getPendingPatientPatho.jsp" class="btn btn-default"><i class="glyphicon glyphicon-arrow-left"></i> Back to Tests</a>
                <a href="#" id="open-notes" class="btn btn-info">
                    <i class="glyphicon glyphicon-pencil"></i>  Notes
                </a>
                <hr>
                
                <%= message %>
                
                <% if (surveyData instanceof String) { %>
                    <div class="alert alert-danger">Error: <%= surveyData %></div>
                <% } else { %>
                    <% 
                    Vector dataVector = (Vector)surveyData;
                    if (dataVector.size() > 0) {
                        
                        // Check if we're displaying a list of surveys
                        dataobj firstObj = (dataobj)dataVector.get(0);
                        if (firstObj.getKey(0).equals("slno")) {
                            // This is a list of prescribed surveys
                            %>
                            <div class="panel panel-primary">
                                <div class="panel-heading">
                                    <h3 class="panel-title">Prescribed Assesment Forms</h3>
                                </div>
                                <div class="panel-body">
                                    <table class="table table-striped">
                                        <thead>
                                            <tr>
                                                <th>Survey Name</th>
                                                <th>Description</th>
                                                <th>Action</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (int i = 0; i < dataVector.size(); i++) {
                                                dataobj survey = (dataobj)dataVector.get(i);
                                            %>
                                            <tr>
                                                <td><%= survey.getValue("name") %></td>
                                                <td><%= survey.getValue("description") %></td>
                                                <td>
                                                    <a href="tobaccoSurvey.jsp?sid=<%= survey.getValue("sid") %>&patId=<%= patId %>" class="btn btn-primary btn-sm">Fill Form</a>
                                                    <a href="tobaccoSurvey.jsp?sid=<%= survey.getValue("sid") %>&view=history&patId=<%= patId %>" class="btn btn-info btn-sm">View History</a>
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <%
                        } else {
                            // This is a specific survey to display
                            dataobj survey = (dataobj)dataVector.get(0);
                            String name = survey.getValue("name");
                            String description = survey.getValue("description");
                            String surveySid = survey.getValue("sid");
                            String templateSource = survey.getValue("template_source");
                            
                            // Check if we're viewing history
                            if (request.getParameter("view") != null && request.getParameter("view").equals("history")) {
                                Object responseData = rdd.getPatientSurveyResponses(patId);
                                if (responseData instanceof String) {
                                    %>
                                    <div class="alert alert-danger">Error retrieving response history: <%= responseData %></div>
                                    <%
                                } else {
                                    Vector responseVector = (Vector)responseData;
                                    %>
                                    <div class="panel panel-info">
                                        <div class="panel-heading">
                                            <h3 class="panel-title">Response History for <%= name %></h3>
                                        </div>
                                        <div class="panel-body">
                                            <% if (responseVector.size() > 0) { %>
                                                <div class="table-responsive">
                                                    <table class="table table-striped">
                                                        <thead>
                                                            <tr>
                                                                <th>Date & Time</th>
                                                                <th>Submitted By</th>
                                                                <th>Score</th>
                                                                <th>Responses</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                            <% for (int i = 0; i < responseVector.size(); i++) {
                                                                dataobj Response = (dataobj)responseVector.get(i);
                                                                String surveyDateTime = Response.getValue("survey_datetime");
                                                                String surveyDataStr = Response.getValue("survey_data");
                                                                String recordType = Response.getValue("record_type");
                                                                String score = Response.getValue("score");
                                                                
                                                                // Handle null or empty score
                                                                String scoreDisplay = (score != null && !score.isEmpty() && !score.equals("null")) 
                                                                    ? score 
                                                                    : "<span class='text-muted'>N/A</span>";
                                                                
                                                                // Determine display label for submission type
                                                                String submittedByLabel = "<span class='label label-default'>Unknown</span>";
                                                                if (recordType != null && !recordType.isEmpty()) {
                                                                    String recordTypeLower = recordType.toLowerCase().trim();
                                                                    if (recordTypeLower.equals("psychologist")) {
                                                                        submittedByLabel = "<span class='label label-info'><i class='glyphicon glyphicon-user'></i> Psychologist</span>";
                                                                    } else if (recordTypeLower.equals("admin")) {
                                                                        submittedByLabel = "<span class='label label-danger'><i class='glyphicon glyphicon-star'></i> Admin/Doctor</span>";
                                                                    } else if (recordTypeLower.equals("patient")) {
                                                                        submittedByLabel = "<span class='label label-success'><i class='glyphicon glyphicon-heart'></i> Patient</span>";
                                                                    } else if (recordTypeLower.equals("staff")) {
                                                                        submittedByLabel = "<span class='label label-warning'><i class='glyphicon glyphicon-briefcase'></i> Staff</span>";
                                                                    } else if (recordTypeLower.equals("0")) {
                                                                        // Handle legacy data
                                                                        submittedByLabel = "<span class='label label-default'>Patient</span>";
                                                                    }
                                                                }
                                                                
                                                                try {
                                                                    JSONObject surveyDataJson = (JSONObject)parser.parse(surveyDataStr);
                                                            %>
                                                            <tr>
                                                                <td><%= surveyDateTime %></td>
                                                                <td><%= submittedByLabel %></td>
                                                                <td><%= scoreDisplay %></td>
                                                                <td>
                                                                    <ul style="margin: 0; padding-left: 20px;">
                                                                        <% 
                                                                        Iterator<String> keys = surveyDataJson.keySet().iterator();
                                                                        while (keys.hasNext()) {
                                                                            String key = keys.next();
                                                                            String value = (String)surveyDataJson.get(key);
                                                                        %>
                                                                            <li><strong><%= key %>:</strong> <%= value %></li>
                                                                        <% } %>
                                                                    </ul>
                                                                </td>
                                                            </tr>
                                                            <% 
                                                                } catch (Exception e) {
                                                                    %>
                                                                    <tr>
                                                                        <td><%= surveyDateTime %></td>
                                                                        <td><%= submittedByLabel %></td>
                                                                        <td><%= scoreDisplay %></td>
                                                                        <td><span class='text-danger'>Error parsing response data: <%= e.getMessage() %></span></td>
                                                                    </tr>
                                                                    <%
                                                                }
                                                            } %>
                                                        </tbody>
                                                    </table>
                                                </div>
                                            <% } else { %>
                                                <div class="alert alert-info">No response history found for this survey.</div>
                                            <% } %>
                                            <a href="tobaccoSurvey.jsp?sid=<%= surveySid %>&patId=<%= patId %>" class="btn btn-primary">Fill Out Form</a>
                                            <a href="tobaccoSurvey.jsp?patId=<%= patId %>" class="btn btn-default">Back to Forms</a>
                                        </div>
                                    </div>
                                    <%
                                }
                            } else {
                                // Display the form for filling out
                                try {
                                    JSONObject templateJson = (JSONObject)parser.parse(templateSource);
                                    JSONArray questions = (JSONArray)templateJson.get("template_source");
                                %>
                                <div class="survey-container">
                                    <div class="survey-title">
                                        <h2><%= name %></h2>
                                        <p class="text-muted"><%= description %></p>
                                    </div>
                                    
                                    <form method="post" action="tobaccoSurvey.jsp">
                                        <input type="hidden" name="survey_sid" value="<%= surveySid %>">
                                        <input type="hidden" name="patId" value="<%= patId %>">
                                        
                                        <% for (int i = 0; i < questions.size(); i++) {
                                            JSONObject question = (JSONObject)questions.get(i);
                                            String questionText = (String)question.get("attrname");
                                            String questionType = (String)question.get("attrtype");
                                            String questionValues = (String)question.get("attrvalues");
                                            String[] options = questionValues.split(";");
                                        %>
                                        <div class="survey-question">
                                            <div class="question-text"><%= (i+1) %>. <%= questionText %></div>
                                            <div class="radio-options">
                                                <% if (questionType.equals("single")) { 
                                                    for (int j = 0; j < options.length; j++) {
                                                        if (options[j].trim().length() > 0) {
                                                %>
                                                    <label class="radio">
                                                        <input type="radio" name="<%= questionText %>" value="<%= options[j] %>" required>
                                                        <%= options[j] %>
                                                    </label>
                                                <% 
                                                        }
                                                    }
                                                } %>
                                            </div>
                                        </div>
                                        <% } %>
                                        
                                        <div class="form-group text-center">
                                            <button type="submit" name="submit_survey" value="true" class="btn btn-primary btn-lg">Submit Survey</button>
                                            <a href="tobaccoSurvey.jsp?patId=<%= patId %>" class="btn btn-default btn-lg">Cancel</a>
                                        </div>
                                    </form>
                                    
                                    <div class="previous-results">
                                        <a href="tobaccoSurvey.jsp?sid=<%= surveySid %>&view=history&patId=<%= patId %>" class="btn btn-info btn-block">View Previous Responses</a>
                                    </div>
                                </div>
                                <%
                                } catch (Exception e) {
                                    %>
                                    <div class="alert alert-danger">Error parsing survey template: <%= e.getMessage() %></div>
                                    <%
                                }
                            }
                        }
                    } else {
                        %>
                        <div class="alert alert-info">No survey data found.</div>
                        <%
                    }
                } %>
            </div>
        </div>
    </div>
    
<div class="upload-audio">
    <fieldset>
        <legend class="title">Upload Session Recording</legend>
        <div>
            <div class="row">
                <div class="col-sm-12 tableb">
                    <FORM name="audioUpload" id="audioUploadForm">
                        <INPUT TYPE="hidden" name="pat_id" value="<%=patId%>">
                        <div class="drop-div" id="audio_drop_div" ondrop="drop_evt(event);" ondragover="dragOver_evt(event);">
                            <span id="audio_drop_div_html">Drop Audio File Here or Click to Select</span>
                            <input type="file" name="audiofile" accept="audio/*" onChange="audio_drop_evt(event)" class="filestyle" id="audioFile" />
                        </div>
                        
                        <INPUT class="form-control" NAME="audiodesc" Size=53 Maxlength=300 placeholder="Session Description" onMouseOver="MM_displayStatusMsg('Enter a description of this session recording')" onMouseOut="MM_displayStatusMsg(' ')">
                        <INPUT class="form-control" NAME="sessiondate" type="date" placeholder="Session Date">
                        
                        <!-- Hidden type field always set to audio -->
                        <input type="hidden" class="form-control" name="type" value="SND">
                        
                        <center>
                            <input class="btn btn-primary" type="submit" value="Upload Recording" onclick="return audioFileCheck()" style="margin-top: 10px;">
                        </center>
                    </FORM>
                    
                    <!-- Hidden form for backend processing -->
                    <form id="audioUploadBackendForm" method="POST">
                        <input type="hidden" id="audioDesc" name="desc" />
                        <input type="hidden" id="sessionDate" name="sessionDate" />
                        <input type="hidden" id="audioExt" name="ext" />
                    </form>
                </div>
            </div>
            
            <!-- Audio Player Section -->
            <div class="row audio-player-section" style="margin-top: 20px;">
                <div class="col-sm-12">
                    <h4>Session Recordings</h4>
                    <div class="audio-files-list">
                        <!-- Will be populated dynamically -->
                        <div class="loading-recordings">Loading recordings...</div>
                    </div>
                </div>
            </div>
        </div>
    </fieldset>
</div>

<style>
.drop-div {
    border: 1px dashed #59a7ec;
    height: 80px;
    position: relative;
    text-align: center;
    margin: 4px 0;
    word-wrap: break-word;
    padding: 0 5px;
    background-color: #f8f9fa;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
}

#audioFile {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    opacity: 0;
    cursor: pointer;
}

.audio-card {
    background: #f0f8ff;
    border-radius: 5px;
    padding: 10px;
    margin-bottom: 10px;
    border-left: 4px solid #138A4E;
}

.audio-title {
    font-weight: bold;
    margin-bottom: 5px;
}

.audio-meta {
    font-size: 0.85em;
    color: #777;
    margin-bottom: 8px;
}

.audio-player {
    width: 100%;
    margin-top: 5px;
}

.audio-controls {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.delete-recording {
    color: #d9534f;
    cursor: pointer;
    margin-left: 10px;
}
</style>
</body>
</html>
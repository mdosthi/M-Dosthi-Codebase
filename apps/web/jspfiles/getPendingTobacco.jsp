<%@page contentType="text/html" import= "imedix.projinfo,imedix.rcDataEntryFrm,java.net.URLConnection,javax.net.ssl.*,java.text.*,imedix.rcDisplayData,java.io.*,java.util.*,org.json.simple.JSONObject,org.json.simple.parser.JSONParser,org.json.simple.JSONArray,java.nio.charset.Charset,java.io.BufferedReader,java.io.IOException ,java.io.InputStreamReader,java.io.OutputStream,java.net.HttpURLConnection,java.net.MalformedURLException,java.net.URL"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
cook cookx = new cook();
    rcDataEntryFrm rd = new rcDataEntryFrm(request.getRealPath("/"));
    rcDisplayData rdd = new rcDisplayData(request.getRealPath("/"));
    String path = request.getRealPath("/");
    String testId = "",pendingStudyUID = "",activeStudyUID="";

    String ccode = cookx.getCookieValue("center", request.getCookies ());
    String utype= cookx.getCookieValue("usertype",request.getCookies());

    String listtype="";
    listtype = request.getParameter("listtype");
    //out.println("DDDD : "+listtype);

Date cur_date = new Date();
SimpleDateFormat dde = new SimpleDateFormat("yyyy-MM-dd");
String today = dde.format(cur_date);
String msg = "",postTestId="";

String patId = "",patName="",phone="";
if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("getPendingPatient") != null) {
    patName = request.getParameter("patName");
    patId = request.getParameter("patId");
    phone = request.getParameter("phone");
    patName = patName == null ? "" : patName.trim();
    patId = patId == null ? "" : patId.trim();
    phone = phone == null ? "" : phone.trim();
    String testType = request.getParameter("type");
    String fromDate = request.getParameter("fromDate");
    String toDate = request.getParameter("toDate");
    // testType="Pathology";
    testType="TobaccoAssessment";
    Calendar defaultFromCalendar = Calendar.getInstance();
    defaultFromCalendar.add(Calendar.DATE, -7);
    String defaultFromDate = dde.format(defaultFromCalendar.getTime());
        boolean noFilter = patName.isEmpty() && patId.isEmpty() && phone.isEmpty()
            && (fromDate == null || fromDate.trim().isEmpty() || toDate == null || toDate.trim().isEmpty()
            || (defaultFromDate.equals(fromDate) && today.equals(toDate)));
    String extra = testType+"#"+(noFilter ? "" : fromDate)+"#"+(noFilter ? "" : toDate)+"#"+patName+"#"+phone+"#"+ccode;
//  out.println(fromDate+" : "+toDate);
    //out.println(extra);
    pendingStudyUID = (listtype != null && listtype.equals("T"))?rdd.pendingStudyUID(patId,extra):rdd.patWisePendingStudyUID(patId,extra);
    msg = "Search Results.";
}
else{
    String fromDate = "",toDate="",testType="";
    fromDate = "";
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -7);
        Date prevDate = cal.getTime();
        fromDate = dde.format(prevDate);
    toDate = today;

    // testType="Pathology";
    testType="TobaccoAssessment";
    String param = testType+"#"+fromDate+"#"+toDate+"#"+patName+"#"+phone+"#"+ccode;
    //out.println(param);
    pendingStudyUID = (listtype != null && listtype.equals("T"))?rdd.pendingStudyUID("",param):rdd.patWisePendingStudyUID("",param);
    msg = "Last 7 days pending test list.";
}
//out.println(rdd.pendingStudyUID("VWXYZ0191905180000",""));

%>
<html>
<head>
<link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.css">
        <link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.css">
    <script src="../bootstrap/jquery-2.2.1.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/bootstrap-datetimepicker.pt-BR.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/jquery.dataTables.min.js"></script>
    <script src="<%=request.getContextPath()%>/bootstrap/dataTables.bootstrap.min.js"></script>
<style>
.bootstrap-datetimepicker-widget ul{padding:0px;}
#from-datepicker span, #to-datepicker span{
    left: 0px !important;
    border-radius: 0px;
}
#from-datepicker input, #to-datepicker input{
    border-radius: 0px;
}
table th,table,td{font-size: 14px;}
table thead td{font-weight: 600;}

/* Chat History Styles */
.chat-history-interface {
    background-color: #ffffff;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 0;
    margin-top: 20px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.chat-history-header {
    background: linear-gradient(135deg, #4197c2 0%, #369bd4 100%);
    color: white;
    padding: 15px 20px;
    border-radius: 8px 8px 0 0;
    font-weight: bold;
    text-align: center;
    font-size: 18px;
    border-bottom: 3px solid #2980b9;
}

.chat-history-controls {
    background-color: #f8f9fa;
    padding: 15px;
    border-radius: 5px;
    border: 1px solid #dee2e6;
}

.summary-card {
    background: white;
    border: 1px solid #e9ecef;
    border-radius: 8px;
    padding: 15px;
    display: flex;
    align-items: center;
    transition: all 0.3s ease;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    margin-bottom: 15px;
}

.summary-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.summary-icon {
    font-size: 24px;
    color: #4197c2;
    margin-right: 15px;
    width: 40px;
    text-align: center;
}

.summary-info {
    flex: 1;
}

.summary-number {
    display: block;
    font-size: 20px;
    font-weight: bold;
    color: #2c3e50;
}

.summary-label {
    display: block;
    font-size: 12px;
    color: #7f8c8d;
    margin-top: 2px;
}

.chat-sessions-container {
    background-color: #ffffff;
    border-radius: 5px;
    border: 1px solid #dee2e6;
}

.chat-messages-container {
    max-height: 400px;
    overflow-y: auto;
    border: 1px solid #dee2e6;
    border-radius: 5px;
    padding: 15px;
    background-color: #fafafa;
}

.chat-message {
    margin-bottom: 15px;
    padding: 12px;
    border-radius: 10px;
    position: relative;
}
</style>
</head>
<script>

$(document).ready(function(){
    var obj = {};
    var obj_size=0;

    // Utility function to get cookie value
    function getCookieValue(cookieName) {
        var cookies = document.cookie.split(';');
        for (var i = 0; i < cookies.length; i++) {
            var cookie = cookies[i].trim();
            if (cookie.indexOf(cookieName + '=') === 0) {
                return cookie.substring(cookieName.length + 1);
            }
        }
        return null;
    }

    // Chat History Functions - SINGLE CLEAN IMPLEMENTATION
    window.openChatHistoryModal = function(patientId, patientName) {
        console.log('Opening chat history for:', patientId, patientName);
        
        // Set the patient info in the modal
        $('#chatModalPatientInfo').html('<strong>Patient:</strong> ' + patientName + ' (' + patientId + ')');
        
        // Set the current patient ID
        window.currentPatientId = patientId;
        
        // Set default dates (last 30 days)
        var today = new Date();
        var thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
        
        $('#chatFromDate').val(thirtyDaysAgo.toISOString().split('T')[0]);
        $('#chatToDate').val(today.toISOString().split('T')[0]);
        
        // Open the modal
        $('#chatHistoryMainModal').modal('show');
        
        // Auto-load chat history after modal opens
        setTimeout(function() {
            loadChatHistoryForPatient(patientId);
        }, 500);
    };

    window.loadChatHistoryForPatient = function(patientId) {
        console.log('Loading chat history for patient:', patientId);
        
        if (!patientId || patientId.trim() === '') {
            alert('Patient ID is required');
            return;
        }
        
        var fromDate = $('#chatFromDate').val();
        var toDate = $('#chatToDate').val();
        
        // Show loading
        $('#chatSessionsTableBody').html('<tr><td colspan="7" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading sessions for patient ' + patientId + '...</td></tr>');
        
        var requestData = {
            pat_id: patientId,
            from_date: fromDate,
            to_date: toDate
        };
        
        console.log('Making AJAX request with data:', requestData);
        
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getSimpleChatHistory.jsp',
            type: 'POST',
            data: requestData,
            dataType: 'json',
            success: function(response) {
                console.log('Chat history response:', response);
                if (response.success) {
                    populateChatSessionsTable(response.sessions);
                    
                    if (response.patient_id) {
                        console.log('Successfully loaded chat history for patient:', response.patient_id);
                    }
                } else {
                    console.log('Server returned error:', response.message);
                    $('#chatSessionsTableBody').html('<tr><td colspan="7" class="text-center text-danger">Error: ' + response.message + '</td></tr>');
                }
            },
            error: function(xhr, status, error) {
                console.error('AJAX error:', error);
                console.error('Response text:', xhr.responseText);
                $('#chatSessionsTableBody').html('<tr><td colspan="7" class="text-center text-danger">Error loading chat history. Status: ' + status + ', Error: ' + error + '</td></tr>');
            }
        });
    };

    window.populateChatSessionsTable = function(sessions) {
        var tbody = $('#chatSessionsTableBody');
        tbody.empty();
        
        if (!sessions || sessions.length === 0) {
            tbody.append('<tr><td colspan="7" class="text-center">No chat sessions found for the selected date range</td></tr>');
            return;
        }
        
        for (var i = 0; i < sessions.length; i++) {
            var session = sessions[i];
            var row = '<tr>';
            
            var sessionDate = session.session_date ? formatDate(session.session_date) : 'N/A';
            var startTime = session.start_time ? formatTime(session.start_time) : 'N/A';
            var endTime = session.end_time ? formatTime(session.end_time) : 'N/A';
            var duration = session.duration ? formatDuration(session.duration) : 'N/A';
            var messageCount = session.message_count || '0';
            var status = session.session_status || 'unknown';
            
            var statusBadge = getStatusBadge(status);
            
            row += '<td>' + sessionDate + '</td>';
            row += '<td>' + startTime + '</td>';
            row += '<td>' + endTime + '</td>';
            row += '<td>' + duration + '</td>';
            row += '<td class="text-center">' + messageCount + '</td>';
            row += '<td>' + statusBadge + '</td>';
            row += '<td>';
            row += '<button type="button" class="btn btn-sm btn-primary" onclick="viewChatMessages(\'' + session.session_id + '\')" title="View Messages">';
            row += '<i class="fa fa-eye"></i> View';
            row += '</button>';
            row += '</td>';
            row += '</tr>';
            
            tbody.append(row);
        }
    };

    window.showQuickSummary = function() {
        var patId = window.currentPatientId;
        
        if (!patId || patId.trim() === '') {
            alert('Please select a patient first by clicking "Chat History" button in the patient table');
            return;
        }
        
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getSimpleChatHistory.jsp',
            type: 'POST',
            data: {
                pat_id: patId,
                action: 'summary'
            },
            dataType: 'json',
            success: function(response) {
                if (response.success && response.summary) {
                    var summary = response.summary;
                    
                    $('#totalSessions').text(summary.total_sessions || 0);
                    $('#totalDuration').text(formatDuration(summary.total_duration || 0));
                    $('#lastSession').text(summary.last_session_date ? formatDate(summary.last_session_date) : '-');
                    $('#totalMessages').text(summary.total_messages || 0);
                    
                    $('#summaryCards').show();
                } else {
                    alert('Error loading summary: ' + (response.message || 'Unknown error'));
                }
            },
            error: function(xhr, status, error) {
                console.error('Summary error:', error);
                alert('Error loading summary. Please try again.');
            }
        });
    };

    window.viewChatMessages = function(sessionId) {
        var patId = window.currentPatientId;
        
        if (!patId) {
            alert('Patient ID not available. Please try again.');
            return;
        }
        
        $('#chatMessagesModal').modal('show');
        $('#chatMessagesContainer').html('<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading messages...</div>');
        $('#chatSessionInfo').html('<strong>Session ID:</strong> ' + sessionId);
        
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getSimpleChatHistory.jsp',
            type: 'POST',
            data: {
                action: 'messages',
                session_id: sessionId,
                pat_id: patId
            },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    populateChatMessages(response.messages);
                } else {
                    $('#chatMessagesContainer').html('<div class="text-center text-danger">Error: ' + response.message + '</div>');
                }
            },
            error: function(xhr, status, error) {
                console.log('Error loading chat messages:', error);
                $('#chatMessagesContainer').html('<div class="text-center text-danger">Error loading messages. Please try again.</div>');
            }
        });
    };

    window.populateChatMessages = function(messages) {
        var container = $('#chatMessagesContainer');
        container.empty();
        
        if (!messages || messages.length === 0) {
            container.append('<div class="text-center">No messages found in this session</div>');
            return;
        }
        
        for (var i = 0; i < messages.length; i++) {
            var message = messages[i];
            var messageDiv = '<div class="chat-message" style="margin-bottom: 15px; padding: 12px; border-radius: 10px; ';
            
            if (message.sender_type === 'patient') {
                messageDiv += 'background-color: #E9F8F0; border-left: 4px solid #0097A7;">';
            } else if (message.sender_type === 'bot') {
                messageDiv += 'background-color: #f3e5f5; border-left: 4px solid #9c27b0;">';
            } else if (message.sender_type === 'system') {
                messageDiv += 'background-color: #fff3e0; border-left: 4px solid #ff9800;">';
            } else {
                messageDiv += 'background-color: #f8f9fa; border-left: 4px solid #dee2e6;">';
            }
            
            messageDiv += '<div style="font-size: 12px; color: #555; margin-bottom: 6px; font-weight: bold;">';
            messageDiv += message.sender_type.toUpperCase() + ' (#' + message.message_sequence + ')';
            messageDiv += '</div>';
            
            messageDiv += '<div style="font-size: 14px; line-height: 1.5; word-wrap: break-word;">' + escapeHtml(message.message_content) + '</div>';
            
            if (message.timestamp) {
                messageDiv += '<div style="font-size: 10px; color: #95a5a6; margin-top: 5px; text-align: right;">' + formatTimestamp(message.timestamp) + '</div>';
            }
            
            messageDiv += '</div>';
            container.append(messageDiv);
        }
        
        container.scrollTop(container[0].scrollHeight);
    };

    // Add after the existing chat history functions

    // Assign Test Functions
    window.openAssignTestModal = function(patientId, patientName) {
        console.log('Opening assign test modal for:', patientId, patientName);
        
        // Set the patient info in the modal
        $('#assignTestPatientInfo').html('<strong>Patient:</strong> ' + patientName + ' (' + patientId + ')');
        
        // Store current patient ID
        window.currentAssignPatientId = patientId;
        
        // Load available surveys
        loadAvailableSurveys();
        
        // Open the modal
        $('#assignTestModal').modal('show');
    };

    window.loadAvailableSurveys = function() {
        $('#availableSurveysContainer').html('<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading available forms...</div>');
        
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getAvailableSurveys.jsp',
            type: 'GET',
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    populateAvailableSurveys(response.surveys);
                } else {
                    $('#availableSurveysContainer').html('<div class="alert alert-danger">Error: ' + response.message + '</div>');
                }
            },
            error: function(xhr, status, error) {
                console.error('Error loading surveys:', error);
                $('#availableSurveysContainer').html('<div class="alert alert-danger">Error loading forms. Please try again.</div>');
            }
        });
    };

    window.populateAvailableSurveys = function(surveys) {
        var container = $('#availableSurveysContainer');
        container.empty();
        
        if (!surveys || surveys.length === 0) {
            container.append('<div class="alert alert-info">No forms available</div>');
            return;
        }
        
        var html = '<div class="list-group">';
        for (var i = 0; i < surveys.length; i++) {
            var survey = surveys[i];
            html += '<div class="list-group-item">';
            html += '<div class="checkbox">';
            html += '<label>';
            html += '<input type="checkbox" class="survey-checkbox" value="' + survey.sid + '">';
            html += '<strong>' + survey.name + '</strong>';
            html += '<br><small class="text-muted">' + survey.description + '</small>';
            html += '</label>';
            html += '</div>';
            html += '</div>';
        }
        html += '</div>';
        
        container.html(html);
    };

    window.assignSelectedTests = function() {
        var patientId = window.currentAssignPatientId;
        
        if (!patientId) {
            alert('Patient ID not available');
            return;
        }
        
        // Get selected survey IDs
        var selectedSurveys = [];
        $('.survey-checkbox:checked').each(function() {
            selectedSurveys.push($(this).val());
        });
        
        if (selectedSurveys.length === 0) {
            alert('Please select at least one form to assign');
            return;
        }
        
        // Show loading
        $('#assignTestBtn').prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Assigning...');
        
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/assignTestsToPatient.jsp',
            type: 'POST',
            data: {
                pat_id: patientId,
                survey_ids: selectedSurveys.join(',')
            },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    alert('Forms assigned successfully!');
                    $('#assignTestModal').modal('hide');
                    // Reset checkboxes
                    $('.survey-checkbox').prop('checked', false);
                } else {
                    alert('Error: ' + response.message);
                }
                $('#assignTestBtn').prop('disabled', false).html('<i class="fa fa-check"></i> Assign Selected');
            },
            error: function(xhr, status, error) {
                console.error('Error assigning tests:', error);
                alert('Error assigning forms. Please try again.');
                $('#assignTestBtn').prop('disabled', false).html('<i class="fa fa-check"></i> Assign Selected');
            }
        });
    };

    // Utility functions
    window.formatDate = function(dateString) {
        if (!dateString) return 'N/A';
        try {
            var date = new Date(dateString);
            return date.toLocaleDateString();
        } catch (e) {
            return dateString;
        }
    };

    window.formatTime = function(timeString) {
        if (!timeString) return 'N/A';
        try {
            var date = new Date(timeString);
            return date.toLocaleTimeString();
        } catch (e) {
            return timeString;
        }
    };

    window.formatDuration = function(seconds) {
        if (!seconds || seconds <= 0) return '0m';
        
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        
        if (hours > 0) {
            return hours + 'h ' + minutes + 'm';
        } else {
            return minutes + 'm';
        }
    };

    window.formatTimestamp = function(timestamp) {
        if (!timestamp) return '';
        try {
            var date = new Date(timestamp);
            return date.toLocaleString();
        } catch (e) {
            return timestamp;
        }
    };

    window.getStatusBadge = function(status) {
        var color = '#6c757d';
        var text = status ? status.toUpperCase() : 'UNKNOWN';
        
        switch (status) {
            case 'completed':
                color = '#28a745';
                break;
            case 'active':
                color = '#0097A7';
                break;
            case 'terminated':
                color = '#dc3545';
                break;
        }
        
        return '<span style="background-color: ' + color + '; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px; font-weight: bold;">' + text + '</span>';
    };

    window.escapeHtml = function(text) {
        if (!text) return '';
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    };

// CORRECTED Survey ID Mapping - NO DEFAULT FALLBACK
function getSurveyIdFromTestName(testName) {
    console.log("Getting survey ID for test: " + testName);
    
    // Return null for unknown test names instead of defaulting to s12
    switch(testName) {
        case "FTND": return "s12";
        case "QSU": return "s13";
        case "PHQ9": return "s14";
        default: 
            console.warn("Unknown test name: " + testName + " - no default survey will be used");
            return null;
    }
}

    // Original tobacco assessment code continues below...
    <%if(listtype != null && listtype.equals("T")){%>
    try{
        var obj_temp = JSON.stringify(<%=pendingStudyUID%>);
        console.log(obj_temp);
        if(typeof(obj_temp)=="undefined" || obj_temp == undefined);
        else{
            obj = JSON.parse(obj_temp);
            console.log(<%=pendingStudyUID%>);
            obj_size = Object.keys(obj).length;
            if(obj_size>0){
                // CORRECTED: Add Assign Test column header
                $(".pendingStudyUIDList").append("<table class='table table-bordered dataTable' id='pendList'><thead><tr><td>Patient Name</td><td>Phone</td><td>Test Id</td><td>Test Name</td><td>Description</td><td>Reffered By</td><td>Entrydate</td><td>Upload Test Report</td><td>Assessment</td><td>Chat History</td><td>Assign Test</td></tr></thead><tbody align='center'></tbody></table>")
            }
        }
    }
    catch(err){console.log(err);}

    var rowCount=0;
    for(var i=0;i<obj_size;i++){
        if(obj[i].type=="TobaccoAssessment"){
        var row = $("tbody").get(0).insertRow(rowCount);
        rowCount++;
        var td0 = row.insertCell(0);
        var td1 = row.insertCell(1);
        var td2 = row.insertCell(2);
        var td3 = row.insertCell(3);
        var td4 = row.insertCell(4);
        var td5 = row.insertCell(5);
        var td6 = row.insertCell(6);
        var td7 = row.insertCell(7);
        var td8 = row.insertCell(8);
        var td9 = row.insertCell(9);
        var td10 = row.insertCell(10); // NEW: Assign Test column
        
        td0.innerHTML=obj[i].patName;
        td1.innerHTML=obj[i].phone;
        td2.innerHTML=obj[i].testId;
        td3.innerHTML=obj[i].test_name;
        td4.innerHTML=obj[i].description;
        td5.innerHTML=obj[i].reffered_by;
        td6.innerHTML=obj[i].entrydate.substring(0,10);
        td6.setAttribute("title",obj[i].entrydate);

        td7.innerHTML="<span class='glyphicon glyphicon-upload'></span>";
        td7.setAttribute("testId", obj[i].testId);
        td7.setAttribute("class", "pathoModal "+obj[i].testId);
        td7.setAttribute("data-toggle", "modal");
        td7.setAttribute("data-target", "#pathoUploadModal");
        
        var patId = obj[i].pat_id;
        var surveyId = getSurveyIdFromTestName(obj[i].test_name);
        
        if (surveyId) {
            td8.innerHTML="<a href='<%=request.getContextPath()%>/jspfiles/tobaccoSurvey.jsp?sid=" + surveyId + "&patId=" + patId + "' class='btn btn-info btn-sm'>Take Assessment</a>";
        } else {
            td8.innerHTML="<a href='<%=request.getContextPath()%>/jspfiles/tobaccoSurvey.jsp?patId=" + patId + "' class='btn btn-warning btn-sm'>View Forms</a>";
        }
        
        // Chat History button
        td9.innerHTML="<button type='button' class='btn btn-success btn-sm' onclick=\"window.openChatHistoryModal('" + patId + "', '" + obj[i].patName + "')\"><i class='fa fa-comments'></i> Chat History</button>";
        
        // NEW: Assign Test button (only show for psychologist/admin)
        var userType = getCookieValue('usertype');
        if (userType === 'psy' || userType === 'adm') {
            td10.innerHTML="<button type='button' class='btn btn-primary btn-sm' onclick=\"window.openAssignTestModal('" + patId + "', '" + obj[i].patName + "')\"><i class='fa fa-tasks'></i> Assign Test</button>";
        } else {
            td10.innerHTML="-";
        }
        }
    }
    <%} else{%>
// For PatientWise view
    try{
        var obj_temp = JSON.stringify(<%=pendingStudyUID%>);
        if(typeof(obj_temp)=="undefined" || obj_temp == undefined);
        else{
            obj = JSON.parse(obj_temp);
            console.log(<%=pendingStudyUID%>);
            obj_size = Object.keys(obj).length;
            if(obj_size>0){
                $(".pendingStudyUIDList").append("<table class='table table-bordered dataTable' id='pendList'><thead><tr><td>Patient Name</td><td>Patient Id</td><td>Visit</td><td>Chat History</td><td>Assign Test</td></tr></thead><tbody align='center'></tbody></table>")
            }
        }
    }
    catch(err){console.log(err);}

    for(var i=0;i<obj_size;i++){
        var row = $("tbody").get(0).insertRow(i);
        var td0 = row.insertCell(0);
        var td1 = row.insertCell(1);
        var td2 = row.insertCell(2);
        var td3 = row.insertCell(3);
        var td4 = row.insertCell(4);
        
        td0.innerHTML=obj[i].patName;
        td1.innerHTML=obj[i].patId;
        
        var patId = obj[i].patId;
        
        td2.innerHTML = "<a href='<%=request.getContextPath()%>/jspfiles/tobaccoSurvey.jsp?patId=" + patId + "' class='btn btn-info btn-sm'>View Prescribed Forms</a>";
        
        td3.innerHTML="<button type='button' class='btn btn-success btn-sm' onclick=\"window.openChatHistoryModal('" + patId + "', '" + obj[i].patName + "')\"><i class='fa fa-comments'></i> Chat History</button>";
        
        // SIMPLIFIED: Show Assign Test button for everyone (for testing)
        td4.innerHTML="<button type='button' class='btn btn-primary btn-sm' onclick=\"window.openAssignTestModal('" + patId + "', '" + obj[i].patName + "')\"><i class='fa fa-tasks'></i> Assign Test</button>";
    }
    <%}%>

// Rest of the original code continues...
$(".syncStudyUID").click(function(){
    var rotation = $(this).children(".glyphicon-refresh");
    for(var i=0;i<=180;i++){
        setTimeout(function(i) {
        rotation.attr("style","transform:rotate("+i+"deg)");
    },i * 10, i);
        }

    var testId = $(this).attr("testId").trim();
    $.ajax({
        type: "POST",
        url: "studyUIDSync.jsp",
        data: {'testId':testId},
        success: function(data){
            //alert(data.trim());
            if(data.trim()=="1"){
                    $("."+testId).children(".flag").addClass("glyphicon-ok").removeClass("glyphicon-remove");
                    $("."+testId).children(".flag").attr("style","color:green;float:right");
            }
            else{

                    $("."+testId).children(".flag").addClass("glyphicon-remove").removeClass("glyphicon-ok");
                    $("."+testId).children(".flag").attr("style","color:red;float:right");
            }
        },
    });
});

// Continue with rest of original functionality...
var d = new Date();
$(function () {
    var startDate = new Date("10/10/1995"),
        endDate = new Date("<%=today%>");
    $('#from-datepicker').datetimepicker({
        weekStart: 1,
        todayBtn: 1,
        autoclose: 1,
        todayHighlight: 1,
        startView: 4,
        keyboardNavigation: 1,
        minView: 2,
        forceParse: 0,
        startDate: startDate,
        endDate: endDate,
        setDate: startDate
    });

    var startDateTo = new Date("10/10/1995"),
    endDateTo = new Date("<%=today%>");
    $('#to-datepicker').datetimepicker({
        weekStart: 1,
        todayBtn: 1,
        autoclose: 1,
        todayHighlight: 1,
        startView: 4,
        keyboardNavigation: 1,
        minView: 2,
        forceParse: 0,
        startDate: startDateTo,
        endDate: endDateTo,
        setDate: endDateTo
    });
});

$("#pendList").dataTable({
    "lengthMenu": [[20,50], [20,50]],
    "info":     false
});

$(document).on("click", ".pathoModal" , function(){
    $.post("pathologyFileUploader.jsp",{testid:""+$(this).attr("testid")+"",patid:""+$(this).attr("testid").substring(0,18)+""},function(data){$(".pathoUploader").html(data)});
});

$(".tesListModalId").click(function(){
    $(".tesListModalBody").html("");
});

});
</script>
<body>

<div class="container-fluid">
<% if(utype.equalsIgnoreCase("adm")){ %>
<div class="row">
<div class="col-sm-12">
    <a href="pacsResultlist.jsp" >TEST DETAILS FROM PACS</a>
</div>
</div>
<%  } %>

<% 
// Check if patient has prescribed tobacco assessments
Object prescribedSurveys = null;
if (patId != null && !patId.isEmpty()) {
    prescribedSurveys = rdd.getPatientPrescribedSurveys(patId);
    if (!(prescribedSurveys instanceof String) && prescribedSurveys != null) {
        Vector surveysVector = (Vector)prescribedSurveys;
        if (surveysVector.size() > 0) {
%>

<%
        }
    }
}
%>

    <div class="panel panel-info">
        <div class="panel-heading">
            <h3 class="panel-title">Search For Pending Test</h3>
        </div>
        <div class="panel-body">
            <form method="POST" class="pendingStudyUID">
            <input type="hidden" name="listtype" value="<%=listtype == null || listtype.isEmpty() ? "P" : listtype%>">
            <div class="row">
                <div class="col-sm-2">
                    <label>Patient Name</label>
                    <input class="form-control" type="text" name="patName" placeholder="Min. 3 Character" value="<%=patName%>"/>
                </div>
                <div class="col-sm-2">
                    <label>Patient ID</label>
                    <input class="form-control" type="text" name="patId" placeholder="Patient Id" value="<%=patId%>"/>
                </div>
                <div class="col-sm-2">
                    <label>Phone</label>
                    <input class="form-control" type="text" name="phone" placeholder="Phone" value="<%=phone%>"/>
                </div>
            <div class="col-sm-2">
                <label>Investigation Type</label>
                <select class="form-control" name="type" disabled=true>
                    <!--<option value="">Select</option>
                    <option value="" disabled="true">Radiology</option>-->
                    <option value="Pathology">Pathology</option>
                </select>
            </div>
            <div class="col-sm-4">
                <label>By Date</label>
                <div class="input-group">
                        <div id="from-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
                            <input data-format="yyyy-MM-dd" type="text" name="fromDate" value="<%=request.getParameter("fromDate") == null ? "" : request.getParameter("fromDate")%>" class="form-control dob"><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                        </div>
                    <span class="input-group-addon">To</span>
                        <div id="to-datepicker" class="input-append date input-group" style="margin:auto;max-width:320px;">
                            <input data-format="yyyy-MM-dd" type="text" name="toDate" value="<%=request.getParameter("toDate") == null ? "" : request.getParameter("toDate")%>" class="form-control dob"><span class="add-on glyphicon glyphicon-calendar input-group-addon" style="cursor: pointer;top:0px;padding:6px;left:-4px"></span>
                        </div>

                </div>
            </div>
            <div class="col-sm-2">
            <label>Submit</label>
                <input class="form-control btn-primary" type="submit" name="getPendingPatient" class="getPendingPatient" value="Get Pending List" />
            </div>
            </div>
            </form>
        </div>
    </div>

    <div class="panel panel-success">
        <div class="panel-heading">
            <h3 class="panel-title"><%=msg%> <label class="pull-right"><a class="btn btn-small" href="?listtype=T">TestWise</a><a class="btn btn-small" href="?listtype=P">PatientWise</a></label></h3>
        </div>
        <div class="panel-body">
            <div class="pendingStudyUIDList">

            </div>
            <div class="pendingStudyUIDList-child">

            </div>
        </div>
    </div>

<!-- Chat History Main Modal -->
<div class='modal fade' id='chatHistoryMainModal' tabindex='-1' role='dialog'>
    <div class='modal-dialog modal-xl' role='document' style='width: 95%; max-width: 1200px;'>
        <div class='modal-content'>
            <div class='modal-header' style='background-color: #4197c2; color: white;'>
                <button type='button' class='close' data-dismiss='modal' style='color: white;'>
                    <span>&times;</span>
                </button>
                <h4 class='modal-title'>
                    <i class='fa fa-comments'></i> Patient Chat History
                </h4>
            </div>
            <div class='modal-body'>
                <!-- Patient Info -->
                <div id='chatModalPatientInfo' style='margin-bottom: 15px; padding: 10px; background-color: #E9F8F0; border-radius: 5px; font-weight: bold;'></div>
                
                <!-- Controls -->
                <div style='margin-bottom: 20px; background-color: #f8f9fa; padding: 15px; border-radius: 5px; border: 1px solid #dee2e6;'>
                    <div class='row'>
                        <div class='col-md-3'>
                            <label>From Date:</label>
                            <input type='date' id='chatFromDate' class='form-control'>
                        </div>
                        <div class='col-md-3'>
                            <label>To Date:</label>
                            <input type='date' id='chatToDate' class='form-control'>
                        </div>
                        <div class='col-md-3'>
                            <label>&nbsp;</label><br>
                            <button type='button' class='btn btn-primary btn-sm' onclick='loadChatHistoryForPatient(window.currentPatientId)'>
                                <i class='fa fa-search'></i> Reload
                            </button>
                        </div>
                        <div class='col-md-3'>
                            <label>&nbsp;</label><br>
                            <button type='button' class='btn btn-info btn-sm' onclick='showQuickSummary()'>
                                <i class='fa fa-chart-bar'></i> Summary
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Summary Cards -->
                <div class='row' style='margin-bottom: 20px; display: none;' id='summaryCards'>
                    <div class='col-md-3'>
                        <div style='background: white; border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; text-align: center;'>
                            <div style='font-size: 24px; color: #4197c2;'><i class='fa fa-comments'></i></div>
                            <div style='font-size: 20px; font-weight: bold; color: #2c3e50;' id='totalSessions'>0</div>
                            <div style='font-size: 12px; color: #7f8c8d;'>Total Sessions</div>
                        </div>
                    </div>
                    <div class='col-md-3'>
                        <div style='background: white; border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; text-align: center;'>
                            <div style='font-size: 24px; color: #4197c2;'><i class='fa fa-clock'></i></div>
                            <div style='font-size: 20px; font-weight: bold; color: #2c3e50;' id='totalDuration'>0m</div>
                            <div style='font-size: 12px; color: #7f8c8d;'>Total Duration</div>
                        </div>
                    </div>
                    <div class='col-md-3'>
                        <div style='background: white; border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; text-align: center;'>
                            <div style='font-size: 24px; color: #4197c2;'><i class='fa fa-calendar'></i></div>
                            <div style='font-size: 20px; font-weight: bold; color: #2c3e50;' id='lastSession'>-</div>
                            <div style='font-size: 12px; color: #7f8c8d;'>Last Session</div>
                        </div>
                    </div>
                    <div class='col-md-3'>
                        <div style='background: white; border: 1px solid #e9ecef; border-radius: 8px; padding: 15px; text-align: center;'>
                            <div style='font-size: 24px; color: #4197c2;'><i class='fa fa-comment'></i></div>
                            <div style='font-size: 20px; font-weight: bold; color: #2c3e50;' id='totalMessages'>0</div>
                            <div style='font-size: 12px; color: #7f8c8d;'>Total Messages</div>
                        </div>
                    </div>
                </div>

                <!-- Chat Sessions Table -->
                <div style='background-color: #ffffff; border-radius: 5px; border: 1px solid #dee2e6;'>
                    <div class='table-responsive'>
                        <table class='table table-striped table-bordered'>
                            <thead>
                                <tr style='background-color: #4197c2; color: white;'>
                                    <th>Date</th>
                                    <th>Start Time</th>
                                    <th>End Time</th>
                                    <th>Duration</th>
                                    <th>Messages</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id='chatSessionsTableBody'>
                                <tr>
                                    <td colspan='7' class='text-center'>Select a patient to view chat history</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>
            </div>
        </div>
    </div>
</div>

<!-- Chat Messages Modal -->
<div class='modal fade' id='chatMessagesModal' tabindex='-1' role='dialog'>
    <div class='modal-dialog modal-lg' role='document'>
        <div class='modal-content'>
            <div class='modal-header' style='background-color: #4197c2; color: white;'>
                <button type='button' class='close' data-dismiss='modal' style='color: white;'>
                    <span>&times;</span>
                </button>
                <h4 class='modal-title'>
                    <i class='fa fa-comments'></i> Chat Messages
                </h4>
            </div>
            <div class='modal-body'>
                <div id='chatSessionInfo' style='margin-bottom: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 5px;'></div>
                <div id='chatMessagesContainer' style='max-height: 400px; overflow-y: auto; border: 1px solid #dee2e6; border-radius: 5px; padding: 15px; background-color: #fafafa;'>
                    <div class='text-center'>
                        <i class='fa fa-spinner fa-spin'></i> Loading messages...
                    </div>
                </div>
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>
            </div>
        </div>
    </div>
</div>
 <!-- Assign Test Modal -->
<div class='modal fade' id='assignTestModal' tabindex='-1' role='dialog'>
    <div class='modal-dialog modal-lg' role='document'>
        <div class='modal-content'>
            <div class='modal-header' style='background-color: #4197c2; color: white;'>
                <button type='button' class='close' data-dismiss='modal' style='color: white;'>
                    <span>&times;</span>
                </button>
                <h4 class='modal-title'>
                    <i class='fa fa-tasks'></i> Assign Assessment Forms
                </h4>
            </div>
            <div class='modal-body'>
                <!-- Patient Info -->
                <div id='assignTestPatientInfo' style='margin-bottom: 15px; padding: 10px; background-color: #E9F8F0; border-radius: 5px; font-weight: bold;'></div>
                
                <div class='alert alert-info'>
                    <i class='fa fa-info-circle'></i> Select one or more assessment forms to assign to this patient. The patient will be able to view and complete these forms from their mobile app.
                </div>
                
                <!-- Available Surveys Container -->
                <div id='availableSurveysContainer' style='max-height: 400px; overflow-y: auto; border: 1px solid #dee2e6; border-radius: 5px; padding: 15px; background-color: #fafafa;'>
                    <div class='text-center'>
                        <i class='fa fa-spinner fa-spin'></i> Loading forms...
                    </div>
                </div>
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-default' data-dismiss='modal'>Cancel</button>
                <button type='button' class='btn btn-primary' id='assignTestBtn' onclick='assignSelectedTests()'>
                    <i class='fa fa-check'></i> Assign Selected
                </button>
            </div>
        </div>
    </div>
</div>

</body>
</html>
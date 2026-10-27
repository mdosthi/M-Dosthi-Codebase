<%@page contentType="text/html" import="imedix.cook,imedix.rcDisplayData,java.util.*,imedix.dataobj,org.json.simple.JSONObject,org.json.simple.parser.JSONParser" %>
<%@ include file="..//includes/chkcook.jsp" %>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="<%=request.getContextPath()%>/bootstrap/css/bootstrap.min.css">
    <style>
    .table-tobacco-assessment tbody td,tbody tr{background:#fff;color:#000;}
    .table-tobacco-assessment>tbody>tr>td, .table-tobacco-assessment>tbody>tr>th, .table-tobacco-assessment>tfoot>tr>td, .table-tobacco-assessment>tfoot>tr>th, .table-tobacco-assessment>thead>tr>td, .table-tobacco-assessment>thead>tr>th {
        border: 1px solid #4197c2;
    }
    .table-tobacco-assessment>thead>tr:nth-child(2){
        background: #4198c1;
        color: #eee;
    }
    .table-tobacco-assessment>thead>tr:nth-child(1){
        font-weight: bold;
        color: #1378ab;
    }
    .print{cursor:pointer;}
    .view-btn {
        background-color: #4197c2;
        color: white;
        border: none;
        padding: 5px 10px;
        border-radius: 3px;
        cursor: pointer;
    }
    .view-btn:hover {
        background-color: #337ab7;
    }
    .modal-body {
        max-height: 70vh;
        overflow-y: auto;
    }

    /* Score display styles */
    .score-summary {
        background-color: #f8f9fa;
        border: 2px solid #4197c2;
        border-radius: 8px;
        padding: 15px;
        margin-bottom: 20px;
    }

    .score-summary h5 {
        color: #4197c2;
        margin-top: 0;
        margin-bottom: 10px;
        font-weight: bold;
    }

    .score-display {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 10px;
    }

    .score-label {
        font-weight: bold;
        color: #333;
    }

    .score-value {
        font-size: 24px;
        font-weight: bold;
        color: #4197c2;
    }

    .score-interpretation {
        padding: 10px;
        border-radius: 5px;
        text-align: center;
        font-weight: bold;
        margin-top: 10px;
    }

    .score-interpretation.low {
        background-color: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
    }

    .score-interpretation.moderate {
        background-color: #fff3cd;
        color: #856404;
        border: 1px solid #ffeaa7;
    }

    .score-interpretation.high {
        background-color: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
    }

    /* Chat Control Interface Styles */
    .chat-control-interface {
        margin-top: 20px;
        padding: 15px;
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 5px;
    }
    
    .chat-control-header {
        background-color: #4197c2;
        color: white;
        padding: 10px 15px;
        margin: -15px -15px 15px -15px;
        border-radius: 5px 5px 0 0;
        font-weight: bold;
        text-align: center;
    }
    
    .chat-control-btn {
        background-color: #28a745;
        color: white;
        border: none;
        padding: 10px 20px;
        border-radius: 5px;
        cursor: pointer;
        font-size: 16px;
        font-weight: bold;
    }
    
    .chat-control-btn:hover {
        background-color: #218838;
    }
    
    /* Simplified Chat History Styles */
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

    .control-item {
        margin-bottom: 15px;
        padding: 10px;
        background-color: white;
        border: 1px solid #dee2e6;
        border-radius: 3px;
    }
    
    .control-item label {
        font-weight: bold;
        margin-bottom: 5px;
        display: block;
    }
    
    .control-item input, .control-item select, .control-item textarea {
        width: 100%;
        padding: 8px;
        border: 1px solid #ced4da;
        border-radius: 3px;
    }
    
    .control-item input[type="checkbox"] {
        width: auto;
        margin-right: 5px;
    }
    
    .control-item .form-text {
        font-size: 0.875em;
        color: #6c757d;
        margin-top: 5px;
    }
    
    .chat-control-section {
        margin-bottom: 25px;
        padding: 15px;
        border: 1px solid #e9ecef;
        border-radius: 5px;
        background-color: #f8f9fa;
    }
    
    .chat-control-section h5 {
        color: #4197c2;
        margin-bottom: 15px;
        font-weight: bold;
    }

    /* Modern Chat Control Input Styles */
    .chat-control-input {
        display: block;
        width: 100%;
        height: 42px;
        padding: 8px 12px;
        font-size: 14px;
        line-height: 1.5;
        color: #1e293b;
        background-color: #ffffff;
        background-image: none;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
    }
    .chat-control-input:focus {
        border-color: var(--primary, #4f46e5) !important;
        outline: 0;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.15) !important;
    }
    
    /* Premium Chip Checkboxes for Blackout Days */
    .blackout-days-container {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        margin-top: 8px;
    }
    .day-chip {
        display: inline-block;
        position: relative;
    }
    .day-chip input[type="checkbox"] {
        position: absolute;
        opacity: 0;
        width: 0;
        height: 0;
        margin: 0;
    }
    .day-chip-label {
        display: inline-block;
        padding: 8px 16px;
        background-color: #f1f5f9;
        border: 1px solid #cbd5e1;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 600;
        color: #475569;
        cursor: pointer;
        transition: all 0.2s ease;
        user-select: none;
    }
    .day-chip input[type="checkbox"]:checked + .day-chip-label {
        background-color: var(--primary, #4f46e5) !important;
        border-color: var(--primary, #4f46e5) !important;
        color: white !important;
        box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);
    }
    .day-chip input[type="checkbox"]:focus + .day-chip-label {
        outline: 2px solid var(--primary, #4f46e5);
        outline-offset: 2px;
    }
    .day-chip-label:hover {
        background-color: #e2e8f0;
        color: #0f172a;
    }
    </style>
    <!-- jQuery and Bootstrap are already loaded by index1.jsp; re-loading them can cause conflicts -->
    <!-- <script src="<%=request.getContextPath()%>/bootstrap/js/jquery.min.js"></script> -->
    <!-- <script src="<%=request.getContextPath()%>/bootstrap/js/bootstrap.min.js"></script> -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <script>
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
    
    function showSurveyDetails(surveyId) {
        var modalInAssesment = $('#tobaccoAssesment').find('#modal-' + surveyId);
        if (modalInAssesment.length > 0) {
            $('body > #modal-' + surveyId).remove();
            modalInAssesment.appendTo('body');
        }
        $('#modal-' + surveyId).modal('show');
    }
    
    function showChatControlModal() {
        var modalInAssesment = $('#tobaccoAssesment').find('#chatControlModal');
        if (modalInAssesment.length > 0) {
            $('body > #chatControlModal').remove();
            modalInAssesment.appendTo('body');
        }
        $('#chatControlModal').modal('show');
    }
    
    function loadChatControls() {
        // Get patient ID from URL (same method as loadChatHistory)
        var patId = window.currentPatientId || getPatientIdFromURL();
        
        if (!patId) {
            alert('Patient ID not found. Please ensure you are accessing this page with a valid patient ID.');
            return;
        }
        
        // Show loading indicator
        $('#chatControlModal .modal-body').append('<div id="loading" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading...</div>');
        
        // AJAX call to fetch existing settings
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getChatControlSettings.jsp',
            type: 'POST',
            data: { pat_id: patId },
            dataType: 'json',
            success: function(response) {
                $('#loading').remove();
                if(response.success) {
                    populateChatControlForm(response.data);
                } else {
                    alert('Error loading settings: ' + response.message);
                }
            },
            error: function(xhr, status, error) {
                $('#loading').remove();
                console.log('Error loading chat control settings:', error);
                alert('Error loading chat control settings. Please try again.');
            }
        });
    }
    
    function populateChatControlForm(data) {
        if(data) {
            $('#dailyChatLimit').val(data.daily_chat_limit || 3);
            $('#maxSessionDuration').val(data.max_session_duration || 1800);
            $('#minSessionInterval').val(data.min_session_interval || 3600);
            $('#chatType').val(data.chat_type || 'original');
            
            // Handle time fields - remove seconds if present
            var startTime = data.blackout_start_time;
            var endTime = data.blackout_end_time;
            
            if(startTime && startTime.length > 5) {
                startTime = startTime.substring(0, 5);
            }
            if(endTime && endTime.length > 5) {
                endTime = endTime.substring(0, 5);
            }
            
            $('#blackoutStartTime').val(startTime || '');
            $('#blackoutEndTime').val(endTime || '');
            
            // Clear all checkboxes first
            $('input[name="blackoutDays"]').prop('checked', false);
            
            // Handle blackout days
            if(data.blackout_days) {
                var days = data.blackout_days.split(',');
                days.forEach(function(day) {
                    day = day.trim();
                    $('input[name="blackoutDays"][value="' + day + '"]').prop('checked', true);
                });
            }
        }
    }
    
    function saveChatControls() {
        var patId = window.currentPatientId || getPatientIdFromURL();
        
        if (!patId) {
            alert('Patient ID not found. Please ensure you are accessing this page with a valid patient ID.');
            return;
        }
        
        var dailyChatLimit = $('#dailyChatLimit').val();
        var maxSessionDuration = $('#maxSessionDuration').val();
        var minSessionInterval = $('#minSessionInterval').val();
        var blackoutStartTime = $('#blackoutStartTime').val();
        var blackoutEndTime = $('#blackoutEndTime').val();
        var chatType = $('#chatType').val() || 'original';

        // Get selected blackout days
        var blackoutDays = [];
        $('input[name="blackoutDays"]:checked').each(function() {
            blackoutDays.push($(this).val());
        });
        
        // Client-side validation
        if(dailyChatLimit < 1 || dailyChatLimit > 50) {
            alert('Daily chat limit must be between 1 and 50');
            return;
        }
        
        if(maxSessionDuration < 300 || maxSessionDuration > 7200) {
            alert('Max session duration must be between 300 seconds (5 min) and 7200 seconds (2 hours)');
            return;
        }
        
        if(minSessionInterval < 300) {
            alert('Minimum session interval must be at least 300 seconds (5 minutes)');
            return;
        }
        
        // Show saving indicator
        var saveBtn = $('#saveChatControlsBtn');
        var originalText = saveBtn.text();
        saveBtn.prop('disabled', true).text('Saving...');
        
        // AJAX call to save settings
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/saveChatControlSettings.jsp',
            type: 'POST',
            data: {
                pat_id: patId,
                daily_chat_limit: dailyChatLimit,
                max_session_duration: maxSessionDuration,
                min_session_interval: minSessionInterval,
                blackout_start_time: blackoutStartTime,
                blackout_end_time: blackoutEndTime,
                blackout_days: blackoutDays.join(','),
                chat_type: chatType
            },
            dataType: 'json',
            success: function(response) {
                saveBtn.prop('disabled', false).text(originalText);
                if(response.success) {
                    alert('Chat control settings saved successfully!');
                    $('#chatControlModal').modal('hide');
                } else {
                    alert('Error saving settings: ' + response.message);
                }
            },
            error: function(xhr, status, error) {
                saveBtn.prop('disabled', false).text(originalText);
                console.log('Error saving chat control settings:', error);
                alert('Error saving chat control settings. Please try again.');
            }
        });
    }
    
    function resetChatControls() {
        if(confirm('Are you sure you want to reset all chat controls to default values?')) {
            $('#dailyChatLimit').val(3);
            $('#maxSessionDuration').val(1800);
            $('#minSessionInterval').val(3600);
            $('#blackoutStartTime').val('');
            $('#blackoutEndTime').val('');
            $('input[name="blackoutDays"]').prop('checked', false);
            $('#chatType').val('original');
        }
    }

    // Simplified Chat History JavaScript
    $(document).ready(function() {
    // Set default date range (last 30 days)
        var today = new Date();
        var thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
        
        $('#chatToDate').val(today.toISOString().split('T')[0]);
        $('#chatFromDate').val(thirtyDaysAgo.toISOString().split('T')[0]);
        
        console.log('Page loaded - extracting patient ID from URL');
        
        // Get patient ID from URL parameter (same as tobacco assessment)
        var patientId = getPatientIdFromURL();
        console.log('Patient ID extracted from URL:', patientId);
        
        if (patientId) {
            console.log('Patient ID found, setting up interface for:', patientId);
            // Store for later use
            window.currentPatientId = patientId;
            loadPatientMemory();
        } else {
            console.log('No patient ID found in URL');
        }
    });

    /*
     * Patient memory UI disabled temporarily.
     * The feature was rendering the "Patient Memory (for next session)" form shown in the screenshot.
     */
    // var _patientMemoryDeltaId = null;
    //
    // function loadPatientMemory() {
    //     var patId = window.currentPatientId || getPatientIdFromURL();
    //     if (!patId) return;
    //
    //     $.ajax({
    //         url: '<%=request.getContextPath()%>/jspfiles/getPatientMemory.jsp',
    //         type: 'POST',
    //         data: { pat_id: patId },
    //         dataType: 'json',
    //         success: function(response) {
    //             if (response.success) {
    //                 _patientMemoryDeltaId = response.delta_id;
    //                 $('#patientMemoryPersistentTriggers').val(safeParseList(response.persistent_triggers).join(', '));
    //                 $('#patientMemoryPersistentConcerns').val(safeParseList(response.persistent_concerns).join(', '));
    //                 $('#patientMemoryContinuedAdvice').val(safeParseList(response.continued_advice).join(', '));
    //                 $('#patientMemoryQuitHistory').val(response.cumulative_quit_history || '');
    //                 $('#patientMemoryReadinessAfter').val(response.readiness_after || '');
    //                 $('#savePatientMemoryBtn').prop('disabled', false);
    //             } else {
    //                 _patientMemoryDeltaId = null;
    //                 $('#savePatientMemoryBtn').prop('disabled', true);
    //                 $.ajax({
    //                     url: '<%=request.getContextPath()%>/jspfiles/getSessionSummary.jsp',
    //                     type: 'POST',
    //                     data: { pat_id: patId },
    //                     dataType: 'json',
    //                     success: function(sr) {
    //                         if (sr.success && sr.sessions && sr.sessions.length > 0) {
    //                             var latest = sr.sessions[sr.sessions.length - 1];
    //                             $('#patientMemoryPersistentTriggers').val(safeParseList(latest.triggers).join(', '));
    //                             $('#patientMemoryPersistentConcerns').val(safeParseList(latest.concerns).join(', '));
    //                             $('#patientMemoryContinuedAdvice').val(safeParseList(latest.advice).join(', '));
    //                             $('#patientMemoryQuitHistory').val(latest.quit_history || '');
    //                             $('#patientMemoryReadinessAfter').val(latest.readiness || '');
    //                         } else {
    //                             $('#patientMemoryPersistentTriggers').val('');
    //                             $('#patientMemoryPersistentConcerns').val('');
    //                             $('#patientMemoryContinuedAdvice').val('');
    //                             $('#patientMemoryQuitHistory').val('');
    //                             $('#patientMemoryReadinessAfter').val('');
    //                         }
    //                     },
    //                     error: function() {
    //                         $('#patientMemoryPersistentTriggers').val('');
    //                         $('#patientMemoryPersistentConcerns').val('');
    //                         $('#patientMemoryContinuedAdvice').val('');
    //                         $('#patientMemoryQuitHistory').val('');
    //                         $('#patientMemoryReadinessAfter').val('');
    //                     }
    //                 });
    //             }
    //         },
    //         error: function() {
    //             _patientMemoryDeltaId = null;
    //             $('#savePatientMemoryBtn').prop('disabled', true);
    //             $('#patientMemoryFeedback').html('<div class="alert alert-danger" style="padding:6px 12px;font-size:12px;margin-top:6px;">Error loading patient memory.</div>');
    //         }
    //     });
    // }
    //
    // function commaListToJson(text) {
    //     var items = text.split(',').map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    //     return JSON.stringify(items);
    // }
    //
    // function savePatientMemory() {
    //     if (!_patientMemoryDeltaId) return;
    //     var btn = $('#savePatientMemoryBtn');
    //     btn.prop('disabled', true).text('Saving...');
    //     $.ajax({
    //         url: '<%=request.getContextPath()%>/jspfiles/savePatientMemory.jsp',
    //         type: 'POST',
    //         data: {
    //             delta_id: _patientMemoryDeltaId,
    //             persistent_triggers: commaListToJson($('#patientMemoryPersistentTriggers').val()),
    //             persistent_concerns: commaListToJson($('#patientMemoryPersistentConcerns').val()),
    //             continued_advice: commaListToJson($('#patientMemoryContinuedAdvice').val()),
    //             cumulative_quit_history: $('#patientMemoryQuitHistory').val().trim(),
    //             readiness_after: $('#patientMemoryReadinessAfter').val().trim()
    //         },
    //         dataType: 'json',
    //         success: function(response) {
    //             btn.prop('disabled', false).html('<i class="fa fa-save"></i> Save');
    //             if (response.success) {
    //                 $('#patientMemoryFeedback').html('<div class="alert alert-success" style="padding:6px 12px;font-size:12px;margin-top:6px;">Saved.</div>');
    //                 setTimeout(function(){ $('#patientMemoryFeedback').html(''); }, 2500);
    //             } else {
    //                 $('#patientMemoryFeedback').html('<div class="alert alert-danger" style="padding:6px 12px;font-size:12px;margin-top:6px;">Error: ' + escapeHtml(response.message) + '</div>');
    //             }
    //         },
    //         error: function() {
    //             btn.prop('disabled', false).html('<i class="fa fa-save"></i> Save');
    //             $('#patientMemoryFeedback').html('<div class="alert alert-danger" style="padding:6px 12px;font-size:12px;margin-top:6px;">Request failed.</div>');
    //         }
    //     });
    // }
    */

    function getPatientIdFromURL() {
        // Method 1: Check URL parameters (like tobacco assessment does)
        var urlParams = new URLSearchParams(window.location.search);
        var patId = urlParams.get('patid') || urlParams.get('id') || urlParams.get('patient_id');
        
        if (patId && patId.trim() !== '') {
            console.log('Found patient ID in URL parameters:', patId);
            return patId.trim();
        }
        
        // Method 2: Extract from URL path (common pattern)
        var currentURL = window.location.href;
        console.log('Current URL:', currentURL);
        
        // Look for patterns like patid=VBCR0192706250000 or &dest=patientAlldata&id=VBCR0192706250000
        var patterns = [
            /[?&]patid=([A-Z]{4}\d{13})/,
            /[?&]id=([A-Z]{4}\d{13})/,
            /[?&]patient_id=([A-Z]{4}\d{13})/,
            /dest=patientAlldata[^&]*&id=([A-Z]{4}\d{13})/
        ];
        
        for (var i = 0; i < patterns.length; i++) {
            var match = currentURL.match(patterns[i]);
            if (match && match[1]) {
                console.log('Found patient ID using pattern', i, ':', match[1]);
                return match[1];
            }
        }
        
        // Method 3: Try to get from cookies as fallback
        var cookiePatId = getCookieValue('patid');
        if (cookiePatId && cookiePatId.match(/^[A-Z]{4}\d{13}$/)) {
            console.log('Found properly formatted patient ID in cookie:', cookiePatId);
            return cookiePatId;
        }
        
        console.log('No patient ID found in URL or cookies');
        return null;
    }

    // ── Session Summary column — per-session view & edit ─────────────
    var _currentSummarySessionId = null;

    function viewSessionSummary(sessionId) {
        _currentSummarySessionId = sessionId;
        $('#sessionAnnotationModal').modal('show');
        $('#sessionAnnotationContent').html(
            '<div class="text-center" style="padding:30px;"><i class="fa fa-spinner fa-spin fa-2x"></i><br><br>Loading...</div>'
        );
        $('#manualSummaryBox').hide();

        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getSessionSummary.jsp',
            type: 'POST',
            data: { session_id: sessionId },
            dataType: 'json',
            success: function(response) {
                if (response.success && response.session) {
                    renderAnnotation(response.session);
                } else {
                    $('#sessionAnnotationContent').html(
                        '<div class="text-center" style="padding:30px; color:#e67e22;">' +
                        '<i class="fa fa-hourglass-half fa-2x"></i><br><br>' +
                        '<strong>Processing...</strong><br>' +
                        '<small class="text-muted">The annotation pipeline is still running for this session.<br>Please check back in a moment.</small>' +
                        '</div>'
                    );
                    $('#manualSummaryBox').show();
                    $('#manualSummaryText').val('');
                }
            },
            error: function() {
                $('#sessionAnnotationContent').html('<div class="alert alert-danger">Error loading data. Please try again.</div>');
            }
        });
    }

    function renderAnnotation(s) {
        var concerns  = safeParseList(s.concerns);
        var triggers  = safeParseList(s.triggers);
        var advice    = safeParseList(s.advice);
        var readiness = s.readiness || 'unknown';
        var none      = '<span style="color:#999;font-size:11px;font-style:italic;">None</span>';
        var badgeColor = {
            'precontemplation': '#e74c3c', 'contemplation': '#e67e22',
            'preparation': '#f1c40f',      'action': '#2ecc71',
            'maintenance': '#27ae60',      'relapse': '#c0392b',
            'unknown': '#95a5a6'
        }[readiness] || '#95a5a6';

        var html = '';

        // Suicidal ideation — always shown
        if (s.suicidal_ideation) {
            html += '<div style="background:#c0392b;color:#fff;padding:10px 14px;border-radius:6px;margin-bottom:14px;display:flex;align-items:center;gap:10px;">';
            html += '  <span style="font-size:18px;">&#9888;</span>';
            html += '  <strong>Suicidal Ideation Detected — Immediate clinical review required.</strong>';
            html += '</div>';
        } else {
            html += '<div style="background:#eafaf1;color:#1e8449;padding:6px 12px;border-radius:6px;margin-bottom:14px;font-size:12px;">';
            html += '  &#10003; <strong>Suicidal Ideation:</strong> Not detected';
            html += '</div>';
        }

        // Header: date + stage badge
        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;">';
        html += '  <strong style="font-size:15px;">' + escapeHtml(s.session_date || 'N/A') + '</strong>';
        html += '  <span style="background:' + badgeColor + ';color:#fff;padding:4px 12px;border-radius:12px;font-size:12px;font-weight:bold;">' + escapeHtml(readiness.toUpperCase()) + '</span>';
        html += '</div>';

        // Quit history — always shown
        html += '<p style="font-size:13px;margin-bottom:8px;"><strong>Quit History:</strong> ';
        html += (s.quit_history && s.quit_history !== 'unknown') ? escapeHtml(s.quit_history) : none;
        html += '</p>';

        // Concerns — always shown
        html += '<p style="font-size:13px;margin-bottom:6px;"><strong>Concerns:</strong> ';
        if (concerns.length) {
            concerns.forEach(function(c) { html += '<span style="background:#fdecea;color:#c0392b;padding:2px 8px;border-radius:10px;font-size:11px;margin-right:4px;">' + escapeHtml(c) + '</span>'; });
        } else { html += none; }
        html += '</p>';

        // Triggers — always shown
        html += '<p style="font-size:13px;margin-bottom:6px;"><strong>Triggers:</strong> ';
        if (triggers.length) {
            triggers.forEach(function(t) { html += '<span style="background:#fef9e7;color:#856404;padding:2px 8px;border-radius:10px;font-size:11px;margin-right:4px;">' + escapeHtml(t) + '</span>'; });
        } else { html += none; }
        html += '</p>';

        // Recommended intervention — always shown
        html += '<p style="font-size:13px;margin-bottom:6px;"><strong>Recommended Intervention:</strong> ';
        if (advice.length) {
            advice.forEach(function(a) { html += '<span style="background:#eafaf1;color:#1e8449;padding:2px 8px;border-radius:10px;font-size:11px;margin-right:4px;">' + escapeHtml(a) + '</span>'; });
        } else { html += none; }
        html += '</p>';

        // Clinical reasoning — always shown
        html += '<div style="margin-top:12px;padding:12px;background:#f8f9fa;border-radius:5px;font-size:13px;line-height:1.6;">';
        html += '<strong>Clinical Reasoning:</strong><br>';
        html += s.session_summary ? escapeHtml(s.session_summary) : '<span style="color:#999;font-style:italic;">Not yet available</span>';
        html += '</div>';

        $('#sessionAnnotationContent').html(html);
        $('#manualSummaryBox').show();
        $('#manualSummaryText').val(s.session_summary || '');
    }

    function saveSessionSummary() {
        var summary = $('#manualSummaryText').val().trim();
        if (!_currentSummarySessionId) return;

        var btn = $('#saveSummaryBtn');
        btn.prop('disabled', true).text('Saving...');

        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/saveSessionSummary.jsp',
            type: 'POST',
            data: { session_id: _currentSummarySessionId, summary: summary },
            dataType: 'json',
            success: function(response) {
                btn.prop('disabled', false).text('Save Summary');
                if (response.success) {
                    var saved = '<div class="alert alert-success" style="margin-top:8px; padding:6px 12px; font-size:13px;">Saved successfully.</div>';
                    $('#saveFeedback').html(saved);
                    setTimeout(function(){ $('#saveFeedback').html(''); }, 3000);
                } else {
                    $('#saveFeedback').html('<div class="alert alert-danger" style="margin-top:8px; padding:6px 12px; font-size:13px;">Error: ' + (response.message || 'Save failed.') + '</div>');
                }
            },
            error: function() {
                btn.prop('disabled', false).text('Save Summary');
                $('#saveFeedback').html('<div class="alert alert-danger" style="margin-top:8px; padding:6px 12px; font-size:13px;">Request failed. Please try again.</div>');
            }
        });
    }

    function safeParseList(val) {
        if (!val) return [];
        try {
            var parsed = JSON.parse(val);
            return Array.isArray(parsed) ? parsed : [];
        } catch(e) { return val ? [val] : []; }
    }
    // ─────────────────────────────────────────────────────────────────────

    function loadChatHistory() {
        console.log('Loading chat history...');
        
        // Get patient ID using the same method as tobacco assessment
        var patId = window.currentPatientId || getPatientIdFromURL();
        
        if (!patId || patId.trim() === '') {
            alert('Patient ID not found. Please ensure you are accessing this page with a valid patient ID.');
            console.log('ERROR: No patient ID available');
            return;
        }
        
        console.log('Using patient ID for chat history:', patId);
        
        var fromDate = $('#chatFromDate').val();
        var toDate = $('#chatToDate').val();
        
        // Show loading
        $('#chatSessionsTableBody').html('<tr><td colspan="10" class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading sessions...</td></tr>');
        
        var requestData = {
            pat_id: patId,
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
                    
                    // Show success message with patient ID used
                    if (response.patient_id) {
                        console.log('Successfully loaded chat history for patient:', response.patient_id);
                    }
                } else {
                    console.log('Server returned error:', response.message);
                    $('#chatSessionsTableBody').html('<tr><td colspan="10" class="text-center text-danger">Error: ' + response.message + '</td></tr>');
                }
            },
            error: function(xhr, status, error) {
                console.error('AJAX error:', error);
                console.error('Response text:', xhr.responseText);
                $('#chatSessionsTableBody').html('<tr><td colspan="10" class="text-center text-danger">Error loading chat history. Please try again.</td></tr>');
            }
        });
    }

    function populateChatSessionsTable(sessions) {
        var tbody = $('#chatSessionsTableBody');
        tbody.empty();
        
        if (!sessions || sessions.length === 0) {
            tbody.append('<tr><td colspan="10" class="text-center">No chat sessions found for the selected date range</td></tr>');
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
            var isAnnotated = session.is_annotated === true || session.is_annotated === 'true';

            var statusBadge = getStatusBadge(status);

            var annotationBadge = isAnnotated
                ? '<span style="background:#28a745;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">Yes</span>'
                : '<span style="background:#dc3545;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:bold;">No</span>';

            var annotateBtn = isAnnotated
                ? '<button type="button" class="btn btn-sm btn-secondary" style="margin-left:6px;font-size:11px;" onclick="reannotateSession(\'' + session.session_id + '\', this)">'
                  + '<i class="fa fa-redo"></i> Reannotate</button>'
                : '<button type="button" class="btn btn-sm btn-warning" style="margin-left:6px;font-size:11px;" onclick="annotateSession(\'' + session.session_id + '\', this)">'
                  + '<i class="fa fa-cogs"></i> Annotate</button>';

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
            row += '<td>';
            row += '<button type="button" class="btn btn-sm btn-success" onclick="viewSessionSummary(\'' + session.session_id + '\')" title="View Session Summary">';
            row += '<i class="fa fa-file-alt"></i> View';
            row += '</button>';
            row += '</td>';
            row += '<td>';
            row += '<button type="button" class="btn btn-sm btn-info" onclick="viewSessionDelta(\'' + session.session_id + '\')" title="View Delta Summary">';
            row += '<i class="fa fa-exchange-alt"></i> View';
            row += '</button>';
            row += '</td>';
            var showThinkingBtn = isAnnotated
                ? ' <button type="button" class="btn btn-sm" style="margin-left:4px;font-size:11px;background:#5d4e7b;color:#fff;border:1px solid #4a3d64;" onclick="showPipelineRun(\'' + session.session_id + '\')" title="View AI reasoning trace"><i class="fa fa-brain"></i> Show Thinking</button>'
                : '';
            row += '<td style="white-space:nowrap;">' + annotationBadge + showThinkingBtn + annotateBtn + '</td>';
            row += '</tr>';

            tbody.append(row);
        }
    }

    function showQuickSummary() {
        var patId = window.currentPatientId || getPatientIdFromURL();
        
        if (!patId || patId.trim() === '') {
            alert('Patient ID not found. Please ensure you are accessing this page with a valid patient ID.');
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
    }

    function viewChatMessages(sessionId) {
        var patId = window.currentPatientId || getPatientIdFromURL();
        
        if (!patId) {
            alert('Patient ID not found. Please ensure you are accessing this page with a valid patient ID.');
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
    }

    function populateChatMessages(messages) {
        var container = $('#chatMessagesContainer');
        container.empty();
        
        if (!messages || messages.length === 0) {
            container.append('<div class="text-center">No messages found in this session</div>');
            return;
        }
        
        for (var i = 0; i < messages.length; i++) {
            var message = messages[i];
            var messageDiv = '<div class="chat-message" style="margin-bottom: 15px; padding: 12px; border-radius: 10px; ';
            
            // Set background color based on sender type
            if (message.sender_type === 'patient') {
                messageDiv += 'background-color: #e3f2fd; border-left: 4px solid #2196f3;">';
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
    }

    // Utility functions (keeping the same)
    function formatDate(dateString) {
        if (!dateString) return 'N/A';
        try {
            var date = new Date(dateString);
            return date.toLocaleDateString();
        } catch (e) {
            return dateString;
        }
    }

    function formatTime(timeString) {
        if (!timeString) return 'N/A';
        try {
            var date = new Date(timeString);
            return date.toLocaleTimeString();
        } catch (e) {
            return timeString;
        }
    }

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0) return '0m';
        
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        
        if (hours > 0) {
            return hours + 'h ' + minutes + 'm';
        } else {
            return minutes + 'm';
        }
    }

    function formatTimestamp(timestamp) {
        if (!timestamp) return '';
        try {
            var date = new Date(timestamp);
            return date.toLocaleString();
        } catch (e) {
            return timestamp;
        }
    }

    function getStatusBadge(status) {
        var color = '#6c757d';
        var text = status ? status.toUpperCase() : 'UNKNOWN';
        
        switch (status) {
            case 'completed':
                color = '#28a745';
                break;
            case 'active':
                color = '#007bff';
                break;
            case 'terminated':
                color = '#dc3545';
                break;
        }
        
        return '<span style="background-color: ' + color + '; color: white; padding: 4px 8px; border-radius: 12px; font-size: 11px; font-weight: bold;">' + text + '</span>';
    }

    // ── Delta Summary Modal ───────────────────────────────────────────
    var _currentDeltaSessionId = null;

    function viewSessionDelta(sessionId) {
        _currentDeltaSessionId = sessionId;
        $('#sessionDeltaModal').modal('show');
        $('#sessionDeltaContent').html(
            '<div class="text-center" style="padding:30px;"><i class="fa fa-spinner fa-spin fa-2x"></i><br><br>Loading...</div>'
        );
        $('#deltaSummaryBox').hide();

        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getSessionDelta.jsp',
            type: 'POST',
            data: { session_id: sessionId },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    renderDelta(response.delta);
                } else if (response.message === 'no_delta') {
                    $('#sessionDeltaContent').html(
                        '<div class="text-center" style="padding:30px;color:#e67e22;">' +
                        '<i class="fa fa-info-circle fa-2x"></i><br><br>' +
                        '<strong>No delta available</strong><br>' +
                        '<small class="text-muted">This is the first session — no prior session to compare against.</small>' +
                        '</div>'
                    );
                } else {
                    $('#sessionDeltaContent').html('<div class="alert alert-danger">Error: ' + escapeHtml(response.message) + '</div>');
                }
            },
            error: function() {
                $('#sessionDeltaContent').html('<div class="alert alert-danger">Request failed. Please try again.</div>');
            }
        });
    }

    function renderDelta(d) {
        var html = '';

        // ── Stage transition ──────────────────────────────────────────
        var before = d.readiness_before || 'unknown';
        var after  = d.readiness_after  || 'unknown';
        var directionColor = { progress:'#27ae60', regression:'#e74c3c', stable:'#f39c12', relapse:'#c0392b', recovery:'#2980b9' };
        var stageColor = {
            precontemplation:'#e74c3c', contemplation:'#e67e22', preparation:'#f1c40f',
            action:'#2ecc71', maintenance:'#27ae60', relapse:'#c0392b', unknown:'#95a5a6'
        };
        var direction = d.readiness_changed == 1 ? detectDirection(before, after) : 'stable';
        var dColor = directionColor[direction] || '#95a5a6';

        html += '<div style="background:#f8f9fa;border-radius:8px;padding:14px;margin-bottom:16px;text-align:center;">';
        html += '<div style="font-size:12px;color:#7f8c8d;margin-bottom:8px;font-weight:bold;">STAGE TRANSITION</div>';
        html += '<span style="background:' + (stageColor[before]||'#95a5a6') + ';color:#fff;padding:4px 12px;border-radius:12px;font-size:13px;font-weight:bold;">' + escapeHtml(before.toUpperCase()) + '</span>';
        html += ' <i class="fa fa-arrow-right" style="color:' + dColor + ';margin:0 10px;"></i> ';
        html += '<span style="background:' + (stageColor[after]||'#95a5a6') + ';color:#fff;padding:4px 12px;border-radius:12px;font-size:13px;font-weight:bold;">' + escapeHtml(after.toUpperCase()) + '</span>';
        html += ' &nbsp;<span style="background:' + dColor + ';color:#fff;padding:3px 10px;border-radius:10px;font-size:11px;font-weight:bold;">' + direction.toUpperCase() + '</span>';
        html += '</div>';

        // ── Clinical flags — always shown ─────────────────────────────
        var flags = [];
        if (d.relapse_detected        == 1) flags.push({label:'Relapse Detected',        color:'#c0392b', icon:'fa-exclamation-triangle'});
        if (d.rapid_progress_detected == 1) flags.push({label:'Rapid Progress Detected', color:'#27ae60', icon:'fa-rocket'});
        if (d.progress_detected == 1 && d.rapid_progress_detected != 1)
                                            flags.push({label:'Progress Detected',        color:'#2ecc71', icon:'fa-arrow-up'});
        if (d.stagnation_detected     == 1) flags.push({label:'Stagnation Detected',      color:'#e67e22', icon:'fa-pause-circle'});
        if (d.concern_shift_detected  == 1) flags.push({label:'Concern Shift Detected',   color:'#8e44ad', icon:'fa-exchange-alt'});
        if (d.trigger_resolved        == 1) flags.push({label:'Trigger Resolved',         color:'#16a085', icon:'fa-check-circle'});

        html += '<div style="margin-bottom:14px;">';
        html += '<div style="font-size:12px;color:#7f8c8d;font-weight:bold;margin-bottom:6px;">CLINICAL FLAGS</div>';
        if (flags.length) {
            flags.forEach(function(f) {
                html += '<span style="background:' + f.color + ';color:#fff;padding:3px 10px;border-radius:10px;font-size:12px;font-weight:bold;margin-right:6px;margin-bottom:4px;display:inline-block;">';
                html += '<i class="fa ' + (f.icon||'fa-flag') + '"></i> ' + escapeHtml(f.label) + '</span>';
            });
        } else {
            html += '<span style="color:#999;font-size:11px;font-style:italic;">None</span>';
        }
        html += '</div>';

        // ── Signal sections — always shown ────────────────────────────
        html += renderDeltaSection('Triggers',
            safeParseList(d.new_triggers),         '#e74c3c',  'New',
            safeParseList(d.resolved_triggers),    '#27ae60',  'Resolved',
            safeParseList(d.persistent_triggers),  '#7f8c8d',  'Persistent'
        );
        html += renderDeltaSection('Concerns',
            safeParseList(d.new_concerns),         '#e74c3c',  'New',
            safeParseList(d.resolved_concerns),    '#27ae60',  'Resolved',
            safeParseList(d.persistent_concerns),  '#7f8c8d',  'Persistent'
        );
        html += renderDeltaSection('Interventions',
            safeParseList(d.new_advice),           '#2980b9',  'New',
            safeParseList(d.continued_advice),     '#7f8c8d',  'Continuing',
            safeParseList(d.dropped_advice),       '#e74c3c',  'Dropped'
        );

        // ── Quit attempt history — always shown ───────────────────────
        var newQuit = safeParseList(d.new_quit_attempts);
        html += '<div style="margin-bottom:14px;">';
        html += '<div style="font-size:12px;color:#7f8c8d;font-weight:bold;margin-bottom:6px;">QUIT ATTEMPT HISTORY</div>';
        if (newQuit.length) {
            newQuit.forEach(function(q) {
                html += '<span style="background:#8e44ad;color:#fff;padding:2px 8px;border-radius:10px;font-size:11px;margin-right:4px;margin-bottom:4px;display:inline-block;">New: ' + escapeHtml(q) + '</span>';
            });
        } else {
            html += '<span style="color:#999;font-size:11px;font-style:italic;">No new quit attempts</span>';
        }
        html += '<p style="font-size:12px;color:#555;margin-top:8px;margin-bottom:0;"><strong>Cumulative:</strong> ';
        html += (d.cumulative_quit_history && d.cumulative_quit_history !== 'unknown')
            ? escapeHtml(d.cumulative_quit_history)
            : '<span style="color:#999;font-style:italic;">None</span>';
        html += '</p>';
        html += '</div>';

        // ── Clinical summary — always shown ───────────────────────────
        html += '<div style="margin-bottom:14px;padding:12px;background:#f8f9fa;border-radius:5px;font-size:13px;line-height:1.6;">';
        html += '<strong>Clinical Summary:</strong><br>';
        html += d.clinical_summary ? escapeHtml(d.clinical_summary) : '<span style="color:#999;font-style:italic;">Not yet available</span>';
        html += '</div>';

        $('#sessionDeltaContent').html(html);

        // ── Editable clinical summary ─────────────────────────────────
        $('#deltaSummaryText').val(d.clinical_summary || '');
        $('#deltaSummaryBox').show();
    }

    function renderDeltaSection(title, listA, colorA, labelA, listB, colorB, labelB, listC, colorC, labelC) {
        var html = '<div style="margin-bottom:14px;">';
        html += '<div style="font-size:12px;color:#7f8c8d;font-weight:bold;margin-bottom:6px;">' + title.toUpperCase() + '</div>';

        function pills(items, color, label) {
            if (!items.length) return '';
            var h = '<div style="margin-bottom:4px;">';
            h += '<span style="font-size:11px;color:' + color + ';font-weight:bold;margin-right:4px;">' + label + ':</span>';
            items.forEach(function(item) {
                h += '<span style="background:' + color + '22;color:' + color + ';border:1px solid ' + color + '44;padding:2px 8px;border-radius:10px;font-size:11px;margin-right:4px;">' + escapeHtml(item) + '</span>';
            });
            h += '</div>';
            return h;
        }

        var body = pills(listA, colorA, labelA) + pills(listB, colorB, labelB) + pills(listC, colorC, labelC);
        html += body || '<span style="color:#999;font-size:11px;font-style:italic;">None</span>';
        html += '</div>';
        return html;
    }

    function detectDirection(before, after) {
        var order = {precontemplation:0, contemplation:1, preparation:2, action:3, maintenance:4, relapse:-1};
        if (after === 'relapse') return 'relapse';
        if (before === 'relapse') return 'recovery';
        var b = order[before], a = order[after];
        if (b === undefined || a === undefined) return 'stable';
        if (a > b) return 'progress';
        if (a < b) return 'regression';
        return 'stable';
    }

    function saveDeltaSummary() {
        if (!_currentDeltaSessionId) return;
        var summary = $('#deltaSummaryText').val().trim();
        var btn = $('#saveDeltaBtn');
        btn.prop('disabled', true).text('Saving...');
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/saveDeltaSummary.jsp',
            type: 'POST',
            data: { session_id: _currentDeltaSessionId, clinical_summary: summary },
            dataType: 'json',
            success: function(response) {
                btn.prop('disabled', false).text('Save');
                if (response.success) {
                    $('#deltaFeedback').html('<div class="alert alert-success" style="padding:6px 12px;font-size:12px;margin-top:6px;">Saved.</div>');
                    setTimeout(function(){ $('#deltaFeedback').html(''); }, 2500);
                } else {
                    $('#deltaFeedback').html('<div class="alert alert-danger" style="padding:6px 12px;font-size:12px;margin-top:6px;">Error: ' + escapeHtml(response.message) + '</div>');
                }
            },
            error: function() {
                btn.prop('disabled', false).text('Save');
                $('#deltaFeedback').html('<div class="alert alert-danger" style="padding:6px 12px;font-size:12px;margin-top:6px;">Request failed.</div>');
            }
        });
    }
    // ─────────────────────────────────────────────────────────────────

    function reannotateSession(sessionId, btn) {
        var patId = window.currentPatientId || getPatientIdFromURL();
        if (!patId) { alert('Patient ID not found.'); return; }
        if (!confirm('This will overwrite the existing annotation for this session. Continue?')) return;
        $(btn).prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Starting...');
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/annotateSession.jsp',
            type: 'POST',
            data: { pat_id: patId, session_id: sessionId, force: 'true' },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    $(btn).removeClass('btn-secondary').addClass('btn-info')
                          .html('<i class="fa fa-clock"></i> Processing...');
                } else {
                    $(btn).prop('disabled', false).html('<i class="fa fa-redo"></i> Reannotate');
                    alert('Error: ' + response.message);
                }
            },
            error: function() {
                $(btn).prop('disabled', false).html('<i class="fa fa-redo"></i> Reannotate');
                alert('Request failed. Please try again.');
            }
        });
    }

    function annotateSession(sessionId, btn) {
        var patId = window.currentPatientId || getPatientIdFromURL();
        if (!patId) {
            alert('Patient ID not found.');
            return;
        }
        $(btn).prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Starting...');
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/annotateSession.jsp',
            type: 'POST',
            data: { pat_id: patId, session_id: sessionId },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    $(btn).removeClass('btn-warning').addClass('btn-info')
                          .html('<i class="fa fa-clock"></i> Processing...');
                } else {
                    $(btn).prop('disabled', false).html('<i class="fa fa-cogs"></i> Annotate');
                    alert('Error: ' + response.message);
                }
            },
            error: function() {
                $(btn).prop('disabled', false).html('<i class="fa fa-cogs"></i> Annotate');
                alert('Request failed. Please try again.');
            }
        });
    }

    function escapeHtml(text) {
        if (!text) return '';
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    // ── Pipeline Run Thinking Report ────────────────────────────────────────

    function showPipelineRun(sessionId) {
        var patId = window.currentPatientId || getPatientIdFromURL();
        $('#pipelineRunBody').html(
            '<div style="text-align:center;padding:60px;color:#888;">' +
            '<i class="fa fa-spinner fa-spin fa-2x"></i><br><br>Loading pipeline run...</div>'
        );
        $('#pipelineRunModal').modal('show');
        $.ajax({
            url: '<%=request.getContextPath()%>/jspfiles/getPipelineRun.jsp',
            type: 'POST',
            data: { session_id: sessionId, pat_id: patId },
            dataType: 'json',
            success: function(resp) {
                if (resp.success && resp.run) {
                    $('#pipelineRunBody').html(renderPipelineRunDoc(resp.run));
                } else {
                    $('#pipelineRunBody').html(
                        '<div class="alert alert-warning" style="margin:24px;">' +
                        escapeHtml(resp.message || 'No pipeline run found for this session.') + '</div>'
                    );
                }
            },
            error: function() {
                $('#pipelineRunBody').html(
                    '<div class="alert alert-danger" style="margin:24px;">Failed to load pipeline run data.</div>'
                );
            }
        });
    }

    function renderPipelineRunDoc(run) {
        var h = '';
        h += '<div style="font-family:\'Segoe UI\',Arial,sans-serif;background:#fff;padding:32px 36px;border-radius:4px;box-shadow:0 1px 4px rgba(0,0,0,.10);color:#1a1a2e;">';

        // ── Cover block ────────────────────────────────────────────────────────
        h += '<div style="border-bottom:3px solid #2c3e50;padding-bottom:20px;margin-bottom:28px;">';
        h += '<div style="font-size:10px;font-weight:700;letter-spacing:2px;color:#aaa;text-transform:uppercase;margin-bottom:4px;">Annotation Pipeline</div>';
        h += '<h2 style="margin:0 0 18px;font-size:20px;font-weight:700;color:#2c3e50;">Thinking Report</h2>';
        h += '<table style="width:100%;font-size:12px;color:#444;border-collapse:collapse;"><tr>';
        h += '<td style="padding:0 24px 0 0;vertical-align:top;"><div style="font-size:10px;color:#bbb;text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px;">Run ID</div><div style="font-family:monospace;font-size:11px;color:#666;">' + escapeHtml(run.run_id || '—') + '</div></td>';
        h += '<td style="padding:0 24px;vertical-align:top;"><div style="font-size:10px;color:#bbb;text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px;">Session</div><div style="font-family:monospace;font-size:11px;color:#666;">' + escapeHtml(run.conversation_id || '—') + '</div></td>';
        h += '<td style="padding:0 24px;vertical-align:top;"><div style="font-size:10px;color:#bbb;text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px;">Patient</div><div style="font-size:12px;font-weight:600;color:#333;">' + escapeHtml(run.patient_id || '—') + '</div></td>';
        h += '<td style="padding:0 24px;vertical-align:top;"><div style="font-size:10px;color:#bbb;text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px;">Processed At</div><div style="font-size:12px;">' + escapeHtml(run.created_at || '—') + '</div></td>';
        h += '<td style="padding:0 0 0 24px;vertical-align:top;"><div style="font-size:10px;color:#bbb;text-transform:uppercase;letter-spacing:.8px;margin-bottom:3px;">Rounds</div><div style="font-size:22px;font-weight:700;color:#2c3e50;line-height:1;">' + (run.total_rounds || 0) + '</div></td>';
        h += '</tr></table></div>';

        // ── 1. Extraction Rounds ───────────────────────────────────────────────
        h += prSect('1', 'Extraction Rounds', '#2980b9');
        var rounds = run.rounds || [];
        if (rounds.length > 0) {
            for (var r = 0; r < rounds.length; r++) { h += renderRound(rounds[r]); }
        } else {
            h += prEmpty('No round data recorded.');
        }

        // ── 2. Consensus ──────────────────────────────────────────────────────
        h += prSect('2', 'Consensus', '#8e44ad');
        h += renderConsensus(run.consensus);

        // ── 3. Final Annotation ───────────────────────────────────────────────
        h += prSect('3', 'Final Annotation', '#27ae60');
        h += renderDatasetRow(run.dataset_row);

        // ── 4. Session Delta ──────────────────────────────────────────────────
        if (run.session_delta) {
            h += prSect('4', 'Session Delta', '#e67e22');
            h += renderPrDelta(run.session_delta);
        }

        // ── 5. Longitudinal Analysis ──────────────────────────────────────────
        if (run.longitudinal_sanity || run.longitudinal_output) {
            h += prSect('5', 'Longitudinal Analysis', '#c0392b');
            if (run.longitudinal_sanity) {
                h += prSubHead('Sanity Check');
                h += renderGenericObj(run.longitudinal_sanity);
            }
            if (run.longitudinal_output) {
                h += prSubHead('Profile Update');
                h += renderGenericObj(run.longitudinal_output);
            }
        }

        h += '</div>';
        return h;
    }

    function prSect(num, title, color) {
        return '<div style="margin:28px 0 14px;">'
             + '<div style="display:flex;align-items:center;gap:10px;border-bottom:2px solid ' + color + ';padding-bottom:8px;">'
             + '<span style="background:' + color + ';color:#fff;font-size:10px;font-weight:800;padding:3px 10px;border-radius:3px;letter-spacing:.8px;">' + num + '</span>'
             + '<span style="font-size:13px;font-weight:700;color:' + color + ';text-transform:uppercase;letter-spacing:.8px;">' + title + '</span>'
             + '</div></div>';
    }

    function prSubHead(title) {
        return '<div style="margin:14px 0 8px;font-size:11px;font-weight:700;color:#888;text-transform:uppercase;letter-spacing:.8px;border-left:3px solid #ddd;padding-left:8px;">' + escapeHtml(title) + '</div>';
    }

    function prEmpty(msg) {
        return '<div style="color:#bbb;font-size:13px;font-style:italic;padding:8px 0;">' + escapeHtml(msg) + '</div>';
    }

    function prBadge(text, color) {
        return '<span style="display:inline-block;background:' + (color || '#666') + ';color:#fff;padding:2px 10px;border-radius:12px;font-size:12px;font-weight:600;">' + escapeHtml(String(text || '')) + '</span>';
    }

    function prTag(text, bgColor) {
        var bg = bgColor || '#ecf0f1';
        var fg = bgColor ? '#fff' : '#555';
        return '<span style="display:inline-block;background:' + bg + ';color:' + fg + ';padding:2px 8px;border-radius:3px;font-size:11px;margin:2px 3px 2px 0;border:1px solid rgba(0,0,0,.07);">' + escapeHtml(String(text || '')) + '</span>';
    }

    function prTblRow(label, valHtml) {
        return '<tr style="border-bottom:1px solid #f0f0f0;">'
             + '<td style="padding:7px 16px 7px 0;font-size:10px;font-weight:600;color:#aaa;text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;vertical-align:top;width:180px;">' + label + '</td>'
             + '<td style="padding:7px 0;vertical-align:top;">' + valHtml + '</td>'
             + '</tr>';
    }

    function renderRound(round) {
        var h = '';
        var isRevRound = round.round_number > 1;
        var hdrBg = isRevRound ? '#c0392b' : '#2980b9';
        h += '<div style="border:1px solid #d8e6f0;border-radius:4px;margin-bottom:12px;overflow:hidden;">';
        h += '<div style="background:' + hdrBg + ';color:#fff;padding:8px 14px;font-size:11px;font-weight:700;letter-spacing:.8px;">';
        h += 'ROUND ' + round.round_number + (isRevRound ? '  —  REVISION' : '');
        h += '</div>';

        if (round.extraction && Object.keys(round.extraction).length > 0) {
            h += '<div style="padding:14px;border-bottom:1px solid #f0f0f0;">';
            h += '<div style="font-size:10px;font-weight:700;color:#2980b9;text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;">Extraction</div>';
            h += renderSignalTable(round.extraction);
            h += '</div>';
        }

        if (round.confidence && Object.keys(round.confidence).length > 0) {
            h += '<div style="padding:14px;border-bottom:1px solid #f0f0f0;background:#fafcff;">';
            h += '<div style="font-size:10px;font-weight:700;color:#27ae60;text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;">Confidence Scores</div>';
            h += renderConfTable(round.confidence);
            h += '</div>';
        }

        if (round.revision && Object.keys(round.revision).length > 0) {
            h += '<div style="padding:14px;background:#fffbf4;">';
            h += '<div style="font-size:10px;font-weight:700;color:#e67e22;text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;">Revised Signals</div>';
            h += renderSignalTable(round.revision);
            h += '</div>';
        }

        h += '</div>';
        return h;
    }

    var _signalDefs = [
        { key: 'advice',    label: 'Advice',        arrField: 'advice'   },
        { key: 'attempt',   label: 'Quit Attempts',  arrField: 'attempts' },
        { key: 'readiness', label: 'Readiness',      arrField: null       },
        { key: 'concern',   label: 'Concerns',       arrField: 'concerns' },
        { key: 'trigger',   label: 'Triggers',       arrField: 'triggers' }
    ];

    function renderSignalTable(signals) {
        var h = '<table style="width:100%;font-size:12px;border-collapse:collapse;">';
        for (var i = 0; i < _signalDefs.length; i++) {
            var def = _signalDefs[i];
            var val = signals[def.key];
            if (!val) continue;

            h += '<tr style="border-bottom:1px solid #f5f5f5;">';
            h += '<td style="padding:5px 14px 5px 0;font-size:10px;font-weight:700;color:#999;text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;vertical-align:top;width:110px;">' + def.label + '</td>';
            h += '<td style="padding:5px 0;vertical-align:top;">';

            if (def.key === 'readiness') {
                h += prBadge(val.readiness_stage || 'unknown', '#2980b9');
                if (val.evidence) {
                    h += ' <span style="font-size:11px;color:#999;font-style:italic;">' + escapeHtml(String(val.evidence)) + '</span>';
                }
            } else {
                var items = val[def.arrField] || [];
                if (typeof items === 'string') items = [items];
                if (!Array.isArray(items)) items = [];
                if (items.length > 0) {
                    for (var j = 0; j < items.length; j++) { h += prTag(items[j]); }
                } else {
                    h += '<span style="color:#ccc;font-style:italic;font-size:11px;">none recorded</span>';
                }
                var ev = val.evidence;
                if (Array.isArray(ev) && ev.length > 0) {
                    h += '<div style="margin-top:3px;font-size:10px;color:#bbb;font-style:italic;">Evidence: ' + escapeHtml(ev.slice(0, 2).join(' · ')) + (ev.length > 2 ? ' …' : '') + '</div>';
                } else if (typeof ev === 'string' && ev) {
                    h += '<div style="margin-top:3px;font-size:10px;color:#bbb;font-style:italic;">Evidence: ' + escapeHtml(ev) + '</div>';
                }
            }

            h += '</td></tr>';
        }
        h += '</table>';
        return h;
    }

    function renderConfTable(conf) {
        var h = '<table style="width:100%;font-size:12px;border-collapse:collapse;">';
        var confLabels = { advice: 'Advice', attempt: 'Quit Attempts', readiness: 'Readiness', concern: 'Concerns', triggers: 'Triggers' };
        for (var i = 0; i < _signalDefs.length; i++) {
            var key = _signalDefs[i].key;
            var val = conf[key];
            if (!val) continue;
            var score  = (val.confidence !== undefined && val.confidence !== null) ? val.confidence : null;
            var issues = val.issues || [];
            var scoreStr = score !== null ? Math.round(score * 100) + '%' : '—';
            var scoreBg  = score === null ? '#bbb' : score >= 0.80 ? '#27ae60' : score >= 0.60 ? '#e67e22' : '#e74c3c';
            h += '<tr style="border-bottom:1px solid #f5f5f5;">';
            h += '<td style="padding:5px 14px 5px 0;font-size:10px;font-weight:700;color:#999;text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;width:110px;">' + (confLabels[key] || key) + '</td>';
            h += '<td style="padding:5px 10px 5px 0;width:54px;"><span style="background:' + scoreBg + ';color:#fff;font-size:11px;font-weight:700;padding:2px 8px;border-radius:10px;">' + scoreStr + '</span></td>';
            h += '<td style="padding:5px 0;font-size:11px;">';
            if (issues.length === 0) {
                h += '<span style="color:#27ae60;">&#10003; No issues</span>';
            } else {
                h += '<span style="color:#e74c3c;">&#9888; ' + escapeHtml(issues.join(' · ')) + '</span>';
            }
            h += '</td></tr>';
        }
        h += '</table>';
        return h;
    }

    function renderConsensus(c) {
        if (!c || Object.keys(c).length === 0) return prEmpty('No consensus data recorded.');
        var h = '<div style="background:#fdf8ff;border:1px solid #e8d5f5;border-radius:4px;padding:16px;">';
        h += '<table style="width:100%;font-size:13px;border-collapse:collapse;">';
        h += prTblRow('Stage of Change', prBadge(c.stage_of_change || 'unknown', '#8e44ad'));
        if (c.vote_agreement !== undefined && c.vote_agreement !== null) {
            var agr = Math.round(c.vote_agreement * 100);
            var agrColor = agr >= 80 ? '#27ae60' : agr >= 60 ? '#e67e22' : '#e74c3c';
            h += prTblRow('Vote Agreement', '<span style="font-size:15px;font-weight:700;color:' + agrColor + ';">' + agr + '%</span>');
        }
        h += prTblRow('Suicidal Ideation', c.suicidal_ideation
            ? '<span style="color:#e74c3c;font-weight:700;">YES &#9888;</span>'
            : '<span style="color:#27ae60;">No</span>');
        if (c.all_concerns && c.all_concerns.length > 0)             { h += prTblRow('Concerns', c.all_concerns.map(function(x){ return prTag(x); }).join('')); }
        if (c.all_triggers && c.all_triggers.length > 0)             { h += prTblRow('Triggers', c.all_triggers.map(function(x){ return prTag(x); }).join('')); }
        if (c.recommended_intervention && c.recommended_intervention.length > 0) { h += prTblRow('Interventions', c.recommended_intervention.map(function(x){ return prTag(x, '#27ae60'); }).join('')); }
        if (c.quit_attempt_history)                                   { h += prTblRow('Quit History', '<em style="font-size:12px;color:#666;">' + escapeHtml(c.quit_attempt_history) + '</em>'); }
        if (c.dissenting_fields && c.dissenting_fields.length > 0)   { h += prTblRow('Dissenting Fields', c.dissenting_fields.map(function(x){ return prTag(x, '#e67e22'); }).join('')); }
        h += '</table></div>';
        return h;
    }

    function renderDatasetRow(dr) {
        if (!dr || Object.keys(dr).length === 0) return prEmpty('No final annotation data recorded.');
        var h = '<div style="background:#f4fff8;border:1px solid #b7f0ce;border-radius:4px;padding:16px;">';
        h += '<table style="width:100%;font-size:13px;border-collapse:collapse;">';
        h += prTblRow('Stage of Change', prBadge(dr.stage_of_change || 'unknown', '#27ae60'));
        h += prTblRow('Suicidal Ideation', dr.suicidal_ideation
            ? '<span style="color:#e74c3c;font-weight:700;">YES &#9888;</span>'
            : '<span style="color:#27ae60;">No</span>');
        if (dr.quit_attempt_history) { h += prTblRow('Quit History', '<em style="font-size:12px;color:#666;">' + escapeHtml(dr.quit_attempt_history) + '</em>'); }
        if (dr.all_concerns && dr.all_concerns.length > 0)             { h += prTblRow('Concerns', dr.all_concerns.map(function(x){ return prTag(x); }).join('')); }
        if (dr.all_triggers && dr.all_triggers.length > 0)             { h += prTblRow('Triggers', dr.all_triggers.map(function(x){ return prTag(x); }).join('')); }
        if (dr.recommended_intervention && dr.recommended_intervention.length > 0) { h += prTblRow('Interventions', dr.recommended_intervention.map(function(x){ return prTag(x, '#27ae60'); }).join('')); }
        h += '</table>';
        if (dr.reasoning_summary) {
            h += '<div style="margin-top:14px;padding-top:12px;border-top:1px solid #b7f0ce;">';
            h += '<div style="font-size:10px;font-weight:700;color:#27ae60;text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px;">Reasoning Summary</div>';
            h += '<div style="font-size:13px;color:#333;line-height:1.65;white-space:pre-wrap;">' + escapeHtml(dr.reasoning_summary) + '</div>';
            h += '</div>';
        }
        h += '</div>';
        return h;
    }

    function renderPrDelta(delta) {
        if (!delta || Object.keys(delta).length === 0) return prEmpty('No delta data recorded.');
        var h = '<div style="background:#fffaf4;border:1px solid #f5d5a0;border-radius:4px;padding:16px;">';
        h += '<table style="width:100%;font-size:13px;border-collapse:collapse;">';
        if (delta.from_session !== undefined && delta.to_session !== undefined) {
            h += prTblRow('Sessions', 'Session ' + delta.from_session + ' &rarr; Session ' + delta.to_session);
        }
        if (delta.stage_before && delta.stage_after) {
            var dirColors = { progress: '#27ae60', regression: '#e74c3c', relapse: '#e74c3c', recovery: '#27ae60', stable: '#888', unknown: '#aaa' };
            var arrowColor = dirColors[delta.stage_direction] || '#888';
            h += prTblRow('Stage', prBadge(delta.stage_before, '#888') + ' <span style="color:' + arrowColor + ';font-weight:700;margin:0 6px;">&rarr;</span>' + prBadge(delta.stage_after, arrowColor));
        }
        if (delta.stage_direction) {
            var dirLabels = { progress: '&#8593; Progress', regression: '&#8595; Regression', relapse: '&#9888; Relapse', recovery: '&#8593; Recovery', stable: '&#8594; Stable', unknown: '? Unknown' };
            var dirColors2 = { progress: '#27ae60', regression: '#e74c3c', relapse: '#e74c3c', recovery: '#27ae60', stable: '#888', unknown: '#aaa' };
            h += prTblRow('Direction', '<span style="font-weight:700;color:' + (dirColors2[delta.stage_direction] || '#888') + ';">' + (dirLabels[delta.stage_direction] || escapeHtml(delta.stage_direction)) + '</span>');
        }
        var listFields = [
            ['new_triggers', 'New Triggers'], ['resolved_triggers', 'Resolved Triggers'], ['persistent_triggers', 'Persistent Triggers'],
            ['new_concerns', 'New Concerns'], ['resolved_concerns', 'Resolved Concerns'], ['persistent_concerns', 'Persistent Concerns'],
            ['new_interventions', 'New Interventions'], ['continuing_interventions', 'Continuing Interventions'], ['dropped_interventions', 'Dropped Interventions'],
            ['new_quit_attempts', 'New Quit Attempts']
        ];
        for (var lf = 0; lf < listFields.length; lf++) {
            var arr = delta[listFields[lf][0]];
            if (arr && arr.length > 0) { h += prTblRow(listFields[lf][1], arr.map(function(x){ return prTag(x); }).join('')); }
        }
        if (delta.cumulative_quit_history) { h += prTblRow('Cumulative Quit History', '<em style="font-size:12px;color:#666;">' + escapeHtml(delta.cumulative_quit_history) + '</em>'); }
        var boolFlags = [
            ['relapse_detected', 'Relapse Detected'], ['rapid_progress_detected', 'Rapid Progress'],
            ['stagnation_detected', 'Stagnation Detected'], ['concern_shift_detected', 'Concern Shift'],
            ['trigger_resolved', 'Trigger Resolved']
        ];
        var flagHtml = '';
        for (var bf = 0; bf < boolFlags.length; bf++) {
            if (delta[boolFlags[bf][0]]) { flagHtml += '<span style="background:#e74c3c;color:#fff;padding:2px 8px;border-radius:3px;font-size:11px;margin-right:5px;">' + boolFlags[bf][1] + '</span>'; }
        }
        if (flagHtml) { h += prTblRow('Clinical Flags', flagHtml); }
        h += '</table>';
        if (delta.clinical_summary) {
            h += '<div style="margin-top:14px;padding-top:12px;border-top:1px solid #f5d5a0;">';
            h += '<div style="font-size:10px;font-weight:700;color:#e67e22;text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px;">Clinical Summary</div>';
            h += '<div style="font-size:13px;color:#333;line-height:1.65;white-space:pre-wrap;">' + escapeHtml(delta.clinical_summary) + '</div>';
            h += '</div>';
        }
        h += '</div>';
        return h;
    }

    function renderGenericObj(obj) {
        if (!obj || Object.keys(obj).length === 0) return prEmpty('No data recorded.');
        var h = '<div style="background:#fff;border:1px solid #e0e0e0;border-radius:4px;padding:14px;">';
        h += '<table style="width:100%;font-size:12px;border-collapse:collapse;">';
        for (var key in obj) {
            if (!obj.hasOwnProperty(key)) continue;
            var val = obj[key];
            var display = '';
            if (val === null || val === undefined) {
                display = '<span style="color:#ccc;font-style:italic;">null</span>';
            } else if (typeof val === 'boolean') {
                display = val ? '<span style="color:#27ae60;font-weight:600;">Yes</span>' : '<span style="color:#aaa;">No</span>';
            } else if (Array.isArray(val)) {
                if (val.length === 0) {
                    display = '<span style="color:#ccc;font-style:italic;">[]</span>';
                } else if (typeof val[0] === 'string') {
                    display = val.map(function(x){ return prTag(x); }).join('');
                } else {
                    display = '<pre style="margin:0;font-size:10px;background:#f8f8f8;padding:6px;border-radius:2px;max-height:120px;overflow-y:auto;">' + escapeHtml(JSON.stringify(val, null, 2)) + '</pre>';
                }
            } else if (typeof val === 'object') {
                display = '<pre style="margin:0;font-size:10px;background:#f8f8f8;padding:6px;border-radius:2px;max-height:120px;overflow-y:auto;">' + escapeHtml(JSON.stringify(val, null, 2)) + '</pre>';
            } else {
                display = '<span style="color:#333;">' + escapeHtml(String(val)) + '</span>';
            }
            h += '<tr style="border-bottom:1px solid #f5f5f5;">';
            h += '<td style="padding:5px 14px 5px 0;font-size:10px;font-weight:600;color:#aaa;text-transform:capitalize;white-space:nowrap;vertical-align:top;width:200px;">' + escapeHtml(key.replace(/_/g, ' ')) + '</td>';
            h += '<td style="padding:5px 0;vertical-align:top;">' + display + '</td>';
            h += '</tr>';
        }
        h += '</table></div>';
        return h;
    }

    // ── End Pipeline Run Thinking Report ───────────────────────────────────
    </script>
</head>

<%!
    // Helper methods for FTND scoring
    private static int scoreFTNDQ1(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("after 60") || cleaned.contains("after60")) return 0;
        if (cleaned.contains("31") && (cleaned.contains("60") || cleaned.contains("-"))) return 1;
        if (cleaned.contains("6") && (cleaned.contains("30") || cleaned.contains("-"))) return 2;
        if (cleaned.contains("within 5") || cleaned.contains("within5")) return 3;

        return 0;
    }

    private static int scoreFTNDQ3(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("first") && cleaned.contains("morning")) return 1;
        return 0;
    }

    private static int scoreFTNDQ4(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("10 or less") || cleaned.contains("10 or fewer")) return 0;
        if (cleaned.contains("11") && cleaned.contains("20")) return 1;
        if (cleaned.contains("21") && cleaned.contains("30")) return 2;
        if (cleaned.contains("31 or more") || cleaned.contains("31+")) return 3;

        return 0;
    }

    private static int scoreYesNo(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();
        return cleaned.equals("yes") ? 1 : 0;
    }

    // Helper method for PHQ-9 and GAD-7 scoring
    private static int scoreStandardFrequency(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("not at all")) return 0;
        if (cleaned.contains("several days")) return 1;
        if (cleaned.contains("more than half")) return 2;
        if (cleaned.contains("nearly every day")) return 3;

        return 0;
    }

    // Helper method for QSU scoring
    private static int scoreQSUAnswer(String answer) {
        if (answer == null) return 1;

        try {
            int value = Integer.parseInt(answer.trim());
            return Math.max(1, Math.min(7, value));
        } catch (NumberFormatException e) {
            String cleaned = answer.toLowerCase().trim();

            if (cleaned.contains("strongly disagree")) return 1;
            if (cleaned.contains("disagree") && !cleaned.contains("strongly")) return 2;
            if (cleaned.contains("slightly disagree")) return 3;
            if (cleaned.contains("neither") || cleaned.contains("neutral")) return 4;
            if (cleaned.contains("slightly agree")) return 5;
            if (cleaned.contains("agree") && !cleaned.contains("strongly")) return 6;
            if (cleaned.contains("strongly agree")) return 7;

            return 1;
        }
    }

    // Helper methods for AUDIT scoring
    private static int scoreAUDITFrequency(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("never")) return 0;
        if (cleaned.contains("monthly or less") || cleaned.contains("less than monthly")) return 1;
        if (cleaned.contains("2 to 4") || cleaned.contains("2-4") ||
            (cleaned.contains("2") && cleaned.contains("4") && cleaned.contains("month"))) return 2;
        if (cleaned.equals("monthly")) return 2;
        if (cleaned.contains("2 to 3") || cleaned.contains("2-3") ||
            (cleaned.contains("2") && cleaned.contains("3") && cleaned.contains("week"))) return 3;
        if (cleaned.equals("weekly")) return 3;
        if (cleaned.contains("4 times") || cleaned.contains("4 or more") ||
            cleaned.contains("daily") || cleaned.contains("almost daily")) return 4;

        return 0;
    }

    private static int scoreAUDITQ2(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.contains("0 to 2") || cleaned.contains("0-2") ||
            cleaned.equals("1") || cleaned.equals("2")) return 0;
        if (cleaned.contains("3 to 4") || cleaned.contains("3-4") ||
            cleaned.equals("3") || cleaned.equals("4")) return 1;
        if (cleaned.contains("5 to 6") || cleaned.contains("5-6") ||
            cleaned.equals("5") || cleaned.equals("6")) return 2;
        if (cleaned.contains("7 to 9") || cleaned.contains("7-9") ||
            cleaned.equals("7") || cleaned.equals("8") || cleaned.equals("9")) return 3;
        if (cleaned.contains("10 or more") || cleaned.contains("10+")) return 4;

        try {
            int numUnits = Integer.parseInt(cleaned);
            if (numUnits <= 2) return 0;
            if (numUnits <= 4) return 1;
            if (numUnits <= 6) return 2;
            if (numUnits <= 9) return 3;
            return 4;
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static int scoreAUDITInjury(String answer) {
        if (answer == null) return 0;
        String cleaned = answer.toLowerCase().trim();

        if (cleaned.equals("no")) return 0;
        if (cleaned.contains("not in") && cleaned.contains("last year")) return 2;
        if (cleaned.contains("but not") && cleaned.contains("last year")) return 2;
        if (cleaned.contains("during") && cleaned.contains("last year")) return 4;
        if (cleaned.contains("in") && cleaned.contains("last year") &&
            !cleaned.contains("not in")) return 4;
        if (cleaned.equals("yes")) return 4;

        return 0;
    }

    // Helper method to get answer from JSON
    private static String getAnswerFromJson(JSONObject surveyData, String questionKey) {
        try {
            if (surveyData.containsKey(questionKey)) {
                return surveyData.get(questionKey).toString();
            }

            for (Object key : surveyData.keySet()) {
                if (key.toString().equalsIgnoreCase(questionKey)) {
                    return surveyData.get(key).toString();
                }
            }

            String[] keyWords = questionKey.toLowerCase().split(" ");
            for (Object key : surveyData.keySet()) {
                String lowerKey = key.toString().toLowerCase();
                boolean matches = true;
                for (String keyword : keyWords) {
                    if (keyword.length() > 3 && !lowerKey.contains(keyword)) {
                        matches = false;
                        break;
                    }
                }
                if (matches) {
                    return surveyData.get(key).toString();
                }
            }

            return null;
        } catch (Exception e) {
            return null;
        }
    }

    // Calculate FTND score
    private static int calculateFTNDScore(JSONObject surveyData) {
        int totalScore = 0;

        String q1 = getAnswerFromJson(surveyData, "How soon after you wake up do you smoke your first cigarette?");
        totalScore += scoreFTNDQ1(q1);

        String q2 = getAnswerFromJson(surveyData, "Do you find it difficult to refrain from smoking in places where it is forbidden, e.g., in church, at the library, cinema, etc?");
        totalScore += scoreYesNo(q2);

        String q3 = getAnswerFromJson(surveyData, "Which cigarette would you hate most to give up?");
        totalScore += scoreFTNDQ3(q3);

        String q4 = getAnswerFromJson(surveyData, "How many cigarettes/day do you smoke?");
        totalScore += scoreFTNDQ4(q4);

        String q5 = getAnswerFromJson(surveyData, "Do you smoke more frequently during the first hours of waking than during the rest of the day?");
        totalScore += scoreYesNo(q5);

        String q6 = getAnswerFromJson(surveyData, "Do you smoke if you are so ill that you are in bed most of the day?");
        totalScore += scoreYesNo(q6);

        return totalScore;
    }

    // Calculate PHQ-9 score
    private static int calculatePHQ9Score(JSONObject surveyData) {
        int totalScore = 0;

        String[] questions = {
            "Little interest or pleasure in doing things",
            "Feeling down, depressed, or hopeless",
            "Trouble falling or staying asleep, or sleeping too much",
            "Feeling tired or having little energy",
            "Poor appetite or overeating",
            "Feeling bad about yourself or that you are a failure or have let yourself or your family down",
            "Trouble concentrating on things, such as reading the newspaper or watching television",
            "Moving or speaking so slowly that other people could have noticed. Or the opposite being so figety or restless that you have been moving around a lot more than usual",
            "Thoughts that you would be better off dead, or of hurting yourself"
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scoreStandardFrequency(answer);
        }

        return totalScore;
    }

    // Calculate QSU score
    private static int calculateQSUScore(JSONObject surveyData) {
        int totalScore = 0;

        String[] questions = {
            "I have a desire for a cigarette right now.",
            "Nothing would be better than smoking a cigarette right now",
            "If it were possible, I probably would smoke now.",
            "I could control things better right now if I could smoke.",
            "All I want right now is a cigarette.",
            "I have an urge for a cigarette.",
            "A cigarette would taste good now.",
            "I would do almost anything for a cigarette now.",
            "Smoking would make me less depressed.",
            "I am going to smoke as soon as possible."
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scoreQSUAnswer(answer);
        }

        return totalScore;
    }

    // Calculate GAD-7 score
    private static int calculateGAD7Score(JSONObject surveyData) {
        int totalScore = 0;

        String[] questions = {
            "Feeling nervous, anxious, or on edge",
            "Not being able to stop or control worrying",
            "Worrying too much about different things",
            "Trouble relaxing",
            "Being so restless that it is hard to sit still",
            "Becoming easily annoyed or irritable",
            "Feeling afraid, as if something awful might happen"
        };

        for (String question : questions) {
            String answer = getAnswerFromJson(surveyData, question);
            totalScore += scoreStandardFrequency(answer);
        }

        return totalScore;
    }

    // Calculate AUDIT score
    private static int calculateAUDITScore(JSONObject surveyData) {
        int totalScore = 0;

        String q1 = getAnswerFromJson(surveyData, "How often do you have a drink containing alcohol?");
        totalScore += scoreAUDITFrequency(q1);

        String q2 = getAnswerFromJson(surveyData, "How many units of alcohol do you drink on a typical day when you are drinking?");
        totalScore += scoreAUDITQ2(q2);

        String q3 = getAnswerFromJson(surveyData, "How often have you had 6 or more units if female, or 8 or more if male, on a single occasion in the last year?");
        totalScore += scoreAUDITFrequency(q3);

        String q4 = getAnswerFromJson(surveyData, "How often during the last year have you found that you were not able to stop drinking once you had started?");
        totalScore += scoreAUDITFrequency(q4);

        String q5 = getAnswerFromJson(surveyData, "How often during the last year have you failed to do what was normally expected from you because of your drinking?");
        totalScore += scoreAUDITFrequency(q5);

        String q6 = getAnswerFromJson(surveyData, "How often during the last year have you needed an alcoholic drink in the morning to get yourself going after a heavy drinking session?");
        totalScore += scoreAUDITFrequency(q6);

        String q7 = getAnswerFromJson(surveyData, "How often during the last year have you had a feeling of guilt or remorse after drinking?");
        totalScore += scoreAUDITFrequency(q7);

        String q8 = getAnswerFromJson(surveyData, "How often during the last year have you been unable to remember what happened the night before because you had been drinking?");
        totalScore += scoreAUDITFrequency(q8);

        String q9 = getAnswerFromJson(surveyData, "Have you or somebody else been injured as a result of your drinking?");
        totalScore += scoreAUDITInjury(q9);

        String q10 = getAnswerFromJson(surveyData, "Has a relative or friend, doctor or other health worker been concerned about your drinking or suggested that you cut down?");
        totalScore += scoreAUDITInjury(q10);

        return totalScore;
    }

    // Get score interpretation
    private static String getScoreInterpretation(String formType, int score) {
        switch (formType) {
            case "FTND":
                if (score <= 2) return "Very low dependence";
                if (score <= 4) return "Low dependence";
                if (score == 5) return "Moderate dependence";
                if (score <= 7) return "High dependence";
                return "Very high dependence";

            case "PHQ9":
                if (score <= 4) return "Minimal depression";
                if (score <= 9) return "Mild depression";
                if (score <= 14) return "Moderate depression";
                if (score <= 19) return "Moderately severe depression";
                return "Severe depression";

            case "QSU":
                if (score <= 30) return "Low craving";
                if (score <= 50) return "Moderate craving";
                return "High craving";

            case "GAD7":
                if (score <= 4) return "Minimal anxiety";
                if (score <= 9) return "Mild anxiety";
                if (score <= 14) return "Moderate anxiety";
                return "Severe anxiety";

            case "AUDIT":
                if (score <= 7) return "Low risk";
                if (score <= 15) return "Increasing risk";
                if (score <= 19) return "Higher risk";
                return "Possible dependence";

            default:
                return "";
        }
    }

    // Get interpretation class (for styling)
    private static String getInterpretationClass(String formType, int score) {
        switch (formType) {
            case "FTND":
                if (score <= 4) return "low";
                if (score <= 6) return "moderate";
                return "high";

            case "PHQ9":
                if (score <= 9) return "low";
                if (score <= 14) return "moderate";
                return "high";

            case "QSU":
                if (score <= 30) return "low";
                if (score <= 50) return "moderate";
                return "high";

            case "GAD7":
                if (score <= 9) return "low";
                if (score <= 14) return "moderate";
                return "high";

            case "AUDIT":
                if (score <= 7) return "low";
                if (score <= 15) return "moderate";
                return "high";

            default:
                return "low";
        }
    }
%>

<%
try {
    cook cookx = new cook();
    String patid = cookx.getCookieValue("patid", request.getCookies());
    String utyp = cookx.getCookieValue("usertype", request.getCookies());

    rcDisplayData rd = new rcDisplayData(request.getRealPath("/"));
    Object res = rd.getTobaccoAssessmentData(patid);
    String innerHTML = "";
    StringBuilder modalsHtml = new StringBuilder();

    out.println("<div class='table-responsive'><table align='center' class='table table-bordered table-tobacco-assessment'><thead><tr align ='center'><td colspan=4>Assesment</td></tr><tr><th>DATE</th><th>TYPE</th><th>SCORE</th><th>ACTION</th></tr></thead><tbody>");

    if(res instanceof String){
        out.println("<tr><td colspan='4'>No Assesment data found</td></tr>");
    } else {
        Vector dataVec = (Vector)res;
        String s_id="";
        if(dataVec.size() > 0) {
            for(int i=0; i<dataVec.size(); i++){
                dataobj assessObj = (dataobj)dataVec.get(i);
                String surveyDatetime = assessObj.getValue("survey_datetime");
                String formattedDate = "";
                if(surveyDatetime != null && surveyDatetime.length() >= 19) {
                    formattedDate = surveyDatetime.substring(0, 10) + " " + surveyDatetime.substring(11, 19);
                } else {
                    formattedDate = surveyDatetime;
                }
                
                String rid = assessObj.getValue("rid");
                s_id = assessObj.getValue("sid");
                String surveyType = "";
                String score = "N/A";
                String interpretation = "";
                
                // Determine survey type based on sid
                if(s_id.equals("s12")) {
                    surveyType = "FTND";
                } else if(s_id.equals("s13")) {
                    surveyType = "QSU";
                } else if(s_id.equals("s14")) {
                    surveyType = "PHQ9";
                } else if(s_id.equals("s15")){
                    surveyType = "AUDIT";
                } else if(s_id.equals("s16")){
                    surveyType = "GAD7";
                }
                else {
                    surveyType = s_id;
                }
                
                String surveyData = assessObj.getValue("survey_data");
                
                if(surveyData != null && !surveyData.trim().isEmpty()) {
                    try {
                        JSONParser parser = new JSONParser();
                        JSONObject jsonData = (JSONObject) parser.parse(surveyData);

                        // Calculate score based on survey type
                        int calculatedScore = 0;
                        if(s_id.equals("s12")) {
                            calculatedScore = calculateFTNDScore(jsonData);
                        } else if(s_id.equals("s13")) {
                            calculatedScore = calculateQSUScore(jsonData);
                        } else if(s_id.equals("s14")) {
                            calculatedScore = calculatePHQ9Score(jsonData);
                        } else if(s_id.equals("s15")) {
                            calculatedScore = calculateAUDITScore(jsonData);
                        } else if(s_id.equals("s16")) {
                            calculatedScore = calculateGAD7Score(jsonData);
                        }

                        score = String.valueOf(calculatedScore);
                        interpretation = getScoreInterpretation(surveyType, calculatedScore);
                        String interpretationClass = getInterpretationClass(surveyType, calculatedScore);

                        // Create modal for this survey
                        modalsHtml.append("<div class='modal fade' id='modal-" + rid + "' tabindex='-1' role='dialog' aria-labelledby='surveyModalLabel-" + rid + "'>");
                        modalsHtml.append("<div class='modal-dialog modal-lg' role='document'>");
                        modalsHtml.append("<div class='modal-content'>");
                        modalsHtml.append("<div class='modal-header'>");
                        modalsHtml.append("<button type='button' class='close' data-dismiss='modal' aria-label='Close'><span aria-hidden='true'>&times;</span></button>");
                        modalsHtml.append("<h4 class='modal-title' id='surveyModalLabel-" + rid + "'>" + surveyType + " Assessment - " + formattedDate + "</h4>");
                        modalsHtml.append("</div>");
                        modalsHtml.append("<div class='modal-body'>");

                        // Add score summary at the top of the modal
                        modalsHtml.append("<div class='score-summary'>");
                        modalsHtml.append("<h5>Assessment Score</h5>");
                        modalsHtml.append("<div class='score-display'>");
                        modalsHtml.append("<span class='score-label'>Total Score:</span>");
                        modalsHtml.append("<span class='score-value'>" + score + "</span>");
                        modalsHtml.append("</div>");
                        modalsHtml.append("<div class='score-interpretation " + interpretationClass + "'>");
                        modalsHtml.append(interpretation);
                        modalsHtml.append("</div>");
                        modalsHtml.append("</div>");

                        modalsHtml.append("<table class='table table-striped table-bordered'>");
                        modalsHtml.append("<thead><tr><th width='70%'>Question</th><th width='30%'>Response</th></tr></thead>");
                        modalsHtml.append("<tbody>");
                        
                        // Display all questions and answers
                        for (Object key : jsonData.keySet()) {
                            String question = (String) key;
                            String answer = jsonData.get(key).toString();
                            
                            modalsHtml.append("<tr>");
                            modalsHtml.append("<td>" + question + "</td>");
                            modalsHtml.append("<td>" + answer + "</td>");
                            modalsHtml.append("</tr>");
                        }
                        
                        modalsHtml.append("</tbody>");
                        modalsHtml.append("</table>");
                        
                        modalsHtml.append("</div>");
                        modalsHtml.append("<div class='modal-footer'>");
                        modalsHtml.append("<button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
                        modalsHtml.append("</div>");
                        modalsHtml.append("</div>");
                        modalsHtml.append("</div>");
                        modalsHtml.append("</div>");
                        
                        // Add table row with view button
                        innerHTML += "<tr>";
                        innerHTML += "<td width='30%'>" + formattedDate + "</td>";
                        innerHTML += "<td width='25%'>" + surveyType + "</td>";
                        innerHTML += "<td width='15%'>" + score + "</td>";
                        innerHTML += "<td width='30%'><button type='button' class='view-btn' onclick=\"showSurveyDetails('" + rid + "')\">View Details</button></td>";
                        innerHTML += "</tr>";
                        
                    } catch (Exception e) {
                        innerHTML += "<tr>";
                        innerHTML += "<td>" + formattedDate + "</td>";
                        innerHTML += "<td>" + surveyType + "</td>";
                        innerHTML += "<td>N/A</td>";
                        innerHTML += "<td>Error parsing data: " + e.getMessage() + "</td>";
                        innerHTML += "</tr>";
                    }
                } else {
                    innerHTML += "<tr>";
                    innerHTML += "<td>" + formattedDate + "</td>";
                    innerHTML += "<td>" + surveyType + "</td>";
                    innerHTML += "<td>N/A</td>";
                    innerHTML += "<td>No data available</td>";
                    innerHTML += "</tr>";
                }
            }
        } else {
            innerHTML += "<tr><td colspan='4'>No Assesment data found</td></tr>";
        }
    }

    out.println(innerHTML+"</tbody></table></div>");
    
    // Chat Control Interface
    out.println("<div class='chat-control-interface'>");
    out.println("<div class='chat-control-header'>Chat Control Preferences</div>");
    out.println("<div class='text-center'>");
    out.println("<p style='margin-bottom: 15px; color: #6c757d;'>Manage and assign chat controls for patient communication</p>");
    out.println("<button type='button' class='chat-control-btn' onclick='showChatControlModal(); loadChatControls();'>Open Chat Controls</button>");
    out.println("</div>");
    out.println("</div>");

    // Simplified Chat History Interface
    out.println("<!-- Simplified Chat History Interface -->");
    out.println("<div class='chat-history-interface' style='margin-top: 30px;'>");
    out.println("    <div class='chat-history-header'>");
    out.println("        <i class='fa fa-comments'></i> Patient Chat History");
    out.println("    </div>");
    
    out.println("    <div class='tab-content' style='padding: 20px;'>");

    /* Patient memory block removed from the UI. */

    // Simple Controls
    out.println("        <div class='chat-history-controls' style='margin-bottom: 20px;'>");
    out.println("            <div class='row'>");
    out.println("                <div class='col-md-3'>");
    out.println("                    <label>From Date:</label>");
    out.println("                    <input type='date' id='chatFromDate' class='form-control'>");
    out.println("                </div>");
    out.println("                <div class='col-md-3'>");
    out.println("                    <label>To Date:</label>");
    out.println("                    <input type='date' id='chatToDate' class='form-control'>");
    out.println("                </div>");
    out.println("                <div class='col-md-3'>");
    out.println("                    <label>&nbsp;</label><br>");
    out.println("                    <button type='button' class='btn btn-primary btn-sm' onclick='loadChatHistory()'>");
    out.println("                        <i class='fa fa-search'></i> Load Chat History");
    out.println("                    </button>");
    out.println("                </div>");
    out.println("                <div class='col-md-3'>");
    out.println("                    <label>&nbsp;</label><br>");
    out.println("                    <button type='button' class='btn btn-info btn-sm' onclick='showQuickSummary()'>");
    out.println("                        <i class='fa fa-chart-bar'></i> Quick Summary");
    out.println("                    </button>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("        </div>");

    // Quick Summary Cards
    out.println("        <div class='row' style='margin-bottom: 20px;' id='summaryCards' style='display: none;'>");
    out.println("            <div class='col-md-3'>");
    out.println("                <div class='summary-card'>");
    out.println("                    <div class='summary-icon'><i class='fa fa-comments'></i></div>");
    out.println("                    <div class='summary-info'>");
    out.println("                        <span class='summary-number' id='totalSessions'>0</span>");
    out.println("                        <span class='summary-label'>Total Sessions</span>");
    out.println("                    </div>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("            <div class='col-md-3'>");
    out.println("                <div class='summary-card'>");
    out.println("                    <div class='summary-icon'><i class='fa fa-clock'></i></div>");
    out.println("                    <div class='summary-info'>");
    out.println("                        <span class='summary-number' id='totalDuration'>0m</span>");
    out.println("                        <span class='summary-label'>Total Duration</span>");
    out.println("                    </div>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("            <div class='col-md-3'>");
    out.println("                <div class='summary-card'>");
    out.println("                    <div class='summary-icon'><i class='fa fa-calendar'></i></div>");
    out.println("                    <div class='summary-info'>");
    out.println("                        <span class='summary-number' id='lastSession'>-</span>");
    out.println("                        <span class='summary-label'>Last Session</span>");
    out.println("                    </div>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("            <div class='col-md-3'>");
    out.println("                <div class='summary-card'>");
    out.println("                    <div class='summary-icon'><i class='fa fa-comment'></i></div>");
    out.println("                    <div class='summary-info'>");
    out.println("                        <span class='summary-number' id='totalMessages'>0</span>");
    out.println("                        <span class='summary-label'>Total Messages</span>");
    out.println("                    </div>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("        </div>");

    // Simple Chat Sessions Table
    out.println("        <div class='chat-sessions-container'>");
    out.println("            <div class='table-responsive'>");
    out.println("                <table class='table table-striped table-bordered' id='chatSessionsTable'>");
    out.println("                    <thead>");
    out.println("                        <tr style='background-color: #4197c2; color: white;'>");
    out.println("                            <th>Date</th>");
    out.println("                            <th>Start Time</th>");
    out.println("                            <th>End Time</th>");
    out.println("                            <th>Duration</th>");
    out.println("                            <th>Messages</th>");
    out.println("                            <th>Status</th>");
    out.println("                            <th>Actions</th>");
    out.println("                            <th>Session Summary</th>");
    out.println("                            <th>Delta Summary</th>");
    out.println("                            <th>Annotation Status</th>");
    out.println("                        </tr>");
    out.println("                    </thead>");
    out.println("                    <tbody id='chatSessionsTableBody'>");
    out.println("                        <tr>");
    out.println("                            <td colspan='9' class='text-center'>Click \"Load Chat History\" to view sessions</td>");
    out.println("                        </tr>");
    out.println("                    </tbody>");
    out.println("                </table>");
    out.println("            </div>");
    out.println("        </div>");
    out.println("    </div>");
    out.println("</div>");

    // Simple Chat Messages Modal
    out.println("<!-- Simple Chat Messages Modal -->");
    out.println("<div class='modal fade' id='chatMessagesModal' tabindex='-1' role='dialog'>");
    out.println("    <div class='modal-dialog modal-lg' role='document'>");
    out.println("        <div class='modal-content'>");
    out.println("            <div class='modal-header' style='background-color: #4197c2; color: white;'>");
    out.println("                <button type='button' class='close' data-dismiss='modal' style='color: white;'>");
    out.println("                    <span>&times;</span>");
    out.println("                </button>");
    out.println("                <h4 class='modal-title'>");
    out.println("                    <i class='fa fa-comments'></i> Chat Messages");
    out.println("                </h4>");
    out.println("            </div>");
    out.println("            <div class='modal-body'>");
    out.println("                <div id='chatSessionInfo' style='margin-bottom: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 5px;'></div>");
    out.println("                <div id='chatMessagesContainer' class='chat-messages-container'>");
    out.println("                    <div class='text-center'>");
    out.println("                        <i class='fa fa-spinner fa-spin'></i> Loading messages...");
    out.println("                    </div>");
    out.println("                </div>");
    out.println("            </div>");
    out.println("            <div class='modal-footer'>");
    out.println("                <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
    out.println("            </div>");
    out.println("        </div>");
    out.println("    </div>");
    out.println("</div>");
    
    // Session Annotation Modal (per-session view + editable summary)
    out.println("<div class='modal fade' id='sessionAnnotationModal' tabindex='-1' role='dialog'>");
    out.println("  <div class='modal-dialog modal-lg' role='document'>");
    out.println("    <div class='modal-content'>");
    out.println("      <div class='modal-header' style='background-color:#27ae60; color:white;'>");
    out.println("        <button type='button' class='close' data-dismiss='modal' style='color:white;'><span>&times;</span></button>");
    out.println("        <h4 class='modal-title'><i class='fa fa-file-alt'></i> Session Summary</h4>");
    out.println("      </div>");
    out.println("      <div class='modal-body' style='max-height:72vh; overflow-y:auto;'>");
    out.println("        <div id='sessionAnnotationContent'></div>");
    out.println("        <div id='manualSummaryBox' style='display:none; margin-top:18px; border-top:1px solid #dee2e6; padding-top:16px;'>");
    out.println("          <label style='font-weight:bold; font-size:14px;'>Write / Edit Summary:</label>");
    out.println("          <textarea id='manualSummaryText' class='form-control' rows='4' placeholder='Enter your clinical summary here...' style='resize:vertical; font-size:13px;'></textarea>");
    out.println("          <div id='saveFeedback'></div>");
    out.println("          <button id='saveSummaryBtn' type='button' class='btn btn-success btn-sm' style='margin-top:8px;' onclick='saveSessionSummary()'>");
    out.println("            <i class='fa fa-save'></i> Save Summary");
    out.println("          </button>");
    out.println("        </div>");
    out.println("      </div>");
    out.println("      <div class='modal-footer'>");
    out.println("        <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
    out.println("      </div>");
    out.println("    </div>");
    out.println("  </div>");
    out.println("</div>");

    // Delta Summary Modal
    out.println("<div class='modal fade' id='sessionDeltaModal' tabindex='-1' role='dialog'>");
    out.println("  <div class='modal-dialog modal-lg' role='document'>");
    out.println("    <div class='modal-content'>");
    out.println("      <div class='modal-header' style='background-color:#2980b9;color:white;'>");
    out.println("        <button type='button' class='close' data-dismiss='modal' style='color:white;'><span>&times;</span></button>");
    out.println("        <h4 class='modal-title'><i class='fa fa-exchange-alt'></i> Delta Summary</h4>");
    out.println("      </div>");
    out.println("      <div class='modal-body' style='max-height:72vh;overflow-y:auto;'>");
    out.println("        <div id='sessionDeltaContent'></div>");
    out.println("        <div id='deltaSummaryBox' style='display:none;margin-top:18px;border-top:1px solid #dee2e6;padding-top:16px;'>");
    out.println("          <label style='font-weight:bold;font-size:14px;'>Clinical Summary:</label>");
    out.println("          <textarea id='deltaSummaryText' class='form-control' rows='3' style='resize:vertical;font-size:13px;'></textarea>");
    out.println("          <div id='deltaFeedback'></div>");
    out.println("          <button id='saveDeltaBtn' type='button' class='btn btn-primary btn-sm' style='margin-top:8px;' onclick='saveDeltaSummary()'>");
    out.println("            <i class='fa fa-save'></i> Save");
    out.println("          </button>");
    out.println("        </div>");
    out.println("      </div>");
    out.println("      <div class='modal-footer'>");
    out.println("        <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
    out.println("      </div>");
    out.println("    </div>");
    out.println("  </div>");
    out.println("</div>");

    // Pipeline Run Thinking Modal
    out.println("<div class='modal fade' id='pipelineRunModal' tabindex='-1' role='dialog'>");
    out.println("  <div class='modal-dialog' style='width:92%;max-width:1080px;' role='document'>");
    out.println("    <div class='modal-content'>");
    out.println("      <div class='modal-header' style='background:#2c3e50;color:white;'>");
    out.println("        <button type='button' class='close' data-dismiss='modal' style='color:white;'><span>&times;</span></button>");
    out.println("        <h4 class='modal-title'><i class='fa fa-brain'></i> Annotation Thinking Report</h4>");
    out.println("      </div>");
    out.println("      <div class='modal-body' id='pipelineRunBody' style='max-height:82vh;overflow-y:auto;background:#f2f4f6;padding:20px;'></div>");
    out.println("      <div class='modal-footer'>");
    out.println("        <button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
    out.println("      </div>");
    out.println("    </div>");
    out.println("  </div>");
    out.println("</div>");

    // Chat Control Modal
    out.println("<div class='modal fade' id='chatControlModal' tabindex='-1' role='dialog' aria-labelledby='chatControlModalLabel'>");
    out.println("<div class='modal-dialog modal-lg' role='document'>");
    out.println("<div class='modal-content'>");
    out.println("<div class='modal-header' style='background-color: #4197c2; color: white;'>");
    out.println("<button type='button' class='close' data-dismiss='modal' aria-label='Close' style='color: white;'><span aria-hidden='true'>&times;</span></button>");
    out.println("<h4 class='modal-title' id='chatControlModalLabel'>Chat Control Management</h4>");
    out.println("</div>");
    out.println("<div class='modal-body'>");
    
    // Daily Chat Limit Section
    out.println("<div class='chat-control-section'>");
    out.println("<h5>Daily Chat Limit</h5>");
    out.println("<div class='control-item'>");
    out.println("<label>Maximum number of chat sessions per day:</label>");
    out.println("<input type='number' id='dailyChatLimit' min='1' max='50' value='3'>");
    out.println("<small class='form-text'>Default: 3 sessions per day (Range: 1-50)</small>");
    out.println("</div>");
    out.println("</div>");
    
    // Session Duration Settings Section
    out.println("<div class='chat-control-section'>");
    out.println("<h5>Session Duration Settings</h5>");
    out.println("<div class='control-item'>");
    out.println("<label>Maximum session duration (seconds):</label>");
    out.println("<input type='number' id='maxSessionDuration' min='300' max='7200' value='1800'>");
    out.println("<small class='form-text'>Default: 1800 seconds (30 minutes). Range: 300-7200 seconds</small>");
    out.println("</div>");
    
    out.println("<div class='control-item'>");
    out.println("<label>Minimum interval between sessions (seconds):</label>");
    out.println("<input type='number' id='minSessionInterval' min='300' value='3600'>");
    out.println("<small class='form-text'>Default: 3600 seconds (1 hour). Minimum: 300 seconds</small>");
    out.println("</div>");
    out.println("</div>");
    
    // Blackout Period Section
    out.println("<div class='chat-control-section'>");
    out.println("<h5>Blackout Period Settings</h5>");
    out.println("<div class='control-item'>");
    out.println("<label>Blackout start time:</label>");
    out.println("<input type='time' id='blackoutStartTime'>");
    out.println("<small class='form-text'>Time when chat should be disabled (optional)</small>");
    out.println("</div>");
    
    out.println("<div class='control-item'>");
    out.println("<label>Blackout end time:</label>");
    out.println("<input type='time' id='blackoutEndTime'>");
    out.println("<small class='form-text'>Time when chat should be re-enabled (optional)</small>");
    out.println("</div>");
    
    out.println("<div class='control-item'>");
    out.println("<label>Blackout days:</label>");
    out.println("<div class='row'>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Monday'> Monday</label></div>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Tuesday'> Tuesday</label></div>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Wednesday'> Wednesday</label></div>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Thursday'> Thursday</label></div>");
    out.println("</div>");
    out.println("<div class='row' style='margin-top: 10px;'>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Friday'> Friday</label></div>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Saturday'> Saturday</label></div>");
    out.println("<div class='col-md-3'><label class='checkbox-inline'><input type='checkbox' name='blackoutDays' value='Sunday'> Sunday</label></div>");
    out.println("</div>");
    out.println("<small class='form-text'>Select days when chat should be disabled (optional)</small>");
    out.println("</div>");
    out.println("</div>");

    // Chat Type Section
    out.println("<div class='chat-control-section'>");
    out.println("<h5>Chat Type</h5>");
    out.println("<div class='control-item'>");
    out.println("<label>Select chatbot type:</label>");
    out.println("<select id='chatType' class='form-control' style='width: auto; display: inline-block;'>");
    out.println("<option value='original'>Original</option>");
    //out.println("<option value='shehnawaz' disabled>Shehnawaz (coming soon)</option>");
    //out.println("<option value='nishnath' disabled>Nishnath (coming soon)</option>");
    out.println("<option value='srijit'>Chatbot with patient memory</option>");
    out.println("</select>");
    out.println("<small class='form-text'>Default: Original. Other types are not yet available.</small>");
    out.println("</div>");
    out.println("</div>");

    out.println("</div>");
    out.println("<div class='modal-footer'>");
    out.println("<button type='button' class='btn btn-default' data-dismiss='modal'>Close</button>");
    out.println("<button type='button' class='btn btn-warning' onclick='resetChatControls()'>Reset to Default</button>");
    out.println("<button type='button' class='btn btn-primary' id='saveChatControlsBtn' onclick='saveChatControls()'>Save Changes</button>");
    out.println("</div>");
    out.println("</div>");
    out.println("</div>");
    out.println("</div>");
    
    // Output existing survey modals
    out.println(modalsHtml.toString());
} catch(Exception e) {
    out.println("<div class='alert alert-danger'>Error: " + e.getMessage() + "</div>");
    e.printStackTrace(new java.io.PrintWriter(out));
}
%>

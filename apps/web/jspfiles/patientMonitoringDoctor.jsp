<%@page contentType="text/html" import="imedix.cook"%>
<%
  cook monitoringCook = new cook();
  String monitoringPatientId = request.getParameter("patId");
  if (monitoringPatientId == null || monitoringPatientId.trim().isEmpty()) monitoringPatientId = request.getParameter("id");
  if (monitoringPatientId == null || monitoringPatientId.trim().isEmpty()) monitoringPatientId = monitoringCook.getCookieValue("patid", request.getCookies());
  if (monitoringPatientId == null) monitoringPatientId = "";
  String monitoringPatientIdHtml = monitoringPatientId.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;");
%>
<link rel="stylesheet" href="<%=request.getContextPath()%>/style/patient-monitoring.css">
<script src="<%=request.getContextPath()%>/includes/patient-monitoring-api.js"></script>
<div class="patient-monitoring" data-patient-id="<%=monitoringPatientIdHtml%>">
  <div class="monitoring-header">
    <h2>Patient Monitoring</h2>
    <p class="text-muted">Review patient-provided monitoring information and record clinical updates.</p>
    <p class="monitoring-patient-context"><strong>Patient ID:</strong> <span><%=monitoringPatientIdHtml%></span></p>
    <p><button type="button" class="btn btn-default" onclick="return showMonitoringPatientList();">Back to patient list</button></p>
  </div>
  <div id="doctor-monitoring-message" class="alert" role="status" aria-live="polite" style="display:none"></div>
  <div class="row">
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="distress-heading">
        <div class="panel-heading"><h3 id="distress-heading" class="panel-title">Distress Status</h3></div>
        <div class="panel-body" id="distress-status-panel"><div class="monitoring-loading">Loading monitoring data...</div></div>
      </section>
    </div>
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="summary-heading">
        <div class="panel-heading"><h3 id="summary-heading" class="panel-title">Patient Summary</h3></div>
        <div class="panel-body" id="patient-summary-panel"><div class="monitoring-loading">Loading monitoring data...</div></div>
      </section>
    </div>
  </div>
  <div class="row">
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="therapy-heading">
        <div class="panel-heading"><h3 id="therapy-heading" class="panel-title">Therapy Change</h3></div>
        <div class="panel-body">
          <p><strong>Current therapy:</strong> <span id="current-therapy">Not available</span></p>
          <form id="therapy-change-form" novalidate>
            <div class="form-group"><label for="previous-therapy">Previous therapy</label><input class="form-control" id="previous-therapy" name="previousTherapy" maxlength="200"></div>
            <div class="form-group"><label for="new-therapy">New therapy <span aria-hidden="true">*</span></label><input class="form-control" id="new-therapy" name="newTherapy" maxlength="200" required aria-describedby="new-therapy-error"><span id="new-therapy-error" class="help-block" role="alert"></span></div>
            <div class="form-group"><label for="therapy-reason">Reason / remarks</label><textarea class="form-control" id="therapy-reason" name="reason" rows="3" maxlength="1000"></textarea></div>
            <div class="form-group"><label for="therapy-date">Date of change <span aria-hidden="true">*</span></label><input class="form-control" type="date" id="therapy-date" name="dateOfChange" required aria-describedby="therapy-date-error"><span id="therapy-date-error" class="help-block" role="alert"></span></div>
            <button type="submit" class="btn btn-primary">Save Therapy Change</button>
            <button type="reset" class="btn btn-default">Cancel</button>
          </form>
          <div id="therapy-history-panel" class="monitoring-history"><div class="monitoring-loading">Loading monitoring data...</div></div>
        </div>
      </section>
    </div>
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="metastasis-heading">
        <div class="panel-heading"><h3 id="metastasis-heading" class="panel-title">Metastasis State</h3></div>
        <div class="panel-body">
          <p><strong>Current metastasis state</strong></p>
          <form id="metastasis-form" novalidate>
            <div class="form-group"><label for="metastasis-state">Metastasis state</label><textarea class="form-control" id="metastasis-state" name="state" rows="5" maxlength="3000" placeholder="Enter the current metastasis-related clinical information..." required aria-describedby="metastasis-error"></textarea><span id="metastasis-error" class="help-block" role="alert"></span></div>
            <button type="submit" class="btn btn-primary">Save Metastasis State</button>
          </form>
          <div id="metastasis-history-panel" class="monitoring-history"><div class="monitoring-loading">Loading monitoring data...</div></div>
        </div>
      </section>
    </div>
  </div>
  <section id="distress-action-section" class="panel monitoring-card monitoring-alert" aria-labelledby="action-heading" style="display:none">
    <div class="panel-heading"><h3 id="action-heading" class="panel-title">Clinical Action</h3></div>
    <div class="panel-body">
      <p><strong>High distress has been identified. A physical/in-person meeting is recommended for clinical consideration.</strong></p>
      <form id="distress-action-form" novalidate>
        <div class="form-group"><label for="distress-action">Action</label><select class="form-control" id="distress-action" required><option value="">Select an action</option><option>Physical meeting recommended</option><option>Physical meeting scheduled</option><option>Follow-up required</option><option>Reviewed by doctor</option></select></div>
        <div class="form-group"><label for="distress-remarks">Remarks (optional)</label><textarea class="form-control" id="distress-remarks" rows="3" maxlength="1000"></textarea></div>
        <button type="submit" class="btn btn-primary">Save Action</button>
      </form>
    </div>
  </section>
</div>
<script>
function showMonitoringPatientList() {
  var loading = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='Loading monitoring patients...'>";
  $("#main_frame").html(loading).load("patientMonitoringDoctorList.jsp");
  $("#main_frame").css("min-height", "100%");
  return false;
}
</script>
<script type="text/plain">
(function ($) {
  'use strict';
  var root = $('.patient-monitoring').last();
  var patientId = root.data('patient-id');
  var service = window.MDosthiMonitoringService;
  function message(text, type) { var el = $('#doctor-monitoring-message'); el.removeClass('alert-success alert-danger').addClass('alert-' + type).text(text).show(); }
  function unavailable(panel) { $(panel).html('<div class="monitoring-error">Unable to load monitoring data. Please try again.</div>'); }
  function escapeHtml(value) { return $('<div>').text(value == null ? '' : value).html(); }
  function renderHistory(panel, rows, columns, emptyText) {
    if (!rows || !rows.length) { $(panel).html('<div class="monitoring-empty">' + emptyText + '</div>'); return; }
    var html = '<div class="table-responsive"><table class="table table-striped monitoring-history"><thead><tr>' + columns.map(function (column) { return '<th>' + column.label + '</th>'; }).join('') + '</tr></thead><tbody>';
    rows.forEach(function (row) { html += '<tr>' + columns.map(function (column) { return '<td>' + escapeHtml(row[column.key]) + '</td>'; }).join('') + '</tr>'; });
    $(panel).html(html + '</tbody></table></div>');
  }
  function load() {
    if (!patientId) { message('Select a patient before opening Patient Monitoring.', 'warning'); return; }
    service.getPatientMonitoring(patientId).done(function (data) { $('#patient-summary-panel').html(data && data.summary ? '<p>' + escapeHtml(data.summary) + '</p>' : '<div class="monitoring-empty">No records available yet.</div>'); $('#current-therapy').text(data && data.currentTherapy ? data.currentTherapy : 'Not available'); if (data && data.distress) { $('#distress-status-panel').html('<p><span class="monitoring-status ' + (data.distress.status === 'High' ? 'high' : '') + '">' + escapeHtml(data.distress.status) + '</span></p><p>Score: ' + escapeHtml(data.distress.score) + '</p><p>Assessment date: ' + escapeHtml(data.distress.assessmentDate) + '</p>'); if (data.distress.physicalMeetingRecommended) $('#distress-action-section').show(); } else { $('#distress-status-panel').html('<div class="monitoring-empty">No records available yet.</div>'); } }).fail(function () { unavailable('#patient-summary-panel'); unavailable('#distress-status-panel'); });
    service.getTherapyHistory(patientId).done(function (data) { renderHistory('#therapy-history-panel', data && data.records, [{key:'dateOfChange',label:'Date'},{key:'previousTherapy',label:'Previous therapy'},{key:'newTherapy',label:'New therapy'},{key:'reason',label:'Reason'}], 'No therapy changes have been recorded.'); }).fail(function () { unavailable('#therapy-history-panel'); });
    service.getMetastasisHistory(patientId).done(function (data) { renderHistory('#metastasis-history-panel', data && data.records, [{key:'recordedAt',label:'Date'},{key:'state',label:'State'}], 'No records available yet.'); }).fail(function () { unavailable('#metastasis-history-panel'); });
  }
  $('#therapy-change-form').on('submit', function (event) { event.preventDefault(); var form = this; $('#new-therapy-error,#therapy-date-error').text(''); if (!form.newTherapy.value.trim()) { $('#new-therapy-error').text('New therapy is required.'); return; } if (!form.dateOfChange.value) { $('#therapy-date-error').text('Date of change is required.'); return; } service.createTherapyChange(patientId, { previousTherapy: form.previousTherapy.value, newTherapy: form.newTherapy.value, reason: form.reason.value, dateOfChange: form.dateOfChange.value }).done(function () { message('Information saved successfully.', 'success'); form.reset(); load(); }).fail(function () { message('Unable to save monitoring data. Please try again.', 'danger'); }); });
  $('#metastasis-form').on('submit', function (event) { event.preventDefault(); var form = this; $('#metastasis-error').text(''); if (!form.state.value.trim()) { $('#metastasis-error').text('Metastasis state is required.'); return; } service.createMetastasisState(patientId, { state: form.state.value }).done(function () { message('Information saved successfully.', 'success'); form.reset(); load(); }).fail(function () { message('Unable to save monitoring data. Please try again.', 'danger'); }); });
  $('#distress-action-form').on('submit', function (event) { event.preventDefault(); if (!this.action.value) return; service.recordDistressAction(patientId, { action: this.action.value, remarks: this.remarks.value }).done(function () { message('Information saved successfully.', 'success'); }).fail(function () { message('Unable to save monitoring data. Please try again.', 'danger'); }); });
  load();
}(jQuery));
</script>
<script src="<%=request.getContextPath()%>/includes/patient-monitoring-doctor.js"></script>
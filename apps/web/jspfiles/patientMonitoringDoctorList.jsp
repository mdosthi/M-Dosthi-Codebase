<%@page contentType="text/html" import="imedix.projinfo,imedix.rcPatqueueInfo,imedix.rcUserInfo,imedix.rcGenOperations,imedix.dataobj,imedix.cook,java.util.*,java.net.URLEncoder"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
  cook monitoringCook = new cook();
  String monitoringUserType = monitoringCook.getCookieValue("usertype", request.getCookies());
  String monitoringUserId = monitoringCook.getCookieValue("userid", request.getCookies());
  String monitoringPatientRows = "";
  String monitoringError = "";

  if (!"doc".equalsIgnoreCase(monitoringUserType)) {
    monitoringError = "Patient Monitoring is available for doctor accounts only.";
  } else {
    try {
      projinfo monitoringProject = new projinfo(request.getRealPath("/"));
      rcUserInfo monitoringUserInfo = new rcUserInfo(request.getRealPath("/"));
      rcPatqueueInfo monitoringQueue = new rcPatqueueInfo(request.getRealPath("/"));
      rcGenOperations monitoringOperations = new rcGenOperations(request.getRealPath("/"));
      String monitoringDoctorRegistration = monitoringUserInfo.getreg_no(monitoringUserId);
      int monitoringPageSize = Integer.parseInt(monitoringProject.gblPageRow);
      Object monitoringResult = monitoringQueue.getLPatqueueDoc(monitoringDoctorRegistration, 0, monitoringPageSize);

      if (monitoringResult instanceof Vector) {
        Vector monitoringPatients = (Vector) monitoringResult;
        for (int i = 0; i < monitoringPatients.size(); i++) {
          dataobj monitoringPatient = (dataobj) monitoringPatients.get(i);
          String patientId = monitoringPatient.getValue("pat_id");
          String patientName = monitoringOperations.getPatientName(patientId);
          String appointmentDate = monitoringPatient.getValue("appdate");
          String registrationDate = monitoringPatient.getValue("entrydate");
          monitoringPatientRows += "<tr>";
          monitoringPatientRows += "<td><a class='monitoring-patient-link' href='patientMonitoringDoctor.jsp?patId=" + URLEncoder.encode(patientId, "UTF-8") + "' onclick=\"return openMonitoringDetails('" + escapeMonitoringValue(patientId) + "');\">" + escapeMonitoringValue(patientName) + "</a></td>";
          monitoringPatientRows += "<td><a class='monitoring-patient-link' href='patientMonitoringDoctor.jsp?patId=" + URLEncoder.encode(patientId, "UTF-8") + "' onclick=\"return openMonitoringDetails('" + escapeMonitoringValue(patientId) + "');\">" + escapeMonitoringValue(patientId) + "</a></td>";
          monitoringPatientRows += "<td>" + escapeMonitoringValue(appointmentDate) + "</td>";
          monitoringPatientRows += "<td>" + escapeMonitoringDate(registrationDate) + "</td>";
          monitoringPatientRows += "</tr>";
        }
      }
    } catch (Exception monitoringException) {
      monitoringError = "Unable to load monitoring patients. Please try again.";
    }
  }
%>
<%!
  private String escapeMonitoringValue(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }

  private String escapeMonitoringDate(String value) {
    if (value == null || value.length() < 10) return escapeMonitoringValue(value);
    return escapeMonitoringValue(value.substring(0, 10).replace('-', '/'));
  }

%>
<link rel="stylesheet" href="<%=request.getContextPath()%>/style/patient-monitoring.css">
<div class="patient-monitoring">
  <div class="monitoring-header">
    <h2>Patient Monitoring</h2>
    <p class="text-muted">Select a patient to review monitoring details.</p>
    <div class="monitoring-list-summary">
      <span class="monitoring-summary-label">Assigned patients</span>
      <strong id="monitoring-patient-count"><%=monitoringPatientRows.isEmpty() ? "0" : ""%></strong>
    </div>
  </div>
  <% if (!monitoringError.isEmpty()) { %>
    <div class="monitoring-error" role="alert"><%=monitoringError%></div>
  <% } else if (monitoringPatientRows.isEmpty()) { %>
    <div class="monitoring-empty">No assigned patients are available yet.</div>
  <% } else { %>
    <div class="panel monitoring-card">
      <div class="panel-heading monitoring-list-heading">
        <div>
          <h3 class="panel-title">Assigned Patients</h3>
          <p>Choose a patient to review distress, therapy, and metastasis information.</p>
        </div>
        <label class="monitoring-search">
          <span class="sr-only">Search assigned patients</span>
          <span class="glyphicon glyphicon-search" aria-hidden="true"></span>
          <input type="search" id="monitoring-patient-search" placeholder="Search name or patient ID" autocomplete="off">
        </label>
      </div>
      <div class="panel-body">
        <div class="table-responsive">
          <table class="table table-striped monitoring-patient-table">
            <thead>
              <tr><th>Patient Name</th><th>Patient ID</th><th>Appointment Date</th><th>Registration Date</th><th>Action</th></tr>
            </thead>
            <tbody><%=monitoringPatientRows%></tbody>
          </table>
          <div id="monitoring-no-results" class="monitoring-empty" style="display:none">No matching patients found.</div>
        </div>
      </div>
    </div>
  <% } %>
</div>
<script>
function openMonitoringDetails(patientId) {
  var loading = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='Loading patient monitoring details...'>";
  $("#main_frame").html(loading).load("patientMonitoringDoctor.jsp?patId=" + encodeURIComponent(patientId));
  $("#main_frame").css("min-height", "100%");
  return false;
}

$(function () {
  var search = $("#monitoring-patient-search");
  var rows = $(".monitoring-patient-table tbody tr");
  var count = $("#monitoring-patient-count");

  rows.each(function () {
    var patientId = $(this).find("td:eq(1)").text();
    $(this).append("<td><a class='btn btn-primary monitoring-open-button' href='patientMonitoringDoctor.jsp?patId=" + encodeURIComponent(patientId) + "' onclick=\"return openMonitoringDetails('" + patientId + "');\"><span class='glyphicon glyphicon-stats' aria-hidden='true'></span> Open monitoring</a></td>");
  });

  function filterPatients() {
    var query = search.val().toLowerCase().trim();
    var visible = 0;
    rows.each(function () {
      var matches = $(this).text().toLowerCase().indexOf(query) !== -1;
      $(this).toggle(matches);
      if (matches) visible += 1;
    });
    count.text(visible);
    $("#monitoring-no-results").toggle(visible === 0);
  }

  count.text(rows.length);
  search.on("input", filterPatients);
});
</script>

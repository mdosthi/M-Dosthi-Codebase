<%@page contentType="text/html" import="imedix.projinfo,imedix.rcPatqueueInfo,imedix.rcUserInfo,imedix.rcGenOperations,imedix.dataobj,imedix.cook,java.util.*,java.net.URLEncoder"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
  cook monitoringCook = new cook();
  String monitoringUserType = monitoringCook.getCookieValue("usertype", request.getCookies());
  String monitoringUserId = monitoringCook.getCookieValue("userid", request.getCookies());
  String monitoringPatientRows = "";
  String monitoringError = "";

  boolean monitoringPsychologist = "psy".equalsIgnoreCase(monitoringUserType);
  String monitoringSearch = request.getParameter("search");
  monitoringSearch = monitoringSearch == null ? "" : monitoringSearch.trim();

  if (monitoringPsychologist) {
    java.sql.Connection monitoringConnection = null;
    java.sql.PreparedStatement monitoringStatement = null;
    java.sql.ResultSet monitoringRows = null;
    try {
      String monitoringUrl = monitoringDbValue("gbldburl", "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
      Class.forName(monitoringDbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request));
      monitoringConnection = java.sql.DriverManager.getConnection(monitoringUrl + (monitoringUrl.contains("?") ? "&" : "?") + "useSSL=false",
          monitoringDbValue("gbldbusername", "root", request), monitoringDbValue("gbldbpasswd", "", request));
      String monitoringSql = "SELECT m.pat_id, m.pat_name, m.m_name, m.l_name, m.entrydate, MAX(l.appdate) AS appointment_date " +
          "FROM med m LEFT JOIN lpatq l ON l.pat_id=m.pat_id" +
          (monitoringSearch.isEmpty() ? "" : " WHERE (m.pat_id LIKE ? OR CONCAT_WS(' ', m.pat_name, m.m_name, m.l_name) LIKE ?)") +
          " GROUP BY m.pat_id, m.pat_name, m.m_name, m.l_name, m.entrydate ORDER BY m.entrydate DESC, m.pat_id LIMIT 200";
      monitoringStatement = monitoringConnection.prepareStatement(monitoringSql);
      if (!monitoringSearch.isEmpty()) {
        monitoringStatement.setString(1, "%" + monitoringSearch + "%");
        monitoringStatement.setString(2, "%" + monitoringSearch + "%");
      }
      monitoringRows = monitoringStatement.executeQuery();
      while (monitoringRows.next()) {
        String patientId = monitoringRows.getString("pat_id");
        StringBuilder patientNameBuilder = new StringBuilder();
        String[] nameParts = {monitoringRows.getString("pat_name"), monitoringRows.getString("m_name"), monitoringRows.getString("l_name")};
        for (String part : nameParts) if (part != null && !part.trim().isEmpty()) {
          if (patientNameBuilder.length() > 0) patientNameBuilder.append(' ');
          patientNameBuilder.append(part.trim());
        }
        String patientName = patientNameBuilder.toString().replaceFirst("^\\s*\\d+\\s*", "");
        String appointmentDate = monitoringRows.getString("appointment_date");
        String registrationDate = monitoringRows.getString("entrydate");
        monitoringPatientRows += "<tr>";
        monitoringPatientRows += "<td><a class='monitoring-patient-link' href='patientMonitoringDoctor.jsp?patId=" + URLEncoder.encode(patientId, "UTF-8") + "' onclick=\"return openMonitoringDetails('" + escapeMonitoringValue(patientId) + "');\">" + escapeMonitoringValue(patientName) + "</a></td>";
        monitoringPatientRows += "<td><a class='monitoring-patient-link' href='patientMonitoringDoctor.jsp?patId=" + URLEncoder.encode(patientId, "UTF-8") + "' onclick=\"return openMonitoringDetails('" + escapeMonitoringValue(patientId) + "');\">" + escapeMonitoringValue(patientId) + "</a></td>";
        monitoringPatientRows += "<td>" + escapeMonitoringDate(appointmentDate) + "</td>";
        monitoringPatientRows += "<td>" + escapeMonitoringDate(registrationDate) + "</td>";
        monitoringPatientRows += "</tr>";
      }
    } catch (Exception monitoringException) {
      application.log("Unable to load monitoring patients.", monitoringException);
      monitoringError = "Unable to load monitoring patients. Please try again.";
    } finally {
      if (monitoringRows != null) try { monitoringRows.close(); } catch (Exception ignored) { }
      if (monitoringStatement != null) try { monitoringStatement.close(); } catch (Exception ignored) { }
      if (monitoringConnection != null) try { monitoringConnection.close(); } catch (Exception ignored) { }
    }
  } else if (!"doc".equalsIgnoreCase(monitoringUserType)) {
    monitoringError = "Patient Monitoring is available for doctor and psychologist accounts only.";
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
  private String monitoringDbValue(String key, String defaultValue, HttpServletRequest request) {
    java.io.BufferedReader reader = null;
    try {
      java.io.File webRoot = new java.io.File(request.getRealPath("/"));
      java.io.File config = new java.io.File(webRoot.getParentFile().getParentFile(), "services/legacy/runtime/gblinfo.inf");
      if (!config.exists()) return defaultValue;
      reader = new java.io.BufferedReader(new java.io.FileReader(config));
      String line;
      while ((line = reader.readLine()) != null) {
        int separator = line.indexOf('=');
        if (separator > 0 && key.equalsIgnoreCase(line.substring(0, separator).trim())) return line.substring(separator + 1).trim();
      }
    } catch (Exception ignored) {
    } finally {
      if (reader != null) try { reader.close(); } catch (java.io.IOException ignored) { }
    }
    return defaultValue;
  }

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
    <p class="text-muted"><%=monitoringPsychologist ? "Select a patient to review monitoring details. Showing up to 200 patients; use search to narrow the list." : "Select a patient to review monitoring details."%></p>
    <div class="monitoring-list-summary">
      <span class="monitoring-summary-label"><%=monitoringPsychologist ? "Patients" : "Assigned patients"%></span>
      <strong id="monitoring-patient-count"><%=monitoringPatientRows.isEmpty() ? "0" : ""%></strong>
    </div>
  </div>
  <% if (!monitoringError.isEmpty()) { %>
    <div class="monitoring-error" role="alert"><%=monitoringError%></div>
  <% } else if (monitoringPatientRows.isEmpty() && monitoringSearch.isEmpty()) { %>
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
  if (rows.length === 0) $("#monitoring-no-results").show();
  search.on("input", filterPatients);
  <% if (monitoringPsychologist) { %>
  search.val("<%=escapeMonitoringValue(monitoringSearch)%>");
  search.on("keydown", function (event) {
    if (event.which !== 13) return;
    event.preventDefault();
    var loading = "<img class='loading' src='<%=request.getContextPath()%>/images/loading.gif' alt='Searching patients...'>";
    $("#main_frame").html(loading).load("patientMonitoringDoctorList.jsp?search=" + encodeURIComponent(search.val().trim()));
  });
  <% } %>
});
</script>

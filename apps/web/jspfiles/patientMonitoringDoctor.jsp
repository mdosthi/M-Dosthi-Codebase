<%@page contentType="text/html" pageEncoding="UTF-8" import="imedix.cook,java.io.*,java.net.URLEncoder,java.sql.*,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
  private String monitoringHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }

  private String monitoringDbValue(String key, String defaultValue, HttpServletRequest request) {
    BufferedReader reader = null;
    try {
      File webRoot = new File(request.getRealPath("/"));
      File config = new File(webRoot.getParentFile().getParentFile(), "services/legacy/runtime/gblinfo.inf");
      if (!config.exists()) return defaultValue;
      reader = new BufferedReader(new FileReader(config));
      String line;
      while ((line = reader.readLine()) != null) {
        int separator = line.indexOf('=');
        if (separator > 0 && key.equalsIgnoreCase(line.substring(0, separator).trim())) return line.substring(separator + 1).trim();
      }
    } catch (Exception ignored) {
    } finally {
      if (reader != null) try { reader.close(); } catch (IOException ignored) { }
    }
    return defaultValue;
  }
%>
<%
  cook monitoringCook = new cook();
  String monitoringRole = monitoringCook.getCookieValue("usertype", request.getCookies());
  String monitoringUserId = monitoringCook.getCookieValue("userid", request.getCookies());
  boolean monitoringIsDoctor = "doc".equalsIgnoreCase(monitoringRole);
  boolean monitoringIsPsychologist = "psy".equalsIgnoreCase(monitoringRole);

  String monitoringPatientId = request.getParameter("patId");
  if (monitoringPatientId == null || monitoringPatientId.trim().isEmpty()) monitoringPatientId = request.getParameter("id");
  if (monitoringPatientId == null || monitoringPatientId.trim().isEmpty()) monitoringPatientId = monitoringCook.getCookieValue("patid", request.getCookies());
  monitoringPatientId = monitoringPatientId == null ? "" : monitoringPatientId.trim();

  String monitoringError = null;
  Map<String, String> profile = new LinkedHashMap<String, String>();
  String distressStatus = "Not assessed";
  String distressMessage = "No distress assessment is available for this patient.";
  boolean distressHigh = false;
  Map<String, List<String>> problemList = new LinkedHashMap<String, List<String>>();
  List<String[]> screenings = new ArrayList<String[]>();
  Map<String, Map<String, List<String>>> concernsByScreening = new HashMap<String, Map<String, List<String>>>();
  List<String[]> actions = new ArrayList<String[]>();
  int distressScore = -1, therapyCount = 0, metastasisCount = 0;

  if (!monitoringIsDoctor && !monitoringIsPsychologist) {
    monitoringError = "Patient Monitoring is available for doctor and psychologist accounts only.";
  } else if (monitoringPatientId.isEmpty()) {
    monitoringError = "Select a patient before opening Patient Monitoring.";
  } else {
    Connection connection = null;
    PreparedStatement statement = null;
    ResultSet result = null;
    try {
      String url = monitoringDbValue("gbldburl", "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
      Class.forName(monitoringDbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request));
      connection = DriverManager.getConnection(url + (url.contains("?") ? "&" : "?") + "useSSL=false",
          monitoringDbValue("gbldbusername", "root", request), monitoringDbValue("gbldbpasswd", "", request));

      statement = connection.prepareStatement("SELECT pat_name, m_name, l_name, sex, dateofbirth, entrydate, phone FROM med WHERE pat_id=?");
      statement.setString(1, monitoringPatientId);
      result = statement.executeQuery();
      if (!result.next()) {
        monitoringError = "Patient not found.";
      } else {
        StringBuilder name = new StringBuilder();
        String[] nameParts = {result.getString("pat_name"), result.getString("m_name"), result.getString("l_name")};
        for (String part : nameParts) if (part != null && !part.trim().isEmpty()) {
          if (name.length() > 0) name.append(' ');
          name.append(part.trim());
        }
        profile.put("Name", name.toString().replaceFirst("^\\s*\\d+\\s*", ""));
        profile.put("Patient ID", monitoringPatientId);
        profile.put("Gender", result.getString("sex"));
        String dob = result.getString("dateofbirth");
        profile.put("Date of birth", dob);
        try {
          java.time.LocalDate born = java.time.LocalDate.parse(dob.substring(0, 10));
          profile.put("Age", String.valueOf(java.time.Period.between(born, java.time.LocalDate.now()).getYears()) + " years");
        } catch (Exception ignoredAge) { }
        profile.put("Phone", result.getString("phone"));
        String registered = result.getString("entrydate");
        profile.put("Registered", registered != null && registered.length() >= 10 ? registered.substring(0, 10) : registered);
      }
      result.close();
      statement.close();
      result = null;
      statement = null;

      if (monitoringError == null && monitoringIsDoctor) {
        statement = connection.prepareStatement("SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) " +
            "WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'");
        statement.setString(1, monitoringPatientId);
        statement.setString(2, monitoringUserId == null ? "" : monitoringUserId);
        result = statement.executeQuery();
        if (!result.next() || result.getInt(1) == 0) monitoringError = "You are not assigned to this patient.";
        result.close();
        statement.close();
        result = null;
        statement = null;
      }

      if (monitoringError == null) {
        statement = connection.prepareStatement("SELECT MAX(appdate) FROM lpatq WHERE pat_id=?");
        statement.setString(1, monitoringPatientId);
        result = statement.executeQuery();
        if (result.next()) {
          String appointment = result.getString(1);
          profile.put("Appointment", appointment != null && appointment.length() >= 10 ? appointment.substring(0, 10) : appointment);
        }
        result.close();
        statement.close();

        statement = connection.prepareStatement("SELECT id, distress_score, screening_date, assessment_checkpoint FROM distress_thermometer WHERE pat_id=? ORDER BY screening_date DESC, id DESC LIMIT 20");
        statement.setString(1, monitoringPatientId);
        result = statement.executeQuery();
        while (result.next()) {
          screenings.add(new String[] {String.valueOf(result.getLong("id")), String.valueOf(result.getInt("distress_score")), result.getString("screening_date"), result.getString("assessment_checkpoint")});
        }
        result.close();
        statement.close();

        statement = connection.prepareStatement("SELECT p.screening_id, p.category, p.concern FROM distress_thermometer_problem p JOIN distress_thermometer d ON d.id=p.screening_id WHERE d.pat_id=? ORDER BY p.id");
        statement.setString(1, monitoringPatientId);
        result = statement.executeQuery();
        while (result.next()) {
          String screeningKey = String.valueOf(result.getLong("screening_id"));
          Map<String, List<String>> groups = concernsByScreening.get(screeningKey);
          if (groups == null) { groups = new LinkedHashMap<String, List<String>>(); concernsByScreening.put(screeningKey, groups); }
          String category = result.getString("category");
          List<String> concerns = groups.get(category);
          if (concerns == null) { concerns = new ArrayList<String>(); groups.put(category, concerns); }
          concerns.add(result.getString("concern"));
        }
        result.close();
        statement.close();

        if (!screenings.isEmpty()) {
          String[] latest = screenings.get(0);
          int score = Integer.parseInt(latest[1]);
          distressScore = score;
          distressHigh = score > 4;
          distressStatus = distressHigh ? "High" : "Low";
          distressMessage = "Latest Distress Thermometer score: " + score + "/10 (screening date " + latest[2] + ").";
          Map<String, List<String>> latestGroups = concernsByScreening.get(latest[0]);
          if (latestGroups != null) problemList.putAll(latestGroups);
        }

        statement = connection.prepareStatement("SELECT action, remarks, recorded_by, recorded_at FROM patient_distress_action WHERE pat_id=? ORDER BY id DESC LIMIT 20");
        statement.setString(1, monitoringPatientId);
        result = statement.executeQuery();
        while (result.next()) {
          actions.add(new String[] {result.getString("action"), result.getString("remarks"), result.getString("recorded_by"), result.getString("recorded_at")});
        }
        result.close();
        statement.close();

        statement = connection.prepareStatement("SELECT (SELECT COUNT(*) FROM patient_therapy_change WHERE pat_id=?), (SELECT COUNT(*) FROM patient_metastasis_state WHERE pat_id=?)");
        statement.setString(1, monitoringPatientId);
        statement.setString(2, monitoringPatientId);
        result = statement.executeQuery();
        if (result.next()) { therapyCount = result.getInt(1); metastasisCount = result.getInt(2); }
      }
    } catch (Exception exception) {
      application.log("Unable to load patient monitoring data.", exception);
      monitoringError = "Unable to load patient monitoring data. Please try again.";
    } finally {
      if (result != null) try { result.close(); } catch (SQLException ignored) { }
      if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
      if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
    }
  }
  String encodedPatientId = URLEncoder.encode(monitoringPatientId, "UTF-8");
%>
<link rel="stylesheet" href="<%=request.getContextPath()%>/style/patient-monitoring.css?v=<%=new File(application.getRealPath("/style/patient-monitoring.css")).lastModified()%>">
<script src="<%=request.getContextPath()%>/includes/patient-monitoring-doctor-adapter.js"></script>
<script src="<%=request.getContextPath()%>/includes/patient-monitoring-api.js"></script>
<div class="patient-monitoring patient-monitoring-detail" data-patient-id="<%=monitoringHtml(monitoringPatientId)%>">
  <div class="monitoring-header monitoring-hero">
    <div class="hero-copy">
      <p class="hero-eyebrow">PATIENT CARE &middot; <%=monitoringIsPsychologist ? "PSYCHOLOGIST" : "DOCTOR"%> VIEW</p>
      <h2><%=monitoringHtml(profile.get("Name") == null || profile.get("Name").isEmpty() ? "Patient Monitoring" : profile.get("Name"))%></h2>
      <span class="hero-chip">Patient ID <strong><%=monitoringHtml(monitoringPatientId)%></strong></span>
      <% if (profile.get("Age") != null) { %><span class="hero-chip"><%=monitoringHtml(profile.get("Age"))%></span><% } %>
      <% if (profile.get("Gender") != null) { %><span class="hero-chip"><%=monitoringHtml(profile.get("Gender"))%></span><% } %>
      <% if (distressScore >= 0) { %><span class="hero-chip hero-status <%=distressHigh ? "high" : "low"%>">Distress <%=monitoringHtml(distressStatus)%> &middot; <%=distressScore%>/10</span><% } %>
    </div>
    <div class="hero-actions">
      <button type="button" class="hero-btn" onclick="return showMonitoringPatientList();">&larr; Patient list</button>
      <button type="button" class="hero-btn" onclick="return reloadMonitoringPage();"><span class="glyphicon glyphicon-refresh" aria-hidden="true"></span> Refresh</button>
    </div>
  </div>
  <div id="doctor-monitoring-message" class="alert" role="status" aria-live="polite" style="display:none"></div>
  <% if (monitoringError != null) { %>
    <div class="monitoring-error" role="alert"><%=monitoringHtml(monitoringError)%></div>
  <% } else { %>
  <ul class="monitoring-tabs" role="tablist">
    <li class="active" data-tab="overview" role="tab" tabindex="0" aria-selected="true">Overview</li>
    <li data-tab="screening" role="tab" tabindex="0" aria-selected="false">Screening History</li>
    <li data-tab="treatment" role="tab" tabindex="0" aria-selected="false">Treatment &amp; Actions</li>
  </ul>
  <div class="monitoring-tabpane" data-pane="overview">
  <div class="row">
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="distress-heading">
        <div class="panel-heading"><h3 id="distress-heading" class="panel-title">Distress Status</h3></div>
        <div class="panel-body" id="distress-status-panel">
          <p><span class="monitoring-status <%=distressHigh ? "high" : ""%>"><%=monitoringHtml(distressStatus)%></span></p>
          <p><%=monitoringHtml(distressMessage)%></p>
          <% if (distressScore >= 0) { %>
            <div class="monitoring-gauge" title="Distress score <%=distressScore%>/10"><div class="monitoring-gauge-fill <%=distressScore > 4 ? "high" : (distressScore > 2 ? "mid" : "low")%>" style="width:<%=distressScore * 10%>%"></div></div>
            <div class="monitoring-gauge-scale"><span>0</span><span>5</span><span>10</span></div>
          <% } %>
          <h4>Problem List</h4>
          <% if (problemList.isEmpty()) { %>
            <div class="monitoring-empty">No concerns selected.</div>
          <% } else { for (Map.Entry<String, List<String>> group : problemList.entrySet()) { %>
            <p><strong><%=monitoringHtml(group.getKey())%></strong></p>
            <ul><% for (String concern : group.getValue()) { %><li><%=monitoringHtml(concern)%></li><% } %></ul>
          <% } } %>
        </div>
      </section>
    </div>
    <div class="col-md-6">
      <section class="panel monitoring-card" aria-labelledby="summary-heading">
        <div class="panel-heading"><h3 id="summary-heading" class="panel-title">Patient Summary</h3></div>
        <div class="panel-body" id="patient-summary-panel">
          <% for (Map.Entry<String, String> entry : profile.entrySet()) { %>
            <p><strong><%=monitoringHtml(entry.getKey())%>:</strong> <%=entry.getValue() == null || entry.getValue().trim().isEmpty() ? "Not provided" : monitoringHtml(entry.getValue())%></p>
          <% } %>
          <% if (monitoringIsPsychologist) { %>
            <p><button type="button" class="btn btn-primary" onclick="clearPanel('patientScreeningReport.jsp?pat_id=<%=encodedPatientId%>'); return false;"><span class="glyphicon glyphicon-time" aria-hidden="true"></span> Screening History &amp; Follow-up</button></p>
          <% } %>
        </div>
      </section>
    </div>
  </div>
  <section class="panel monitoring-card" aria-labelledby="trend-heading">
    <div class="panel-heading"><h3 id="trend-heading" class="panel-title">Distress History</h3></div>
    <div class="panel-body">
      <% if (screenings.isEmpty()) { %>
        <div class="monitoring-empty">No screenings recorded yet.</div>
      <% } else { for (String[] row : screenings) { int rowScore = Integer.parseInt(row[1]); Map<String, List<String>> rowGroups = concernsByScreening.get(row[0]); %>
        <div class="monitoring-trend-row" data-toggle-target="trend-<%=monitoringHtml(row[0])%>" role="button" tabindex="0">
          <span class="monitoring-trend-date"><%=monitoringHtml(row[2])%></span>
          <span class="monitoring-trend-label"><%=monitoringHtml(row[3])%></span>
          <span class="monitoring-gauge small"><span class="monitoring-gauge-fill <%=rowScore > 4 ? "high" : (rowScore > 2 ? "mid" : "low")%>" style="width:<%=rowScore * 10%>%"></span></span>
          <span class="monitoring-trend-score"><%=rowScore%>/10</span>
        </div>
        <div id="trend-<%=monitoringHtml(row[0])%>" class="monitoring-trend-detail" style="display:none">
          <% if (rowGroups == null) { %><em>No concerns selected.</em><% } else { for (Map.Entry<String, List<String>> g : rowGroups.entrySet()) { %>
            <strong><%=monitoringHtml(g.getKey())%></strong>
            <ul><% for (String c : g.getValue()) { %><li><%=monitoringHtml(c)%></li><% } %></ul>
          <% } } %>
        </div>
      <% } } %>
    </div>
  </section>
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
  <div class="monitoring-tabpane" data-pane="treatment" style="display:none">
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
  <section class="panel monitoring-card" aria-labelledby="action-history-heading">
    <div class="panel-heading"><h3 id="action-history-heading" class="panel-title">Doctor Action History</h3></div>
    <div class="panel-body">
      <% if (actions.isEmpty()) { %>
        <div class="monitoring-empty">No actions recorded yet.</div>
      <% } else { %>
        <div class="table-responsive"><table class="table table-striped monitoring-history"><thead><tr><th>Date</th><th>Action</th><th>Remarks</th><th>By</th></tr></thead><tbody>
        <% for (String[] act : actions) { %><tr><td><%=monitoringHtml(act[3])%></td><td><%=monitoringHtml(act[0])%></td><td><%=monitoringHtml(act[1])%></td><td><%=monitoringHtml(act[2])%></td></tr><% } %>
        </tbody></table></div>
      <% } %>
    </div>
  </section>
  </div>
  <div class="monitoring-tabpane" data-pane="screening" style="display:none">
    <iframe id="screening-history-frame" class="monitoring-iframe" title="Screening history" data-src="patientScreeningReport.jsp?pat_id=<%=encodedPatientId%>&amp;embed=1"></iframe>
  </div>
  <% } %>
</div>
<script>
$(document).off("click.mtab keydown.mtab").on("click.mtab keydown.mtab", ".monitoring-tabs li", function (e) {
  if (e.type === "keydown" && e.which !== 13 && e.which !== 32) return;
  var tab = $(this).data("tab");
  $(".monitoring-tabs li").removeClass("active");
  $(this).addClass("active");
  $(".monitoring-tabs li").attr("aria-selected", "false");
  $(this).attr("aria-selected", "true");
  $(".monitoring-tabpane").hide();
  $(".monitoring-tabpane[data-pane='" + tab + "']").fadeIn(150);
  var frame = document.getElementById("screening-history-frame");
  if (tab === "screening" && frame && !frame.getAttribute("src")) frame.setAttribute("src", frame.getAttribute("data-src"));
});
(function () {
  var frame = document.getElementById("screening-history-frame");
  if (!frame) return;
  function fit() { try { frame.style.height = (frame.contentWindow.document.documentElement.scrollHeight + 20) + "px"; } catch (e) { } }
  frame.addEventListener("load", function () {
    fit();
    try { frame.contentWindow.document.addEventListener("click", function () { setTimeout(fit, 50); }); } catch (e) { }
  });
}());
$(".monitoring-gauge-fill").each(function () {
  var el = $(this), w = el.css("width"), target = el[0].style.width;
  el.css("width", 0);
  setTimeout(function () { el.css("width", target); }, 80);
});
function reloadMonitoringPage() {
  $("#main_frame").load("patientMonitoringDoctor.jsp?patId=<%=encodedPatientId%>");
  return false;
}
$(document).off("click.trend keydown.trend").on("click.trend keydown.trend", ".monitoring-trend-row", function (e) {
  if (e.type === "keydown" && e.which !== 13 && e.which !== 32) return;
  e.preventDefault();
  $("#" + $(this).data("toggle-target")).slideToggle(150);
  $(this).toggleClass("open");
});
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
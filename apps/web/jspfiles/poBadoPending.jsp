<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.io.*,java.sql.*,java.time.LocalDate,java.util.*,java.net.URLEncoder" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
    private String html(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private String dbValue(String key, String defaultValue, HttpServletRequest request) {
        BufferedReader reader = null;
        try {
            File webRoot = new File(request.getRealPath("/"));
            File root = webRoot.getParentFile().getParentFile();
            File config = new File(root, "services/legacy/runtime/gblinfo.inf");
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
  List<Map<String,String>> pendingPatients = new ArrayList<Map<String,String>>();
  String patientSearch = request.getParameter("search");
  if (patientSearch == null) patientSearch = request.getParameter("pat_id");
  patientSearch = patientSearch == null ? "" : patientSearch.trim();
  String error = null;
  String[] checkpoints = {"Baseline Assessment", "4 week Assessment", "8 week Assessment", "12 week Assessment"};
  int[] checkpointDays = {0, 28, 56, 84};
  String role = new cook().getCookieValue("usertype", request.getCookies());
  String center = new cook().getCookieValue("center", request.getCookies());
  if (!"adm".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) {
      error = "Access denied.";
  } else {
    Connection connection = null;
    PreparedStatement statement = null;
    ResultSet result = null;
    try {
      String dbUrl = dbValue("gbldburl", "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
      String dbUser = dbValue("gbldbusername", "root", request);
      String dbPassword = dbValue("gbldbpasswd", "", request);
      String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
      Class.forName(dbDriver);
      connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);

      Map<String,Set<String>> completedTools = new HashMap<String,Set<String>>();
      String historySql = "SELECT patient_id, assessment_checkpoint, tool_name FROM (" +
          "SELECT cr_number AS patient_id, assessment_checkpoint, 'PO Bado' AS tool_name FROM pobado_screening UNION ALL " +
          "SELECT pat_id AS patient_id, assessment_checkpoint, 'Distress Thermometer' AS tool_name FROM distress_thermometer UNION ALL " +
          "SELECT pat_id AS patient_id, assessment_checkpoint, 'PHQ-9' AS tool_name FROM phq9_screening UNION ALL " +
          "SELECT pat_id AS patient_id, assessment_checkpoint, 'GAD-7' AS tool_name FROM gad7_screening" +
          ") AS assessment_history";
      statement = connection.prepareStatement(historySql);
      result = statement.executeQuery();
      while (result.next()) {
        String key = result.getString("patient_id") + "|" + result.getString("assessment_checkpoint");
        Set<String> tools = completedTools.get(key);
        if (tools == null) {
          tools = new HashSet<String>();
          completedTools.put(key, tools);
        }
        tools.add(result.getString("tool_name"));
      }
      result.close();
      statement.close();
      result = null;
      statement = null;

      String patientSql = "SELECT m.pat_id, m.pat_name, m.m_name, m.l_name, m.entrydate, MAX(l.appdate) AS appointment_date " +
          "FROM med m LEFT JOIN lpatq l ON l.pat_id=m.pat_id WHERE m.entrydate IS NOT NULL";
      boolean filterCenter = center != null && !center.trim().isEmpty() && !"XXXX".equalsIgnoreCase(center.trim());
      if (filterCenter) patientSql += " AND UPPER(m.pat_id) LIKE UPPER(?)";
      if (!patientSearch.isEmpty()) patientSql += " AND (UPPER(m.pat_id) LIKE UPPER(?) OR UPPER(CONCAT_WS(' ', m.pat_name, m.m_name, m.l_name)) LIKE UPPER(?))";
      patientSql += " GROUP BY m.pat_id,m.pat_name,m.m_name,m.l_name,m.entrydate ORDER BY m.entrydate DESC,m.pat_id";
      statement = connection.prepareStatement(patientSql);
      int parameter = 1;
      if (filterCenter) statement.setString(parameter++, center.trim() + "%");
      if (!patientSearch.isEmpty()) {
        statement.setString(parameter++, "%" + patientSearch + "%");
        statement.setString(parameter, "%" + patientSearch + "%");
      }
      result = statement.executeQuery();
      LocalDate today = LocalDate.now();
      while (result.next()) {
        String patientId = result.getString("pat_id");
        Timestamp registrationTimestamp = result.getTimestamp("entrydate");
        if (registrationTimestamp == null) continue;
        LocalDate registrationDate = registrationTimestamp.toLocalDateTime().toLocalDate();
        String dueCheckpoint = null;
        for (int checkpointIndex = 0; checkpointIndex < checkpoints.length; checkpointIndex++) {
          LocalDate dueDate = registrationDate.plusDays(checkpointDays[checkpointIndex]);
          if (today.isBefore(dueDate)) break;
          Set<String> tools = completedTools.get(patientId + "|" + checkpoints[checkpointIndex]);
          if (tools == null || tools.size() < 4) {
            dueCheckpoint = checkpoints[checkpointIndex];
            break;
          }
        }
        if (dueCheckpoint == null) continue;
        StringBuilder patientName = new StringBuilder();
        String[] nameParts = {result.getString("pat_name"), result.getString("m_name"), result.getString("l_name")};
        for (String part : nameParts) if (part != null && !part.trim().isEmpty()) {
          if (patientName.length() > 0) patientName.append(' ');
          patientName.append(part.trim());
        }
        Map<String,String> patient = new HashMap<String,String>();
        patient.put("pat_id", patientId);
        patient.put("patient_name", patientName.toString().replaceFirst("^\\s*\\d+\\s*", ""));
        patient.put("appointment_date", result.getString("appointment_date"));
        patient.put("assessment_checkpoint", dueCheckpoint);
        pendingPatients.add(patient);
      }
      if ("1".equals(request.getParameter("next")) && !pendingPatients.isEmpty()) {
        String excludedPatientId = request.getParameter("exclude_pat_id");
        for (Map<String,String> nextPatient : pendingPatients) {
          if (excludedPatientId != null && excludedPatientId.equalsIgnoreCase(nextPatient.get("pat_id"))) continue;
          response.sendRedirect("pendingScreeningSelection.jsp?pat_id=" + URLEncoder.encode(nextPatient.get("pat_id"), "UTF-8") + "&checkpoint=" + URLEncoder.encode(nextPatient.get("assessment_checkpoint"), "UTF-8"));
          return;
        }
        response.sendRedirect("poBadoPending.jsp?no_next=1");
        return;
      }
    } catch (Exception exception) {
      error = "Unable to load pending screening checkpoints.";
    } finally {
      if (result != null) try { result.close(); } catch (SQLException ignored) { }
      if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
      if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pending Screenings</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    body { background: #eef6fa; color: #243746; }
    .queue-shell { max-width: 1120px; margin: 26px auto; padding: 0 18px; }
    .queue-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; color: #fff; background: #245b86; border-radius: 6px 6px 0 0; }
    .queue-header h1 { margin: 0; font-size: 26px; }
    .queue-header p { margin: 5px 0 0; color: #dff0fa; }
    .queue-body { padding: 22px; background: #fff; border: 1px solid #c8dce8; border-top: 0; border-radius: 0 0 6px 6px; }
    .badge-count { padding: 8px 12px; color: #245b86; background: #e3f1f8; border-radius: 3px; font-weight: 700; }
    .table > thead > tr > th { color: #385568; background: #eaf5fb; border-bottom-width: 1px; }
    .start-link { color: #fff; background: #8f4d43; border: 0; border-radius: 3px; padding: 7px 11px; white-space: nowrap; }
    .start-link:hover, .start-link:focus { color: #fff; background: #743d35; text-decoration: none; }
    .empty-state { padding: 42px 12px; color: #637887; text-align: center; }
    @media (max-width: 700px) { .queue-shell { margin: 10px auto; padding: 0 8px; } .queue-header, .queue-body { padding: 16px; } .queue-header h1 { font-size: 22px; } }
  </style>
</head>
<body>
  <main class="queue-shell">
    <header class="queue-header">
      <div><h1>Pending Screenings</h1><p>Select a patient to begin the screening assessment.</p></div>
      <i class="fa fa-heartbeat fa-2x" aria-hidden="true"></i>
    </header>
    <section class="queue-body">
      <form class="patient-search" onsubmit="clearPanel('poBadoPending.jsp?search=' + encodeURIComponent(this.search.value.trim())); return false;" style="display:flex;align-items:end;gap:8px;flex-wrap:wrap;margin-bottom:18px;">
        <label for="search" style="margin:0;">Patient ID or Name</label>
        <input id="search" name="search" type="search" maxlength="100" value="<%= html(patientSearch) %>" placeholder="Search by patient ID or name" class="form-control" style="width:min(100%,320px);">
        <button type="submit" class="btn btn-primary">Search</button>
        <% if (!patientSearch.isEmpty()) { %><button type="button" class="btn btn-default" onclick="clearPanel('poBadoPending.jsp'); return false;">Clear</button><% } %>
      </form>
      <% if (error != null) { %>
        <div class="alert alert-danger"><%= error %></div>
      <% } else { %>
        <% if ("1".equals(request.getParameter("no_next"))) { %><div class="alert alert-info">There are no other patients currently due for screening.</div><% } %>
        <div class="table-responsive">
          <table class="table table-hover">
            <thead><tr><th>CR Number</th><th>Patient</th><th>Appointment Date</th><th>Assessment Checkpoint</th><th></th></tr></thead>
            <tbody>
              <% for (Map<String,String> patient : pendingPatients) { String patientId = patient.get("pat_id"); String checkpoint = patient.get("assessment_checkpoint"); %>
                <tr>
                  <td><%= html(patientId) %></td>
                  <td><%= html(patient.get("patient_name")) %></td>
                  <td><%= html(patient.get("appointment_date")) %></td>
                  <td><%= html(checkpoint) %></td>
                  <td><a class="start-link" href="pendingScreeningSelection.jsp?pat_id=<%= URLEncoder.encode(patientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(checkpoint, "UTF-8") %>">Start screening</a></td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
        <% if (pendingPatients.size() == 0) { %><div class="empty-state">There are no patients pending screening.</div><% } %>
      <% } %>
    </section>
  </main>
</body>
</html>
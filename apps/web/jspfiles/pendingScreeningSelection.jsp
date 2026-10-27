<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,imedix.rcGenOperations,java.io.*,java.sql.*,java.net.URLEncoder" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
  private String html(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
  }

  private String displayPatientName(String value) {
    return value == null ? "" : value.replaceFirst("^\\s*\\d+\\s*", "");
  }

  private String displayPatientAge(String value) {
    if (value == null || value.trim().isEmpty()) return "";
    String[] parts = value.split(",", -1);
    if (parts.length < 3) return value.trim() + " years";
    String[] units = {"years", "months", "days"};
    StringBuilder formatted = new StringBuilder();
    for (int index = 0; index < 3; index++) {
      String part = parts[index].trim();
      if (part.isEmpty()) part = "0";
      if (formatted.length() > 0) formatted.append(", ");
      formatted.append(part).append(' ').append(units[index]);
    }
    return formatted.toString();
  }

  private String dbValue(String key, String defaultValue, HttpServletRequest request) {
    String value = defaultValue;
    BufferedReader reader = null;
    try {
      File webappDir = new File(request.getRealPath("/"));
      File repoRoot = webappDir.getParentFile().getParentFile();
      File config = new File(repoRoot, "services/legacy/runtime/gblinfo.inf");
      if (!config.exists()) config = new File(repoRoot, "M-Dosthi-BL/gblinfo.inf");
      if (!config.exists()) config = new File("M-Dosthi-BL/gblinfo.inf");
      if (!config.exists()) return value;
      reader = new BufferedReader(new FileReader(config));
      String line;
      while ((line = reader.readLine()) != null) {
        line = line.trim();
        int separator = line.indexOf('=');
        if (separator > 0 && key.equalsIgnoreCase(line.substring(0, separator).trim())) {
          value = line.substring(separator + 1).trim();
          break;
        }
      }
    } catch (Exception ignored) {
    } finally {
      if (reader != null) try { reader.close(); } catch (IOException ignored) { }
    }
    return value;
  }
%>
<%
  String selectedPatientId = request.getParameter("pat_id");
  String assessmentCheckpoint = request.getParameter("checkpoint");
  if (assessmentCheckpoint == null || assessmentCheckpoint.trim().isEmpty()) assessmentCheckpoint = "Baseline Assessment";
  String patientName = "";
  String patientPhone = "";
  String patientAge = "";
  String patientSex = "";
  String loadingError = null;

  if (selectedPatientId == null || selectedPatientId.trim().isEmpty()) {
    loadingError = "No patient was selected.";
  } else {
    Connection connection = null;
    PreparedStatement statement = null;
    ResultSet result = null;
    try {
      String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi?useUnicode=true&characterEncoding=UTF-8", request);
      String dbUser = dbValue("gbldbusername", "root", request);
      String dbPassword = dbValue("gbldbpasswd", "", request);
      String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
      Class.forName(dbDriver);
      connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);
      statement = connection.prepareStatement("SELECT pat_name, phone, age, sex FROM med WHERE pat_id=?");
      statement.setString(1, selectedPatientId.trim());
      result = statement.executeQuery();
      if (result.next()) {
        patientName = displayPatientName(new rcGenOperations(request.getRealPath("/")).getPatientName(selectedPatientId.trim()));
        if (patientName == null || patientName.trim().isEmpty()) {
          patientName = displayPatientName(result.getString("pat_name"));
        }
        patientPhone = result.getString("phone") == null ? "" : result.getString("phone");
        patientAge = displayPatientAge(result.getString("age"));
        patientSex = result.getString("sex") == null ? "" : result.getString("sex");
      } else {
        loadingError = "The selected patient could not be verified.";
      }
    } catch (Exception exception) {
      loadingError = "Unable to load patient details.";
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
  <title>Screening Tool Selection</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    :root {
      --primary: #245b86;
      --primary-light: #eaf5fb;
      --accent: #8f4d43;
      --muted: #637887;
      --line: #c8dce8;
      --ink: #243746;
      --disabled: #dfe7ed;
    }
    body { margin: 0; background: linear-gradient(135deg, #6abeef 0, #eaf5fb 38%, #f8fbfd 100%); color: var(--ink); font-family: Arial, Helvetica, sans-serif; }
    .shell { max-width: 1100px; margin: 26px auto; padding: 0 18px; }
    .header { display: flex; align-items: center; justify-content: space-between; gap: 18px; padding: 20px 24px; color: #fff; background: linear-gradient(110deg, var(--primary), #3f7fb3); border-radius: 6px 6px 0 0; }
    .header h1 { margin: 0; font-size: 28px; }
    .header p { margin: 5px 0 0; color: #dfeef9; }
    .panel { background: rgba(255,255,255,.96); border: 1px solid rgba(36, 91, 134, .15); border-top: 0; border-radius: 0 0 6px 6px; padding: 24px 22px 28px; }
    .patient-card { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; background: var(--primary-light); border: 1px solid var(--line); border-radius: 6px; padding: 14px 18px; margin-bottom: 18px; }
    .patient-card .label { font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .08em; }
    .patient-card .value { font-size: 16px; font-weight: 700; }
    .tool-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; }
    .tool-button { display: block; min-height: 130px; padding: 16px 14px; border-radius: 6px; text-align: left; text-decoration: none; background: #fff; border: 1px solid var(--line); box-shadow: 0 6px 14px rgba(36,91,134,.08); transition: transform .12s ease, box-shadow .12s ease; }
    .tool-button:hover, .tool-button:focus { text-decoration: none; transform: translateY(-1px); box-shadow: 0 10px 18px rgba(36,91,134,.12); }
    .tool-button.primary { background: linear-gradient(135deg, #eaf5fb, #f6fbff); }
    .tool-button.disabled { background: #f6f8fa; border-style: dashed; color: #6c7d8a; cursor: not-allowed; box-shadow: none; }
    .tool-button .icon { display: inline-block; width: 38px; height: 38px; margin-bottom: 8px; line-height: 38px; text-align: center; border-radius: 50%; background: var(--primary-light); color: var(--primary); font-size: 18px; }
    .tool-button .name { display: block; font-size: 18px; font-weight: 700; color: var(--ink); }
    .tool-button.disabled .name { color: #6c7d8a; }
    .tool-button .meta { display: block; margin-top: 8px; font-size: 12px; color: var(--muted); }
    .tool-button.disabled .meta { color: #7a8b9a; }
    .actions { display: flex; justify-content: flex-end; gap: 12px; margin-top: 22px; }
    .secondary { display: inline-block; margin-top: 18px; padding: 10px 14px; background: #edf4f9; color: var(--primary); border: 1px solid var(--line); border-radius: 4px; text-decoration: none; font-weight: 700; }
    .secondary:hover, .secondary:focus { text-decoration: none; color: var(--primary); }
    .next-patient { display: inline-block; margin-top: 18px; padding: 10px 14px; background: var(--accent); color: #fff; border: 1px solid var(--accent); border-radius: 4px; text-decoration: none; font-weight: 700; }
    .next-patient:hover, .next-patient:focus { color: #fff; text-decoration: none; }
    .alert { margin-top: 12px; padding: 12px 14px; border-radius: 4px; background: #fff0f0; border: 1px solid #f0b9b9; color: #7a2d2d; }
    @media (max-width: 700px) { .shell { padding: 0 8px; } .header, .panel { padding-left: 16px; padding-right: 16px; } .header h1 { font-size: 22px; } .tool-grid { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <main class="shell">
    <header class="header">
      <div>
        <h1>Pending Screening</h1>
        <p>Select the screening tool for the current patient.</p>
      </div>
      <i class="fa fa-heartbeat fa-2x" aria-hidden="true"></i>
    </header>
    <section class="panel">
      <% if (loadingError != null) { %>
        <div class="alert"><%= html(loadingError) %></div>
      <% } else { %>
        <div class="patient-card">
          <div><div class="label">Patient ID</div><div class="value"><%= html(selectedPatientId) %></div></div>
          <div><div class="label">Patient Name</div><div class="value"><%= html(patientName) %></div></div>
          <div><div class="label">Age</div><div class="value"><%= html(patientAge) %></div></div>
          <div><div class="label">Sex</div><div class="value"><%= html(patientSex) %></div></div>
          <div><div class="label">Assessment Checkpoint</div><div class="value"><%= html(assessmentCheckpoint) %></div></div>
        </div>

        <div class="tool-grid">
          <a class="tool-button primary" href="poBadoScreening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">
            <span class="icon"><i class="fa fa-stethoscope" aria-hidden="true"></i></span>
            <span class="name">PO Bado Screening</span>
            <span class="meta">Open the current PO Bado assessment.</span>
          </a>

          <a class="tool-button primary" href="distressThermometerScreening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">
            <span class="icon"><i class="fa fa-thermometer" aria-hidden="true"></i></span>
            <span class="name">Distress Thermometer</span>
            <span class="meta">Record the patient’s distress rating from 0 to 10.</span>
          </a>

          <a class="tool-button primary" href="phq9Screening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">
            <span class="icon"><i class="fa fa-file-text-o" aria-hidden="true"></i></span>
            <span class="name">PHQ-9</span>
            <span class="meta">Open the PHQ-9 questionnaire for the current patient.</span>
          </a>

          <a class="tool-button primary" href="gad7Screening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">
            <span class="icon"><i class="fa fa-line-chart" aria-hidden="true"></i></span>
            <span class="name">GAD-7</span>
            <span class="meta">Complete the anxiety questionnaire for the current patient.</span>
          </a>
        </div>

        <div class="actions">
          <a class="secondary" href="poBadoPending.jsp">Back to pending screenings</a>
          <a class="next-patient" href="poBadoPending.jsp?next=1&amp;exclude_pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>">Go to Next Patient</a>
        </div>
      <% } %>
    </section>
  </main>
</body>
</html>

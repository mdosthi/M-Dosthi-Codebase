<%@ page contentType="text/html" pageEncoding="UTF-8" import="java.io.*,java.sql.*,java.net.URLEncoder,imedix.cook,imedix.medinfo,imedix.rcGenOperations" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
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
    if (parts.length == 1) return value;
    String[] units = {"years", "months", "days"};
    StringBuilder formatted = new StringBuilder();
    for (int index = 0; index < parts.length && index < units.length; index++) {
      String part = parts[index].trim();
      if (!part.isEmpty() && !"0".equals(part)) {
        if (formatted.length() > 0) formatted.append(", ");
        formatted.append(part).append(' ').append(units[index]);
      }
    }
    return formatted.length() == 0 ? "0 years" : formatted.toString();
  }

  private String todayIso() {
    java.time.LocalDate today = java.time.LocalDate.now();
    return today.toString();
  }
%>
<%
  String selectedPatientId = request.getParameter("pat_id");
  String assessmentCheckpoint = request.getParameter("checkpoint");
  if (assessmentCheckpoint == null || assessmentCheckpoint.trim().isEmpty()) assessmentCheckpoint = "Baseline Assessment";
  String patientName = "";
  String patientAge = "";
  String patientSex = "";
  String patientGender = "";
  String formSaved = request.getParameter("saved");
  String formError = request.getParameter("error");
  Integer latestPhq9Score = null;
  String loadingError = null;

  if (selectedPatientId == null || selectedPatientId.trim().isEmpty()) {
    loadingError = "No patient was selected.";
  } else {
    Connection patientConnection = null;
    PreparedStatement patientStatement = null;
    ResultSet patientResult = null;
    try {
      String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi?useUnicode=true&characterEncoding=UTF-8", request);
      String dbUser = dbValue("gbldbusername", "root", request);
      String dbPassword = dbValue("gbldbpasswd", "", request);
      String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
      Class.forName(dbDriver);
      patientConnection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);
      patientStatement = patientConnection.prepareStatement("SELECT pat_name, age, sex FROM med WHERE pat_id=?");
      patientStatement.setString(1, selectedPatientId.trim());
      patientResult = patientStatement.executeQuery();
      if (patientResult.next()) {
        patientName = displayPatientName(new rcGenOperations(request.getRealPath("/")).getPatientName(selectedPatientId.trim()));
        if (patientName == null || patientName.trim().isEmpty()) patientName = displayPatientName(patientResult.getString("pat_name"));
        patientAge = displayPatientAge(patientResult.getString("age"));
        patientSex = patientResult.getString("sex");
        medinfo patientMeta = new medinfo(request.getRealPath("/"));
        patientGender = patientMeta.getSexValues().getValue(patientSex);
        if (patientGender == null || patientGender.trim().isEmpty()) patientGender = patientSex;

        patientResult.close();
        patientResult = null;
        patientStatement.close();
        patientStatement = patientConnection.prepareStatement("SELECT total_score FROM phq9_screening WHERE pat_id=? ORDER BY id DESC LIMIT 1");
        patientStatement.setString(1, selectedPatientId.trim());
        patientResult = patientStatement.executeQuery();
        if (patientResult.next()) latestPhq9Score = patientResult.getInt("total_score");
      } else {
        loadingError = "The selected patient could not be verified.";
      }
    } catch (Exception ignored) {
      loadingError = "Unable to load patient details.";
    } finally {
      if (patientResult != null) try { patientResult.close(); } catch (SQLException ignored) { }
      if (patientStatement != null) try { patientStatement.close(); } catch (SQLException ignored) { }
      if (patientConnection != null) try { patientConnection.close(); } catch (SQLException ignored) { }
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PHQ-9 Screening</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    :root {
      --primary: #245b86;
      --primary-soft: #eaf5fb;
      --line: #c8dce8;
      --ink: #243746;
      --muted: #637887;
      --accent: #8f4d43;
      --success: #256f3c;
    }
    body { margin: 0; background: linear-gradient(135deg, #6abeef 0, #eaf5fb 38%, #f8fbfd 100%); color: var(--ink); font-family: Arial, Helvetica, sans-serif; }
    .screen-shell { max-width: 1100px; margin: 26px auto 44px; padding: 0 18px; }
    .screen-header { display: flex; align-items: center; justify-content: space-between; gap: 18px; padding: 22px 28px; color: #fff; background: linear-gradient(110deg, var(--primary), #3f7fb3); border-radius: 6px 6px 0 0; box-shadow: 0 8px 20px rgba(36, 91, 134, .18); }
    .screen-header h1 { margin: 0 0 5px; font-size: 30px; }
    .screen-header p { margin: 0; color: #dfeef9; }
    .screen-form { background: rgba(255,255,255,.96); border: 1px solid rgba(36, 91, 134, .15); border-top: 0; border-radius: 0 0 6px 6px; padding: 26px 24px 28px; }
    .patient-card { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; background: var(--primary-soft); border: 1px solid var(--line); border-radius: 6px; padding: 14px 18px; margin-bottom: 18px; }
    .patient-card .label { font-size: 12px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .08em; }
    .patient-card .value { font-size: 16px; font-weight: 700; }
    .section-title { display: flex; align-items: center; gap: 10px; margin: 26px 0 18px; padding-bottom: 10px; color: var(--primary); border-bottom: 2px solid #d9eaf3; font-size: 17px; font-weight: 700; }
    .field { margin-bottom: 18px; }
    .field label { display: block; margin-bottom: 7px; color: #385568; font-size: 13px; font-weight: 700; }
    .field input[type="text"], .field input[type="date"], .field select {
      width: 100%; min-height: 42px; padding: 9px 12px; color: var(--ink); background: #fbfdfe; border: 1px solid var(--line); border-radius: 4px; box-shadow: inset 0 1px 2px rgba(36, 91, 134, .05);
    }
    .field input:focus, .field select:focus { outline: 0; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(70,130,180,.14); }
    .choice-group { display: flex; flex-wrap: wrap; gap: 8px; }
    .choice { position: relative; }
    .choice input { position: absolute; opacity: 0; pointer-events: none; }
    .choice label {
      display: block; min-width: 118px; margin: 0; padding: 10px 12px; background: #f4f9fc; border: 1px solid var(--line); border-radius: 4px; color: #496576; font-size: 13px; font-weight: 600; cursor: pointer; text-align: center;
    }
    .choice input:checked + label { background: #dfeef9; border-color: var(--primary); color: var(--primary); box-shadow: inset 0 0 0 1px rgba(36,91,134,.15); }
    .score-box { display: flex; align-items: center; justify-content: space-between; gap: 18px; margin-top: 24px; padding: 18px 20px; background: #f5fafb; border: 1px solid var(--line); border-radius: 6px; }
    .score-box span { font-size: 16px; font-weight: 700; color: var(--ink); }
    .score-box strong { font-size: 30px; color: var(--success); }
    .actions { display: flex; justify-content: flex-start; gap: 12px; margin-top: 22px; }
    .primary-btn, .secondary-btn { display: inline-block; padding: 11px 18px; border-radius: 4px; font-weight: 700; text-decoration: none; }
    .primary-btn { background: var(--accent); color: #fff; border: 0; }
    .primary-btn:hover, .primary-btn:focus { color: #fff; text-decoration: none; }
    .secondary-btn { background: #edf4f9; color: var(--primary); border: 1px solid var(--line); }
    .secondary-btn:hover, .secondary-btn:focus { color: var(--primary); text-decoration: none; }
    .alert { margin-bottom: 12px; padding: 12px 14px; background: #fff0f0; border: 1px solid #f0b9b9; border-radius: 4px; color: #7a2d2d; }
    .success-alert { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-top:18px; padding:14px 16px; background:#edf9f0; border:1px solid #b9d9c1; border-radius:4px; color:#1d5b35; }
    .next-screening { display:inline-block; padding:9px 13px; border-radius:3px; color:#fff; background:var(--primary); font-weight:700; text-decoration:none; white-space:nowrap; }
    .next-screening:hover, .next-screening:focus { color:#fff; background:#194568; text-decoration:none; }
    @media (max-width: 700px) { .screen-shell { padding: 0 8px; } .screen-header, .screen-form { padding-left: 16px; padding-right: 16px; } .screen-header h1 { font-size: 24px; } .choice label { min-width: 100%; } }
  </style>
</head>
<body>
  <main class="screen-shell">
    <header class="screen-header">
      <div>
        <h1>PHQ-9 Screening</h1>
        <p>Complete the patient health questionnaire for the current patient.</p>
      </div>
      <i class="fa fa-file-text-o fa-2x" aria-hidden="true"></i>
    </header>

    <section class="screen-form">
      <% if (loadingError != null) { %>
        <div class="alert"><%= html(loadingError) %></div>
      <% } else { %>
        <div class="patient-card">
          <div><div class="label">Patient ID</div><div class="value"><%= html(selectedPatientId) %></div></div>
          <div><div class="label">Patient Name</div><div class="value"><%= html(patientName) %></div></div>
          <div><div class="label">Age</div><div class="value"><%= html(patientAge) %></div></div>
          <div><div class="label">Sex</div><div class="value"><%= html(patientGender.isEmpty() ? patientSex : patientGender) %></div></div>
          <div><div class="label">Last PHQ-9 Score</div><div class="value"><%= latestPhq9Score == null ? "Not assessed" : latestPhq9Score %></div></div>
        </div>

        <% if (formError != null && !formError.trim().isEmpty()) { %><div class="alert"><%= html(formError) %></div><% } %>

        <form method="post" action="savePhq9Screening.jsp" id="phq9Form">
          <input type="hidden" name="pat_id" value="<%= html(selectedPatientId) %>">
          <input type="hidden" name="assessment_checkpoint" value="<%= html(assessmentCheckpoint) %>">
          <input type="hidden" name="patient_name" value="<%= html(patientName) %>">

          <div class="field">
            <label for="patientIdReadOnly">Patient ID</label>
            <input id="patientIdReadOnly" type="text" value="<%= html(selectedPatientId) %>" readonly>
          </div>

          <div class="field">
            <label for="screeningDate">Screening Date</label>
            <input id="screeningDate" name="screening_date" type="date" value="<%= html(todayIso()) %>" readonly>
          </div>

          <div class="section-title"><i class="fa fa-list" aria-hidden="true"></i>PHQ-9 questionnaire</div>

          <div class="field">
            <label>1. Do you find little interest or pleasure in doing things?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q1" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q1" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q1" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q1" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>2. Do you feel down, depressed, or hopeless?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q2" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q2" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q2" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q2" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>3. Trouble falling or staying asleep, or sleeping too much?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q3" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q3" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q3" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q3" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>4. Do you feel tired or have little energy?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q4" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q4" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q4" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q4" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>5. Poor appetite or overeating?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q5" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q5" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q5" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q5" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>6. Do you feel bad about yourself or that you are a failure or have let yourself or your family down?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q6" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q6" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q6" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q6" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>7. Trouble concentrating on things, such as reading the newspaper or watching television?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q7" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q7" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q7" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q7" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>8. Moving or speaking so slowly that other people could have noticed. Or the opposite, being so fidgety or restless that you have been moving around a lot more than usual?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q8" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q8" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q8" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q8" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="field">
            <label>9. Thoughts that you would be better off dead, or of hurting yourself?</label>
            <div class="choice-group">
              <div class="choice"><input type="radio" name="q9" value="0" required><label>Not at all</label></div>
              <div class="choice"><input type="radio" name="q9" value="1"><label>Several days</label></div>
              <div class="choice"><input type="radio" name="q9" value="2"><label>More than half the days</label></div>
              <div class="choice"><input type="radio" name="q9" value="3"><label>Nearly every day</label></div>
            </div>
          </div>

          <div class="score-box">
            <span>Total score</span>
            <strong id="totalScore">0</strong>
          </div>

          <div class="actions">
            <button type="submit" class="primary-btn">Save PHQ-9 screening</button>
            <a class="secondary-btn" href="pendingScreeningSelection.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">Back to tool selection</a>
          </div>
          <% if ("1".equals(formSaved)) { %>
            <div class="success-alert" role="status">
              <span>PHQ-9 Score saved successfully. Would you like to perform the next screen for this patient?</span>
              <a class="next-screening" href="gad7Screening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">GAD-7</a>
            </div>
          <% } %>
        </form>
      <% } %>
    </section>
  </main>

  <script>
    (function() {
      function calculateTotal() {
        var total = 0;
        var answerInputs = document.querySelectorAll('#phq9Form input[type="radio"]:checked');
        answerInputs.forEach(function (input) {
          total += Number(input.value || 0);
        });
        var totalScoreNode = document.getElementById('totalScore');
        if (totalScoreNode) totalScoreNode.textContent = total;
      }
      var radios = document.querySelectorAll('#phq9Form input[type="radio"]');
      radios.forEach(function (radio) {
        radio.id = radio.name + '_' + radio.value;
        radio.nextElementSibling.htmlFor = radio.id;
        radio.addEventListener('change', calculateTotal);
      });
      calculateTotal();
    })();
  </script>
</body>
</html>

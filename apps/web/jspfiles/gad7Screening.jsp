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
    return java.time.LocalDate.now().toString();
  }
%>
<%
  String patientId = request.getParameter("pat_id");
  String assessmentCheckpoint = request.getParameter("checkpoint");
  if (assessmentCheckpoint == null || assessmentCheckpoint.trim().isEmpty()) assessmentCheckpoint = "Baseline Assessment";
  String patientName = "";
  String patientAge = "";
  String patientSex = "";
  String patientGender = "";
  String saved = request.getParameter("saved");
  String error = request.getParameter("error");
  Integer latestGad7Score = null;
  String loadingError = null;
  String[] questions = {
    "Feeling nervous, anxious, or on edge",
    "Not being able to stop or control worrying",
    "Worrying too much about different things",
    "Trouble relaxing",
    "Being so restless that it is hard to sit still",
    "Becoming easily annoyed or irritable",
    "Feeling afraid, as if something awful might happen"
  };
  String[] answers = {"Not at all", "Several days", "More than half the days", "Nearly every day"};

  if (patientId == null || patientId.trim().isEmpty()) {
    loadingError = "No patient was selected.";
  } else {
    Connection connection = null;
    PreparedStatement statement = null;
    ResultSet patient = null;
    try {
      String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi?useUnicode=true&characterEncoding=UTF-8", request);
      String dbUser = dbValue("gbldbusername", "root", request);
      String dbPassword = dbValue("gbldbpasswd", "", request);
      String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
      Class.forName(dbDriver);
      connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);
      statement = connection.prepareStatement("SELECT pat_name, age, sex FROM med WHERE pat_id=?");
      statement.setString(1, patientId.trim());
      patient = statement.executeQuery();
      if (patient.next()) {
        patientName = displayPatientName(new rcGenOperations(request.getRealPath("/")).getPatientName(patientId.trim()));
        if (patientName == null || patientName.trim().isEmpty()) patientName = displayPatientName(patient.getString("pat_name"));
        patientAge = displayPatientAge(patient.getString("age"));
        patientSex = patient.getString("sex");
        medinfo patientMeta = new medinfo(request.getRealPath("/"));
        patientGender = patientMeta.getSexValues().getValue(patientSex);
        if (patientGender == null || patientGender.trim().isEmpty()) patientGender = patientSex;

        patient.close();
        patient = null;
        statement.close();
        statement = connection.prepareStatement("SELECT total_score FROM gad7_screening WHERE pat_id=? ORDER BY id DESC LIMIT 1");
        statement.setString(1, patientId.trim());
        patient = statement.executeQuery();
        if (patient.next()) latestGad7Score = patient.getInt("total_score");
      } else {
        loadingError = "The selected patient could not be verified.";
      }
    } catch (Exception ignored) {
      loadingError = "Unable to load patient details.";
    } finally {
      if (patient != null) try { patient.close(); } catch (SQLException ignored) { }
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
  <title>GAD-7 Screening</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    :root { --primary:#245b86; --soft:#eaf5fb; --line:#c8dce8; --ink:#243746; --muted:#637887; --accent:#8f4d43; --success:#256f3c; }
    body { margin:0; background:linear-gradient(135deg,#6abeef 0,#eaf5fb 38%,#f8fbfd 100%); color:var(--ink); font-family:Arial,Helvetica,sans-serif; }
    .shell { max-width:1120px; margin:26px auto 44px; padding:0 18px; }
    .header { display:flex; align-items:center; justify-content:space-between; gap:18px; padding:22px 28px; color:#fff; background:linear-gradient(110deg,var(--primary),#3f7fb3); border-radius:6px 6px 0 0; }
    .header h1 { margin:0 0 5px; font-size:28px; }
    .header p { margin:0; color:#e3f1fa; }
    .panel { padding:24px; background:rgba(255,255,255,.97); border:1px solid rgba(36,91,134,.15); border-top:0; border-radius:0 0 6px 6px; }
    .patient { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:12px; margin-bottom:20px; padding:14px 18px; background:var(--soft); border:1px solid var(--line); border-radius:5px; }
    .patient-label { color:var(--muted); font-size:12px; font-weight:700; text-transform:uppercase; }
    .patient-value { font-weight:700; }
    .instruction { margin:20px 0 14px; font-weight:700; }
    .gad-table { width:100%; border-collapse:collapse; }
    .gad-table th, .gad-table td { padding:12px 10px; border:1px solid var(--line); vertical-align:middle; }
    .gad-table thead th { background:#eaf5fb; color:#385568; text-align:center; font-size:13px; }
    .gad-table thead th:first-child { width:28%; text-align:left; }
    .gad-table tbody th { background:#fbfdfe; text-align:left; font-weight:600; }
    .answer-cell { text-align:center; }
    .answer-cell input { width:19px; height:19px; accent-color:var(--primary); cursor:pointer; }
    .date-field { max-width:250px; margin:20px 0; }
    .date-field label { display:block; margin-bottom:6px; font-weight:700; }
    .date-field input { width:100%; min-height:40px; padding:8px 10px; background:#f5f9fb; border:1px solid var(--line); border-radius:4px; }
    .result { display:flex; align-items:center; justify-content:space-between; gap:16px; margin-top:18px; padding:16px 18px; background:#f5fafb; border:1px solid var(--line); border-radius:5px; }
    .result-label { font-weight:700; }
    .result-value { display:flex; align-items:baseline; gap:18px; }
    .result-value strong { color:var(--success); font-size:28px; }
    .result-value span { min-width:145px; color:var(--primary); font-weight:700; text-align:right; }
    .actions { display:flex; gap:10px; margin-top:20px; }
    .primary,.secondary { display:inline-block; padding:11px 16px; border-radius:4px; font-weight:700; text-decoration:none; }
    .primary { color:#fff; background:var(--accent); border:0; }
    .secondary { color:var(--primary); background:#edf4f9; border:1px solid var(--line); }
    .primary:hover,.primary:focus { color:#fff; }
    .secondary:hover,.secondary:focus { color:var(--primary); }
    .alert { padding:12px 14px; margin-bottom:14px; border-radius:4px; background:#edf9f0; border:1px solid #b9d9c1; color:#1d5b35; }
    .alert.error { background:#fff0f0; border-color:#f0b9b9; color:#7a2d2d; }
    .success-alert { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-top:18px; padding:14px 16px; background:#edf9f0; border:1px solid #b9d9c1; border-radius:4px; color:#1d5b35; }
    @media(max-width:760px) {
      .shell { margin-top:10px; padding:0 8px; }
      .header,.panel { padding:16px; }
      .header h1 { font-size:23px; }
      .table-wrap { overflow-x:auto; }
      .gad-table { min-width:760px; }
    }
  </style>
</head>
<body>
  <main class="shell">
    <header class="header"><div><h1>GAD-7 Screening</h1><p>Generalized Anxiety Disorder assessment</p></div><i class="fa fa-line-chart fa-2x" aria-hidden="true"></i></header>
    <section class="panel">
      <% if (loadingError != null) { %>
        <div class="alert error"><%= html(loadingError) %></div>
      <% } else { %>
        <% if (error != null && !error.trim().isEmpty()) { %><div class="alert error"><%= html(error) %></div><% } %>
        <div class="patient">
          <div><div class="patient-label">Patient ID</div><div class="patient-value"><%= html(patientId) %></div></div>
          <div><div class="patient-label">Patient Name</div><div class="patient-value"><%= html(patientName) %></div></div>
          <div><div class="patient-label">Age</div><div class="patient-value"><%= html(patientAge) %></div></div>
          <div><div class="patient-label">Sex</div><div class="patient-value"><%= html(patientGender) %></div></div>
          <div><div class="patient-label">Last GAD-7 Score</div><div class="patient-value"><%= latestGad7Score == null ? "Not assessed" : latestGad7Score %></div></div>
        </div>
        <form id="gad7Form" method="post" action="saveGad7Screening.jsp">
          <input type="hidden" name="pat_id" value="<%= html(patientId) %>">
          <input type="hidden" name="assessment_checkpoint" value="<%= html(assessmentCheckpoint) %>">
          <input type="hidden" name="patient_name" value="<%= html(patientName) %>">
          <p class="instruction">Over the last 2 weeks, how often have you been bothered by the following problems?</p>
          <div class="table-wrap">
            <table class="gad-table">
              <thead><tr><th>Questions</th><% for (String answer : answers) { %><th><%= html(answer) %><br><small><%= java.util.Arrays.asList(answers).indexOf(answer) %></small></th><% } %></tr></thead>
              <tbody>
                <% for (int questionIndex = 0; questionIndex < questions.length; questionIndex++) { %>
                  <tr><th scope="row"><%= questionIndex + 1 %>. <%= html(questions[questionIndex]) %></th>
                    <% for (int answerIndex = 0; answerIndex < answers.length; answerIndex++) { %>
                      <td class="answer-cell"><input type="radio" id="q<%= questionIndex + 1 %>_<%= answerIndex %>" name="q<%= questionIndex + 1 %>" value="<%= answerIndex %>" aria-label="Question <%= questionIndex + 1 %>: <%= html(answers[answerIndex]) %>, score <%= answerIndex %>" required></td>
                    <% } %>
                  </tr>
                <% } %>
              </tbody>
            </table>
          </div>
          <div class="date-field"><label for="screeningDate">Screening date</label><input id="screeningDate" name="screening_date" type="date" value="<%= todayIso() %>" readonly></div>
          <div class="result"><span class="result-label">Total GAD-7 score and anxiety category</span><div class="result-value"><strong id="totalScore">0</strong><span id="anxietyCategory">Complete all questions</span></div></div>
          <div class="actions">
            <button type="submit" class="primary">Save GAD-7 screening</button>
            <a class="secondary" href="pendingScreeningSelection.jsp?pat_id=<%= URLEncoder.encode(patientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">Back to tool selection</a>
          </div>
          <% if ("1".equals(saved)) { %>
            <div class="success-alert" role="status">GAD-7 Score saved successfully.</div>
          <% } %>
        </form>
      <% } %>
    </section>
  </main>
  <script>
    (function () {
      var form = document.getElementById('gad7Form');
      if (!form) return;
      var totalNode = document.getElementById('totalScore');
      var categoryNode = document.getElementById('anxietyCategory');
      var categoryFor = function (score) {
        if (score <= 4) return 'Minimal anxiety';
        if (score <= 9) return 'Mild anxiety';
        if (score <= 14) return 'Moderate anxiety';
        return 'Severe anxiety';
      };
      var updateResult = function () {
        var checked = form.querySelectorAll('input[type="radio"]:checked');
        var total = 0;
        checked.forEach(function (answer) { total += Number(answer.value); });
        totalNode.textContent = total;
        categoryNode.textContent = checked.length === 7 ? categoryFor(total) : 'Complete all questions';
      };
      form.querySelectorAll('input[type="radio"]').forEach(function (answer) {
        answer.addEventListener('change', updateResult);
      });
      updateResult();
    })();
  </script>
</body>
</html>

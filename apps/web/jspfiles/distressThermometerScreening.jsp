<%@ page contentType="text/html" pageEncoding="UTF-8" import="java.io.*,java.sql.*,java.time.LocalDate,java.net.URLEncoder,imedix.cook,imedix.rcGenOperations" %>
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

  private static final String[][][] problemCategories = {
    {{"Physical Concerns"}, {"pain", "Pain"}, {"sleep", "Sleep"}, {"fatigue", "Fatigue"}, {"tobacco_use", "Tobacco use"}, {"substance_use", "Substance use"}, {"memory_concentration", "Memory or concentration"}, {"sexual_health", "Sexual health"}, {"changes_eating", "Changes in eating"}, {"physical_abilities", "Loss or change of physical abilities"}},
    {{"Practical Concerns"}, {"care_self", "Taking care of myself"}, {"care_others", "Taking care of others"}, {"safety", "Safety"}, {"work", "Work"}, {"school", "School"}, {"housing_utilities", "Housing/Utilities"}, {"finances", "Finances"}, {"insurance", "Insurance"}, {"transportation", "Transportation"}, {"child_care", "Child care"}, {"enough_food", "Having enough food"}, {"access_medicine", "Access to medicine"}, {"treatment_decisions", "Treatment decisions"}},
    {{"Emotional Concerns"}, {"worry_anxiety", "Worry or anxiety"}, {"sadness_depression", "Sadness or depression"}, {"loss_interest", "Loss of interest or enjoyment"}, {"grief_loss", "Grief or loss"}, {"fear", "Fear"}, {"loneliness", "Loneliness"}, {"anger", "Anger"}, {"changes_appearance", "Changes in appearance"}, {"worthlessness_burden", "Feelings of worthlessness or being a burden"}},
    {{"Spiritual or Religious Concerns"}, {"meaning_purpose", "Sense of meaning or purpose"}, {"faith_beliefs", "Changes in faith or beliefs"}, {"death_afterlife", "Death, dying, or afterlife"}, {"beliefs_treatment_conflict", "Conflict between beliefs and cancer treatments"}, {"sacred_relationship", "Relationship with the sacred"}, {"ritual_dietary", "Ritual or dietary needs"}},
    {{"Social Concerns"}, {"relationship_partner", "Relationship with spouse or partner"}, {"relationship_children", "Relationship with children"}, {"relationship_family", "Relationship with family members"}, {"relationship_friends", "Relationship with friends or coworkers"}, {"healthcare_communication", "Communication with health care team"}, {"ability_have_children", "Ability to have children"}, {"prejudice_discrimination", "Prejudice or discrimination"}}
  };
%>
<%
  String patientId = request.getParameter("pat_id");
  String assessmentCheckpoint = request.getParameter("checkpoint");
  if (assessmentCheckpoint == null || assessmentCheckpoint.trim().isEmpty()) assessmentCheckpoint = "Baseline Assessment";
  String patientName = "";
  Integer latestDistressScore = null;
  String latestDistressDate = "";
  String loadingError = null;
  String saved = request.getParameter("saved");
  String error = request.getParameter("error");
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
      statement = connection.prepareStatement("SELECT pat_name FROM med WHERE pat_id=?");
      statement.setString(1, patientId.trim());
      patient = statement.executeQuery();
      if (patient.next()) {
        patientName = new rcGenOperations(request.getRealPath("/")).getPatientName(patientId.trim());
        if (patientName == null || patientName.trim().isEmpty()) patientName = patient.getString("pat_name");
        if (patientName != null) patientName = patientName.replaceFirst("^\\s*\\d+\\s*", "");

        patient.close();
        patient = null;
        statement.close();
        statement = connection.prepareStatement("SELECT distress_score, screening_date FROM distress_thermometer WHERE pat_id=? ORDER BY id DESC LIMIT 1");
        statement.setString(1, patientId.trim());
        patient = statement.executeQuery();
        if (patient.next()) {
          latestDistressScore = patient.getInt("distress_score");
          latestDistressDate = patient.getString("screening_date");
        }
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
  <title>Distress Thermometer</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    :root { --primary:#245b86; --line:#c8dce8; --ink:#243746; --muted:#637887; --accent:#8f4d43; }
    body { margin:0; background:linear-gradient(135deg,#6abeef 0,#eaf5fb 38%,#f8fbfd 100%); color:var(--ink); font-family:Arial,Helvetica,sans-serif; }
    .shell { max-width:960px; margin:26px auto 44px; padding:0 18px; }
    .header { display:flex; align-items:center; justify-content:space-between; gap:18px; padding:22px 28px; color:#fff; background:linear-gradient(110deg,var(--primary),#3f7fb3); border-radius:6px 6px 0 0; }
    .header h1 { margin:0 0 5px; font-size:28px; }
    .header p { margin:0; color:#e3f1fa; }
    .panel { padding:24px; background:rgba(255,255,255,.97); border:1px solid rgba(36,91,134,.15); border-top:0; border-radius:0 0 6px 6px; }
    .patient { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:12px; margin-bottom:24px; padding:14px 18px; background:#eaf5fb; border:1px solid var(--line); border-radius:5px; }
    .label { margin-bottom:4px; color:var(--muted); font-size:12px; font-weight:700; text-transform:uppercase; }
    .value { font-weight:700; }
    .question { margin:0 0 18px; font-size:20px; font-weight:700; line-height:1.45; }
    .range { display:grid; grid-template-columns:repeat(11,minmax(36px,1fr)); gap:7px; }
    .rating { position:relative; }
    .rating input { position:absolute; width:1px; height:1px; opacity:0; }
    .rating label { display:grid; place-items:center; min-height:48px; margin:0; background:#f5f9fb; border:1px solid var(--line); border-radius:4px; color:#385568; font-size:16px; font-weight:700; cursor:pointer; }
    .rating input:checked + label { background:var(--primary); border-color:#173f5e; color:#fff; }
    .rating input:focus-visible + label { outline:3px solid #a4d4f1; outline-offset:2px; }
    .anchors { display:flex; justify-content:space-between; margin:8px 0 20px; color:var(--muted); font-size:13px; }
    .problem-list { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:16px; margin:26px 0 8px; }
    .problem-category { padding:14px; background:#f7fafc; border:1px solid var(--line); border-radius:5px; }
    .problem-category h3 { margin:0 0 12px; color:var(--primary); font-size:16px; text-decoration:underline; }
    .problem-option { display:flex; align-items:flex-start; gap:9px; margin:0; padding:9px 10px; background:#fff; border:1px solid #dce7ed; border-radius:4px; cursor:pointer; }
    .problem-option input { width:18px; height:18px; flex:0 0 auto; margin:1px 0 0; accent-color:var(--primary); }
    .problem-option span { line-height:1.4; }
    .problem-instruction { margin:-8px 0 0; font-weight:600; }
    .other-option { display:flex; align-items:center; gap:10px; min-height:39px; }
    .other-option input[type="checkbox"] { width:18px; height:18px; flex:0 0 auto; margin:0; accent-color:var(--primary); }
    .other-option input[type="text"] { width:100%; min-width:0; height:30px; border:0; border-bottom:1px solid var(--ink); background:transparent; }
    .screen-date { max-width:250px; margin:22px 0; }
    .screen-date label { display:block; margin-bottom:6px; font-weight:700; }
    .screen-date input { width:100%; min-height:40px; padding:8px 10px; border:1px solid var(--line); border-radius:4px; background:#f5f9fb; color:var(--ink); }
    .score { display:flex; align-items:center; justify-content:space-between; margin-top:22px; padding:14px 16px; border:1px solid var(--line); background:#f5fafb; border-radius:5px; }
    .score strong { font-size:26px; color:var(--primary); }
    .actions { display:flex; gap:10px; margin-top:20px; }
    .primary, .secondary { display:inline-block; padding:11px 16px; border-radius:4px; font-weight:700; text-decoration:none; }
    .primary { color:#fff; background:var(--accent); border:0; }
    .secondary { color:var(--primary); background:#edf4f9; border:1px solid var(--line); }
    .success-alert { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-top:18px; padding:14px 16px; border:1px solid #b9d9c1; border-radius:4px; color:#1d5b35; background:#edf9f0; }
    .next-screening { display:inline-block; padding:9px 13px; border-radius:3px; color:#fff; background:#245b86; font-weight:700; text-decoration:none; white-space:nowrap; }
    .next-screening:hover,.next-screening:focus { color:#fff; background:#194568; text-decoration:none; }
    .primary:hover,.primary:focus { color:#fff; }
    .secondary:hover,.secondary:focus { color:var(--primary); }
    .alert { padding:12px 14px; margin-bottom:16px; border-radius:4px; background:#edf9f0; border:1px solid #b9d9c1; color:#1d5b35; }
    .alert.error { background:#fff0f0; border-color:#f0b9b9; color:#7a2d2d; }
    @media(max-width:650px) { .shell{padding:0 8px;margin-top:10px}.header,.panel{padding:17px}.header h1{font-size:23px}.range{gap:4px}.rating label{min-height:42px;font-size:14px}.question{font-size:18px}.problem-list{grid-template-columns:1fr} }
  </style>
</head>
<body>
  <main class="shell">
    <header class="header"><div><h1>Distress Thermometer</h1><p>Patient distress rating</p></div><i class="fa fa-thermometer-three-quarters fa-2x" aria-hidden="true"></i></header>
    <section class="panel">
      <% if (loadingError != null) { %>
        <div class="alert error"><%= html(loadingError) %></div>
      <% } else { %>
        <% if (error != null && !error.trim().isEmpty()) { %><div class="alert error"><%= html(error) %></div><% } %>
        <div class="patient">
          <div><div class="label">Patient ID</div><div class="value"><%= html(patientId) %></div></div>
          <div><div class="label">Patient Name</div><div class="value"><%= html(patientName) %></div></div>
          <div><div class="label">Last Distress Score</div><div class="value"><%= latestDistressScore == null ? "Not assessed" : latestDistressScore %><%= latestDistressDate == null || latestDistressDate.isEmpty() ? "" : " (" + html(latestDistressDate) + ")" %></div></div>
        </div>
        <form method="post" action="saveDistressThermometer.jsp" id="distressForm">
          <input type="hidden" name="pat_id" value="<%= html(patientId) %>">
          <input type="hidden" name="assessment_checkpoint" value="<%= html(assessmentCheckpoint) %>">
          <p class="question">How distressed have you been during the past week, including today?</p>
          <div class="range" role="radiogroup" aria-label="Distress score from 0 to 10">
            <% for (int score = 0; score <= 10; score++) { %>
              <div class="rating"><input id="distress_<%= score %>" type="radio" name="distress_score" value="<%= score %>" required><label for="distress_<%= score %>"><%= score %></label></div>
            <% } %>
          </div>
          <div class="anchors"><span>No distress</span><span>Extreme distress</span></div>
          <section aria-labelledby="problemListHeading">
            <h2 id="problemListHeading" class="question">Problem List</h2>
            <p class="problem-instruction">Have you had concerns about any of the items below in the past week, including today? (Mark all that apply)</p>
            <div class="problem-list">
              <% for (int categoryIndex = 0; categoryIndex < problemCategories.length; categoryIndex++) { String[][] category = problemCategories[categoryIndex]; %>
                <section class="problem-category">
                  <h3><%= html(category[0][0]) %></h3>
                  <% for (int itemIndex = 1; itemIndex < category.length; itemIndex++) { %>
                    <label class="problem-option"><input type="checkbox" name="problem_id" value="<%= html(category[itemIndex][0]) %>"><span><%= html(category[itemIndex][1]) %></span></label>
                  <% } %>
                </section>
              <% } %>
              <section class="problem-category">
                <h3>Other Concerns</h3>
                <% for (int otherIndex = 1; otherIndex <= 3; otherIndex++) { %>
                  <div class="other-option">
                    <input type="checkbox" name="other_concern_selected_<%= otherIndex %>" value="1" aria-label="Select other concern <%= otherIndex %>">
                    <input type="text" name="other_concern_<%= otherIndex %>" maxlength="100" aria-label="Other concern <%= otherIndex %>">
                  </div>
                <% } %>
              </section>
            </div>
          </section>
          <div class="screen-date"><label for="screeningDate">Screening date</label><input id="screeningDate" name="screening_date" type="date" value="<%= LocalDate.now() %>" readonly></div>
          <div class="score"><span>Distress score</span><strong id="scoreValue">-</strong></div>
          <div class="actions">
            <button type="submit" class="primary">Save screening</button>
            <a class="secondary" href="pendingScreeningSelection.jsp?pat_id=<%= URLEncoder.encode(patientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">Back to tools</a>
          </div>
          <% if ("1".equals(saved)) { %>
            <div class="success-alert" role="status">
              <span>Distress Score saved successfully. Would you like to perform the next screen for this patient?</span>
              <a class="next-screening" href="phq9Screening.jsp?pat_id=<%= URLEncoder.encode(patientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">PHQ-9</a>
            </div>
          <% } %>
        </form>
      <% } %>
    </section>
  </main>
  <script>
    document.querySelectorAll('#distressForm input[name="distress_score"]').forEach(function (input) {
      input.addEventListener('change', function () {
        document.getElementById('scoreValue').textContent = input.value;
      });
    });
  </script>
</body>
</html>

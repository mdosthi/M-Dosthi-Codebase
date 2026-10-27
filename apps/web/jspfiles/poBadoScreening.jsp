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

  private String htmlAttribute(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;");
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
%>
<%
  String saveStatus = request.getParameter("saved");
  String saveError = request.getParameter("error");
  String userRole = new cook().getCookieValue("usertype", request.getCookies());
  boolean canScreenNext = "doc".equalsIgnoreCase(userRole) || "adm".equalsIgnoreCase(userRole) || "psy".equalsIgnoreCase(userRole);
  String selectedPatientId = request.getParameter("pat_id");
  String assessmentCheckpoint = request.getParameter("checkpoint");
  if (assessmentCheckpoint == null || assessmentCheckpoint.trim().isEmpty()) assessmentCheckpoint = "Baseline Assessment";
  String patientName = "";
  String patientPhone = "";
  String patientAge = "";
  String patientSex = "";
  String patientGender = "";
  Integer latestPoBadoScore = null;

  if (selectedPatientId != null && !selectedPatientId.trim().isEmpty()) {
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
      patientStatement = patientConnection.prepareStatement("SELECT pat_name, phone, age, sex FROM med WHERE pat_id=?");
      patientStatement.setString(1, selectedPatientId.trim());
      patientResult = patientStatement.executeQuery();
      if (patientResult.next()) {
        patientName = displayPatientName(new rcGenOperations(request.getRealPath("/")).getPatientName(selectedPatientId.trim()));
        if (patientName.trim().isEmpty()) patientName = displayPatientName(patientResult.getString("pat_name"));
        patientPhone = patientResult.getString("phone");
        patientAge = displayPatientAge(patientResult.getString("age"));
        patientSex = patientResult.getString("sex");
        medinfo patientMeta = new medinfo(request.getRealPath("/"));
        patientGender = patientMeta.getSexValues().getValue(patientSex);
        if (patientGender == null || patientGender.trim().isEmpty()) patientGender = patientSex;

        patientResult.close();
        patientResult = null;
        patientStatement.close();
        patientStatement = patientConnection.prepareStatement("SELECT total_score FROM pobado_screening WHERE cr_number=? ORDER BY id DESC LIMIT 1");
        patientStatement.setString(1, selectedPatientId.trim());
        patientResult = patientStatement.executeQuery();
        if (patientResult.next()) latestPoBadoScore = patientResult.getInt("total_score");
      }
    } catch (Exception ignored) {
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
  <title>PO Bado Screening</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="../bootstrap/font-awesome-4.7.0/css/font-awesome.min.css">
  <style>
    :root {
      --primary: steelblue;
      --primary-dark: #245b86;
      --page: #eaf5fb;
      --ink: #243746;
      --muted: #637887;
      --line: #c8dce8;
      --accent: #8f4d43;
    }

    body {
      margin: 0;
      background: linear-gradient(135deg, #6abeef 0, #eaf5fb 38%, #f8fbfd 100%);
      color: var(--ink);
      font-family: Arial, Helvetica, sans-serif;
    }

    .screen-shell {
      max-width: 1180px;
      margin: 26px auto 44px;
      padding: 0 18px;
    }

    .screen-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 20px;
      padding: 22px 28px;
      color: #fff;
      background: linear-gradient(110deg, var(--primary-dark), var(--primary));
      border-radius: 6px 6px 0 0;
      box-shadow: 0 8px 20px rgba(36, 91, 134, .18);
    }

    .screen-header h1 {
      margin: 0 0 6px;
      font-family: Georgia, 'Times New Roman', serif;
      font-size: 30px;
      font-weight: 600;
    }

    .screen-header p {
      margin: 0;
      color: #e5f4fc;
      font-size: 14px;
    }
vbcr_psy
    .screen-mark {
      display: grid;
      width: 54px;
      height: 54px;
      place-items: center;
      border: 2px solid rgba(255, 255, 255, .72);
      border-radius: 50%;
      font-size: 23px;
    }

    .screen-form {
      padding: 28px;
      background: rgba(255, 255, 255, .96);
      border: 1px solid rgba(36, 91, 134, .15);
      border-top: 0;
      border-radius: 0 0 6px 6px;
      box-shadow: 0 12px 28px rgba(36, 91, 134, .14);
    }

    .section-title {
      display: flex;
      align-items: center;
      gap: 10px;
      margin: 24px 0 17px;
      padding-bottom: 9px;
      color: var(--primary-dark);
      border-bottom: 2px solid #d9eaf3;
      font-size: 17px;
      font-weight: 700;
    }

    .section-title:first-child { margin-top: 0; }
    .section-title i { color: var(--accent); }
    .field { margin-bottom: 16px; }
    .field label { display: block; margin-bottom: 6px; color: #385568; font-size: 13px; font-weight: 700; }
    .field label .required { color: #b04336; }
    .field input, .field select, .field textarea {
      width: 100%;
      min-height: 40px;
      padding: 9px 11px;
      color: var(--ink);
      background: #fbfdfe;
      border: 1px solid var(--line);
      border-radius: 3px;
      box-shadow: inset 0 1px 2px rgba(36, 91, 134, .05);
      transition: border-color .18s, box-shadow .18s;
    }
    .field textarea { min-height: 86px; resize: vertical; }
    .field input:focus, .field select:focus, .field textarea:focus {
      outline: 0;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(70, 130, 180, .14);
    }

    .choice-group { display: flex; flex-wrap: wrap; gap: 8px; padding-top: 3px; }
    .choice { position: relative; }
    .choice input { position: absolute; opacity: 0; pointer-events: none; }
    .choice label {
      display: block;
      min-width: 88px;
      margin: 0;
      padding: 10px 13px;
      color: #496576;
      background: #f4f9fc;
      border: 1px solid var(--line);
      border-radius: 3px;
      text-align: center;
      cursor: pointer;
    }
    .choice input:checked + label { color: #fff; background: var(--primary); border-color: var(--primary-dark); }

    .score-grid { display: grid; grid-template-columns: minmax(230px, 1fr) repeat(5, 50px); gap: 8px; align-items: center; }
    .score-grid .score-heading { color: var(--muted); font-size: 11px; font-weight: 700; text-align: center; }
    .score-grid .score-label { font-size: 13px; }
    .score-grid input { width: 18px; min-height: auto; margin: auto; accent-color: var(--primary); }

    .form-actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #d9eaf3; }
    .form-actions button { padding: 11px 23px; border: 0; border-radius: 3px; font-weight: 700; cursor: pointer; }
    .btn-reset { color: var(--primary-dark); background: #e6f1f7; }
    .btn-save { color: #fff; background: var(--accent); }
    .btn-save:hover, .btn-reset:hover { filter: brightness(.94); }
    .status-message { display: none; margin-top: 16px; padding: 12px 14px; color: #245b40; background: #e7f5ec; border: 1px solid #b8ddc4; border-radius: 3px; }
    .next-screening { display: inline-block; margin-left: 10px; padding: 7px 10px; color: #fff; background: var(--accent); border-radius: 3px; font-weight: 700; text-decoration: none; }
    .next-screening:hover, .next-screening:focus { color: #fff; background: #743d35; text-decoration: none; }
    .latest-score { display: flex; align-items: center; justify-content: space-between; gap: 14px; margin: 0 0 16px; padding: 13px 16px; color: #245b40; background: #e7f5ec; border: 1px solid #b8ddc4; border-radius: 3px; }
    .latest-score strong { font-size: 20px; }

    @media (max-width: 700px) {
      .screen-shell { margin-top: 10px; padding: 0 8px; }
      .screen-header, .screen-form { padding: 20px 16px; }
      .screen-header h1 { font-size: 24px; }
      .screen-mark { width: 44px; height: 44px; font-size: 18px; }
      .score-grid { grid-template-columns: minmax(150px, 1fr) repeat(5, 30px); gap: 4px; }
      .score-grid .score-label { font-size: 11px; }
      .form-actions { justify-content: stretch; }
      .form-actions button { flex: 1; }
    }
  </style>
</head>
<body>
  <main class="screen-shell">
    <header class="screen-header">
      <div>
        <h1>PO Bado Screening</h1>
        <p>Patient-reported screening and follow-up assessment</p>
      </div>
      <div class="screen-mark" aria-hidden="true"><i class="fa fa-heartbeat"></i></div>
    </header>

    <div class="screen-form" style="border-top: 1px solid rgba(36, 91, 134, .15); padding-top: 16px;">
      <a class="next-screening" href="pendingScreeningSelection.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId == null ? "" : selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>">Return to screening tools</a>
    </div>

    <% if (latestPoBadoScore != null) { %>
      <div class="latest-score" role="status"><span>Latest PO Bado score</span><strong><%= latestPoBadoScore %></strong></div>
    <% } %>

    <form class="screen-form" id="poBadoForm" method="post" action="savePoBadoScreening.jsp">
      <input type="hidden" name="assessment_checkpoint" value="<%= htmlAttribute(assessmentCheckpoint) %>">
      <div class="section-title"><i class="fa fa-id-card-o"></i> Patient details</div>
      <div class="row">
        <div class="col-sm-4 field"><label for="crNumber">CR number <span class="required">*</span></label><input id="crNumber" name="crNumber" value="<%= htmlAttribute(selectedPatientId) %>" readonly required></div>
        <div class="col-sm-4 field"><label for="phoneNumber">Phone number</label><input id="phoneNumber" name="phoneNumber" type="tel" value="<%= htmlAttribute(patientPhone) %>" readonly></div>
        <div class="col-sm-4 field"><label for="patientName">Patient <span class="required">*</span></label><input id="patientName" name="patientName" value="<%= htmlAttribute(patientName) %>" readonly required></div>
        <div class="col-sm-4 field"><label for="screeningDate">Date <span class="required">*</span></label><input id="screeningDate" name="screeningDate" type="date" required></div>
        <div class="col-sm-4 field"><label for="age">Age</label><input id="age" name="age" value="<%= htmlAttribute(patientAge) %>" readonly></div>
        <div class="col-sm-4 field"><label for="genderDisplay">Gender</label><input id="genderDisplay" value="<%= htmlAttribute(patientGender) %>" readonly><input type="hidden" name="gender" value="<%= htmlAttribute(patientSex) %>"></div>
      </div>

      <div class="section-title"><i class="fa fa-users"></i> Social and clinical background</div>
      <div class="row">
        <div class="col-sm-6 field"><label>Steady relationship</label><div class="choice-group"><div class="choice"><input id="relationshipYes" name="relationship" value="Yes" type="radio"><label for="relationshipYes">Yes</label></div><div class="choice"><input id="relationshipNo" name="relationship" value="No" type="radio"><label for="relationshipNo">No</label></div><div class="choice"><input id="relationshipUnknown" name="relationship" value="Not known" type="radio"><label for="relationshipUnknown">Not known</label></div></div></div>
        <div class="col-sm-6 field"><label>Children</label><div class="choice-group"><div class="choice"><input id="childrenYes" name="children" value="Yes" type="radio"><label for="childrenYes">Yes</label></div><div class="choice"><input id="childrenNo" name="children" value="No" type="radio"><label for="childrenNo">No</label></div><div class="choice"><input id="childrenUnknown" name="children" value="Not known" type="radio"><label for="childrenUnknown">Not known</label></div></div></div>
        <div class="col-sm-6 field"><label for="workSituation">Work situation</label><select id="workSituation" name="workSituation"><option value="">Select one</option><option>Employed</option><option>Sick leave</option><option>Unemployed</option><option>Home duties</option><option>Retired</option><option>Other</option></select></div>
        <div class="col-sm-6 field"><label for="tumourDiagnosis">Tumour diagnosis / localisation</label><textarea id="tumourDiagnosis" name="tumourDiagnosis" placeholder="For example: breast, lung, prostate, colorectal, skin, sarcoma, or other"></textarea></div>
        <div class="col-sm-6 field"><label>Metastasis</label><div class="choice-group"><div class="choice"><input id="metastasisYes" name="metastasis" value="Yes" type="radio"><label for="metastasisYes">Yes</label></div><div class="choice"><input id="metastasisNo" name="metastasis" value="No" type="radio"><label for="metastasisNo">No</label></div><div class="choice"><input id="metastasisUnknown" name="metastasis" value="Not known" type="radio"><label for="metastasisUnknown">Not known</label></div></div></div>
        <div class="col-sm-6 field"><label for="diagnosisDate">Date of first diagnosis</label><input id="diagnosisDate" name="diagnosisDate" type="month"></div>
        <div class="col-sm-6 field"><label for="diseaseState">Current state of disease</label><select id="diseaseState" name="diseaseState"><option value="">Select one</option><option>First occurrence</option><option>Recurrence</option><option>Not known</option><option>Second tumour</option><option>Remission</option></select></div>
        <div class="col-sm-12 field"><label for="treatments">Treatments during the last two months</label><textarea id="treatments" name="treatments" placeholder="Surgery, chemotherapy, radiotherapy, hormones, other"></textarea></div>
        <div class="col-sm-6 field"><label for="physicalDiseases">Other relevant physical diseases</label><textarea id="physicalDiseases" name="physicalDiseases"></textarea></div>
        <div class="col-sm-6 field"><label for="psychoactiveMedication">Psychoactive medication / opiates</label><textarea id="psychoactiveMedication" name="psychoactiveMedication" placeholder="For example: tranquilliser or morphine"></textarea></div>
        <div class="col-sm-6 field"><label>Previous psychological / psychiatric treatment</label><div class="choice-group"><div class="choice"><input id="psychYes" name="psychTreatment" value="Yes" type="radio"><label for="psychYes">Yes</label></div><div class="choice"><input id="psychNo" name="psychTreatment" value="No" type="radio"><label for="psychNo">No</label></div><div class="choice"><input id="psychUnknown" name="psychTreatment" value="Not known" type="radio"><label for="psychUnknown">Not known</label></div></div></div>
        <div class="col-sm-6 field"><label for="performanceStatus">Performance status (WHO-ECOG scale 0-4)</label><select id="performanceStatus" name="performanceStatus"><option value="">Select score</option><option value="0">0 - Normal activity</option><option value="1">1 - Nearly fully ambulatory</option><option value="2">2 - In bed less than 50% of normal waking hours</option><option value="3">3 - In bed more than 50% of normal waking hours</option><option value="4">4 - Permanently confined to bed</option></select></div>
      </div>

      <div class="section-title"><i class="fa fa-bar-chart"></i> Other assessment</div>
      <p class="text-muted">Rate each item from 0 (not at all) to 4 (very much).</p>
      <div class="score-grid" role="group" aria-label="Other assessment scores">
        <div></div><div class="score-heading">0</div><div class="score-heading">1</div><div class="score-heading">2</div><div class="score-heading">3</div><div class="score-heading">4</div>
        <div class="score-label">Fatigue / tiredness</div><input name="fatigue" value="0" type="radio"><input name="fatigue" value="1" type="radio"><input name="fatigue" value="2" type="radio"><input name="fatigue" value="3" type="radio"><input name="fatigue" value="4" type="radio">
        <div class="score-label">Mood swings / helplessness / vulnerability</div><input name="mood" value="0" type="radio"><input name="mood" value="1" type="radio"><input name="mood" value="2" type="radio"><input name="mood" value="3" type="radio"><input name="mood" value="4" type="radio">
        <div class="score-label">Anxiety / worries / tension</div><input name="anxiety" value="0" type="radio"><input name="anxiety" value="1" type="radio"><input name="anxiety" value="2" type="radio"><input name="anxiety" value="3" type="radio"><input name="anxiety" value="4" type="radio">
        <div class="score-label">Depression / grief</div><input name="depression" value="0" type="radio"><input name="depression" value="1" type="radio"><input name="depression" value="2" type="radio"><input name="depression" value="3" type="radio"><input name="depression" value="4" type="radio">
        <div class="score-label">Functional limitations in daily activities</div><input name="limitations" value="0" type="radio"><input name="limitations" value="1" type="radio"><input name="limitations" value="2" type="radio"><input name="limitations" value="3" type="radio"><input name="limitations" value="4" type="radio">
        <div class="score-label">Other social or family problems</div><input name="socialProblems" value="0" type="radio"><input name="socialProblems" value="1" type="radio"><input name="socialProblems" value="2" type="radio"><input name="socialProblems" value="3" type="radio"><input name="socialProblems" value="4" type="radio">
      </div>
      <div class="row" style="margin-top: 20px;">
        <div class="col-sm-4 field"><label for="totalScore">Total PO Bado score</label><input id="totalScore" name="totalScore" readonly value="0"></div>
        <div class="col-sm-4 field"><label for="substanceUse">Substance use</label><select id="substanceUse" name="substanceUse"><option value="">Select one</option><option>Tobacco</option><option>Alcohol</option><option>Other</option><option>None reported</option></select></div>
        <div class="col-sm-4 field"><label for="lastSubstanceUsed">Last substance used (time)</label><input id="lastSubstanceUsed" name="lastSubstanceUsed"></div>
        <div class="col-sm-6 field"><label for="followUpDate">Follow-up date</label><input id="followUpDate" name="followUpDate" type="date"></div>
        <div class="col-sm-6 field"><label for="bedNumber">Bed no</label><input id="bedNumber" name="bedNumber"></div>
      </div>

      <div class="form-actions"><button type="reset" class="btn-reset">Clear form</button><button type="submit" class="btn-save"><i class="fa fa-check"></i> Review screening</button></div>
      <div class="status-message" id="statusMessage" role="status">
        <% if (saveError != null) { %>
          Screening not completed. Please verify the patient details and try again.
        <% } else if ("1".equals(saveStatus)) { %>
          Screening completed successfully. would you like to perform the next screen for this patient?
          <% if (canScreenNext && selectedPatientId != null) { %>
            <a class="next-screening" href="distressThermometerScreening.jsp?pat_id=<%= URLEncoder.encode(selectedPatientId, "UTF-8") %>&amp;checkpoint=<%= URLEncoder.encode(assessmentCheckpoint, "UTF-8") %>"><i class="fa fa-thermometer-three-quarters"></i> Distress Thermometer</a>
          <% } %>
        <% } %>
      </div>
      </form>
  </main>
  <script>
    (function () {
      var form = document.getElementById('poBadoForm');
      var scoreNames = ['fatigue', 'mood', 'anxiety', 'depression', 'limitations', 'socialProblems'];
      var total = document.getElementById('totalScore');
      var status = document.getElementById('statusMessage');

      if (status.textContent.trim()) status.style.display = 'block';

      function updateTotal() {
        var sum = 0;
        scoreNames.forEach(function (name) {
          var selected = form.querySelector('input[name="' + name + '"]:checked');
          if (selected) sum += Number(selected.value);
        });
        total.value = sum;
      }

      form.addEventListener('change', updateTotal);
      form.addEventListener('submit', function (event) {
        updateTotal();
        status.textContent = 'Saving screening...';
        status.style.display = 'block';
      });
      form.addEventListener('reset', function () {
        window.setTimeout(function () { total.value = '0'; status.style.display = 'none'; }, 0);
      });
    }());
  </script>
</body>
</html>

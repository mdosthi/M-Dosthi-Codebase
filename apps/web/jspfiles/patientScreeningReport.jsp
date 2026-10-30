<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.io.*,java.sql.*,java.util.*,java.time.*,java.time.temporal.ChronoUnit" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
  private String html(Object value) {
    if (value == null) return "";
    return value.toString().replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }

  private String dbValue(String key, String defaultValue, HttpServletRequest request) {
    BufferedReader reader = null;
    try {
      File webRoot = new File(request.getRealPath("/"));
      File repositoryRoot = webRoot.getParentFile().getParentFile();
      File config = new File(repositoryRoot, "services/legacy/runtime/gblinfo.inf");
      if (!config.exists()) return defaultValue;
      reader = new BufferedReader(new FileReader(config));
      String line;
      while ((line = reader.readLine()) != null) {
        int separator = line.indexOf('=');
        if (separator > 0 && key.equalsIgnoreCase(line.substring(0, separator).trim())) {
          return line.substring(separator + 1).trim();
        }
      }
    } catch (Exception ignored) {
    } finally {
      if (reader != null) try { reader.close(); } catch (IOException ignored) { }
    }
    return defaultValue;
  }

  private int count(Connection connection, String table, String column, String patientId) throws SQLException {
    PreparedStatement statement = connection.prepareStatement(
      "SELECT COUNT(*) FROM " + table + " WHERE " + column + " = ?");
    try {
      statement.setString(1, patientId);
      ResultSet result = statement.executeQuery();
      try { return result.next() ? result.getInt(1) : 0; }
      finally { result.close(); }
    } finally { statement.close(); }
  }

  private void appendResponses(Map<String, Object> record, String[] labels, Object[] values) {
    List<Map<String, Object>> responses = new ArrayList<Map<String, Object>>();
    for (int i = 0; i < labels.length; i++) {
      Map<String, Object> response = new LinkedHashMap<String, Object>();
      response.put("label", labels[i]);
      response.put("value", values[i]);
      responses.add(response);
    }
    record.put("responses", responses);
  }

  private int checkpointWeek(String checkpoint) {
    if ("Baseline Assessment".equalsIgnoreCase(checkpoint)) return 0;
    if (checkpoint == null) return -1;
    if ("4 week Assessment".equalsIgnoreCase(checkpoint)) return 4;
    if ("8 week Assessment".equalsIgnoreCase(checkpoint)) return 8;
    if ("12 week Assessment".equalsIgnoreCase(checkpoint)) return 12;
    return -1;
  }

  private String countdown(long days) {
    if (days < 0) {
      long overdue = Math.abs(days);
      return "Due date passed by " + overdue + (overdue == 1 ? " day" : " days") +
        "; no completion is recorded for this checkpoint";
    }
    if (days == 0) return "Due today";
    return "Due in " + days + (days == 1 ? " day" : " days");
  }

  private LocalDate localDate(String value) {
    return value == null || value.trim().isEmpty()
      ? null : LocalDate.parse(value.substring(0, 10));
  }

  private Map<String, Object> scheduleItem(
      Connection connection, String patientId, String name, String table, String patientColumn,
      boolean hasSavedFollowUpDate) throws SQLException {
    Map<String, Object> item = new LinkedHashMap<String, Object>();
    item.put("screeningType", name);
    String baselineDate = null;
    PreparedStatement baselineStatement = connection.prepareStatement(
      "SELECT screening_date FROM " + table + " WHERE " + patientColumn +
      " = ? AND assessment_checkpoint = ? ORDER BY screening_date ASC, id ASC LIMIT 1");
    try {
      baselineStatement.setString(1, patientId);
      baselineStatement.setString(2, "Baseline Assessment");
      ResultSet baselineResult = baselineStatement.executeQuery();
      try { if (baselineResult.next()) baselineDate = baselineResult.getString("screening_date"); }
      finally { baselineResult.close(); }
    } finally { baselineStatement.close(); }

    String latestDate = null;
    String latestCheckpoint = null;
    String savedFollowUpDate = null;
    PreparedStatement latestStatement = connection.prepareStatement(
      "SELECT screening_date, assessment_checkpoint" +
      (hasSavedFollowUpDate ? ", follow_up_date" : "") +
      " FROM " + table + " WHERE " + patientColumn +
      " = ? ORDER BY screening_date DESC, id DESC LIMIT 1");
    try {
      latestStatement.setString(1, patientId);
      ResultSet latestResult = latestStatement.executeQuery();
      try {
        if (latestResult.next()) {
          latestDate = latestResult.getString("screening_date");
          latestCheckpoint = latestResult.getString("assessment_checkpoint");
          if (hasSavedFollowUpDate) savedFollowUpDate = latestResult.getString("follow_up_date");
        }
      } finally { latestResult.close(); }
    } finally { latestStatement.close(); }

    item.put("baselineDate", baselineDate);
    item.put("lastCompletedCheckpoint", latestCheckpoint);
    if (latestDate == null) {
      item.put("nextCheckpoint", "Baseline Assessment");
      item.put("dueDate", null);
      item.put("countdown", "Baseline screening not completed");
      return item;
    }
    if (localDate(baselineDate) == null) {
      item.put("nextCheckpoint", "Baseline Assessment");
      item.put("dueDate", null);
      item.put("countdown", "Baseline date unavailable; schedule cannot be calculated");
      return item;
    }

    int completedWeek = checkpointWeek(latestCheckpoint);
    if (completedWeek < 0) {
      item.put("nextCheckpoint", null);
      item.put("dueDate", null);
      item.put("countdown", "Schedule checkpoint unavailable");
      return item;
    }
    if (completedWeek >= 12) {
      item.put("nextCheckpoint", null);
      item.put("dueDate", null);
      item.put("countdown", "12-week schedule complete");
      return item;
    }

    int nextWeek = completedWeek + 4;
    LocalDate dueDate = localDate(savedFollowUpDate);
    if (dueDate == null) dueDate = localDate(baselineDate).plusWeeks(nextWeek);
    long daysRemaining = ChronoUnit.DAYS.between(LocalDate.now(), dueDate);
    item.put("nextCheckpoint", nextWeek + " week Assessment");
    item.put("dueDate", dueDate.toString());
    item.put("countdown", countdown(daysRemaining));
    return item;
  }
%>
<%
  String role = new cook().getCookieValue("usertype", request.getCookies());
  if (!"psy".equalsIgnoreCase(role)) {
    out.println("<div class=\"alert alert-danger\">Access denied.</div>");
    return;
  }

  String patientId = request.getParameter("pat_id");
  patientId = patientId == null ? "" : patientId.trim();
  int pageSize = 30;
  int pageNumber = 1;
  try { pageNumber = Math.max(1, Integer.parseInt(request.getParameter("page"))); } catch (Exception ignored) { }
  pageNumber = Math.min(pageNumber, 1000);
  int offset = (pageNumber - 1) * pageSize;
  int totalRecords = 0;
  int totalPages = 1;
  String error = null;
  List<Map<String, Object>> records = new ArrayList<Map<String, Object>>();
  List<Map<String, Object>> screeningSchedule = new ArrayList<Map<String, Object>>();
  Connection connection = null;
  PreparedStatement statement = null;
  ResultSet result = null;
  try {
    String url = dbValue("gbldburl", "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
    String username = dbValue("gbldbusername", "root", request);
    String password = dbValue("gbldbpasswd", "", request);
    String driver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
    Class.forName(driver);
    connection = DriverManager.getConnection(url + (url.contains("?") ? "&" : "?") + "useSSL=false", username, password);

    if (patientId.isEmpty()) throw new SQLException("Patient ID is required.");
    statement = connection.prepareStatement("SELECT pat_id FROM med WHERE pat_id = ?");
    statement.setString(1, patientId);
    result = statement.executeQuery();
    boolean patientExists = result.next();
    result.close();
    statement.close();
    result = null;
    statement = null;
    if (!patientExists) throw new SQLException("Patient not found.");

    totalRecords = count(connection, "pobado_screening", "cr_number", patientId)
      + count(connection, "distress_thermometer", "pat_id", patientId)
      + count(connection, "phq9_screening", "pat_id", patientId)
      + count(connection, "gad7_screening", "pat_id", patientId);
    totalPages = Math.max(1, (int) Math.ceil(totalRecords / (double) pageSize));
    pageNumber = Math.min(pageNumber, totalPages);
    offset = (pageNumber - 1) * pageSize;
    int fetchLimit = offset + pageSize;

    statement = connection.prepareStatement(
      "SELECT id, screening_date, assessment_checkpoint, total_score, fatigue, mood, anxiety, depression, " +
      "limitations, social_problems, follow_up_date, recorded_at, recorded_by FROM pobado_screening " +
      "WHERE cr_number = ? ORDER BY screening_date DESC, id DESC LIMIT ?");
    statement.setString(1, patientId);
    statement.setInt(2, fetchLimit);
    result = statement.executeQuery();
    while (result.next()) {
      Map<String, Object> record = new LinkedHashMap<String, Object>();
      record.put("id", "pobado:" + result.getString("id"));
      record.put("type", "PO Bado");
      record.put("date", result.getString("screening_date"));
      record.put("checkpoint", result.getString("assessment_checkpoint"));
      record.put("score", result.getObject("total_score"));
      record.put("maximum", 24);
      record.put("interpretation", null);
      record.put("followUpDate", result.getString("follow_up_date"));
      record.put("recordedAt", result.getString("recorded_at"));
      appendResponses(record,
        new String[] { "Fatigue", "Mood", "Anxiety", "Depression", "Limitations", "Social problems" },
        new Object[] { result.getObject("fatigue"), result.getObject("mood"), result.getObject("anxiety"),
          result.getObject("depression"), result.getObject("limitations"), result.getObject("social_problems") });
      records.add(record);
    }
    result.close();
    statement.close();
    result = null;
    statement = null;

    statement = connection.prepareStatement(
      "SELECT id, screening_date, assessment_checkpoint, distress_score, recorded_at " +
      "FROM distress_thermometer WHERE pat_id = ? ORDER BY screening_date DESC, id DESC LIMIT ?");
    statement.setString(1, patientId);
    statement.setInt(2, fetchLimit);
    result = statement.executeQuery();
    while (result.next()) {
      Map<String, Object> record = new LinkedHashMap<String, Object>();
      record.put("id", result.getObject("id"));
      record.put("type", "Distress Thermometer");
      record.put("date", result.getString("screening_date"));
      record.put("checkpoint", result.getString("assessment_checkpoint"));
      record.put("score", result.getObject("distress_score"));
      record.put("maximum", 10);
      record.put("interpretation", null);
      record.put("followUpDate", null);
      record.put("recordedAt", result.getString("recorded_at"));
      appendResponses(record, new String[] { "Distress score" },
        new Object[] { result.getObject("distress_score") });
      records.add(record);
    }
    result.close();
    statement.close();
    result = null;
    statement = null;

    statement = connection.prepareStatement(
      "SELECT id, screening_date, assessment_checkpoint, total_score, q1, q2, q3, q4, q5, q6, q7, q8, q9 " +
      "FROM phq9_screening WHERE pat_id = ? ORDER BY screening_date DESC, id DESC LIMIT ?");
    statement.setString(1, patientId);
    statement.setInt(2, fetchLimit);
    result = statement.executeQuery();
    while (result.next()) {
      Map<String, Object> record = new LinkedHashMap<String, Object>();
      record.put("id", result.getObject("id"));
      record.put("type", "PHQ-9");
      record.put("date", result.getString("screening_date"));
      record.put("checkpoint", result.getString("assessment_checkpoint"));
      record.put("score", result.getObject("total_score"));
      record.put("maximum", 27);
      record.put("interpretation", null);
      record.put("followUpDate", null);
      appendResponses(record,
        new String[] { "Question 1", "Question 2", "Question 3", "Question 4", "Question 5", "Question 6", "Question 7", "Question 8", "Question 9" },
        new Object[] { result.getObject("q1"), result.getObject("q2"), result.getObject("q3"), result.getObject("q4"),
          result.getObject("q5"), result.getObject("q6"), result.getObject("q7"), result.getObject("q8"),
          result.getObject("q9") });
      records.add(record);
    }
    result.close();
    statement.close();
    result = null;
    statement = null;

    statement = connection.prepareStatement(
      "SELECT id, screening_date, assessment_checkpoint, total_score, anxiety_category, q1, q2, q3, q4, q5, q6, q7 " +
      "FROM gad7_screening WHERE pat_id = ? ORDER BY screening_date DESC, id DESC LIMIT ?");
    statement.setString(1, patientId);
    statement.setInt(2, fetchLimit);
    result = statement.executeQuery();
    while (result.next()) {
      Map<String, Object> record = new LinkedHashMap<String, Object>();
      record.put("id", result.getObject("id"));
      record.put("type", "GAD-7");
      record.put("date", result.getString("screening_date"));
      record.put("checkpoint", result.getString("assessment_checkpoint"));
      record.put("score", result.getObject("total_score"));
      record.put("maximum", 21);
      record.put("interpretation", result.getString("anxiety_category"));
      record.put("followUpDate", null);
      appendResponses(record,
        new String[] { "Question 1", "Question 2", "Question 3", "Question 4", "Question 5", "Question 6", "Question 7" },
        new Object[] { result.getObject("q1"), result.getObject("q2"), result.getObject("q3"), result.getObject("q4"),
          result.getObject("q5"), result.getObject("q6"), result.getObject("q7") });
      records.add(record);
    }
    result.close();
    statement.close();
    result = null;
    statement = null;

    screeningSchedule.add(scheduleItem(
      connection, patientId, "PO Bado", "pobado_screening", "cr_number", true));
    screeningSchedule.add(scheduleItem(
      connection, patientId, "Distress Thermometer", "distress_thermometer", "pat_id", false));
    screeningSchedule.add(scheduleItem(
      connection, patientId, "PHQ-9", "phq9_screening", "pat_id", false));
    screeningSchedule.add(scheduleItem(
      connection, patientId, "GAD-7", "gad7_screening", "pat_id", false));

    Collections.sort(records, new Comparator<Map<String, Object>>() {
      public int compare(Map<String, Object> left, Map<String, Object> right) {
        int byDate = Objects.toString(right.get("date"), "").compareTo(Objects.toString(left.get("date"), ""));
        if (byDate != 0) return byDate;
        return Objects.toString(right.get("recordedAt"), "").compareTo(Objects.toString(left.get("recordedAt"), ""));
      }
    });

    for (int i = offset; i < Math.min(offset + pageSize, records.size()); i++) {
      Map<String, Object> record = records.get(i);
      if (!"Distress Thermometer".equals(record.get("type"))) continue;
      PreparedStatement concernStatement = connection.prepareStatement(
        "SELECT category, concern FROM distress_thermometer_problem WHERE screening_id = ? ORDER BY id");
      try {
        concernStatement.setObject(1, record.get("id"));
        ResultSet concernResult = concernStatement.executeQuery();
        List<Map<String, Object>> concerns = new ArrayList<Map<String, Object>>();
        try {
          while (concernResult.next()) {
            Map<String, Object> concern = new LinkedHashMap<String, Object>();
            concern.put("category", concernResult.getString("category"));
            concern.put("concern", concernResult.getString("concern"));
            concerns.add(concern);
          }
        } finally { concernResult.close(); }
        record.put("concerns", concerns);
      } finally { concernStatement.close(); }
    }
  } catch (Exception exception) {
    error = exception.getMessage() != null && exception.getMessage().contains("required")
      ? "Patient ID is required."
      : exception.getMessage() != null && exception.getMessage().contains("not found")
        ? "Patient not found."
        : "Unable to load screening history.";
  } finally {
    if (result != null) try { result.close(); } catch (SQLException ignored) { }
    if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
    if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Patient Screening History</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <style>
    :root { color-scheme: light; --ink: #18384b; --muted: #526877; --line: #d8e5eb; --brand: #247a9b; --deep-brand: #164763; --brand-soft: #e2f0f5; --page: #eef5f8; --surface: #fff; }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 28px; background: var(--page); color: var(--ink); font-family: Inter, "Segoe UI", Arial, sans-serif; }
    .history-shell { max-width: 1120px; margin: 0 auto; }
    .history-hero { position: relative; overflow: hidden; display: flex; justify-content: space-between; align-items: flex-start; gap: 24px; padding: 28px 32px; margin-bottom: 20px; color: #fff; background: linear-gradient(120deg, var(--deep-brand), var(--brand)); border-radius: 20px; box-shadow: 0 14px 32px rgba(22, 71, 99, .16); }
    .history-hero:after { position: absolute; right: -54px; bottom: -132px; width: 290px; height: 290px; border: 1px solid rgba(255,255,255,.14); border-radius: 50%; content: ""; box-shadow: 0 0 0 32px rgba(255,255,255,.035), 0 0 0 68px rgba(255,255,255,.025); pointer-events: none; }
    .hero-copy { position: relative; z-index: 1; }
    .eyebrow { margin: 0 0 8px; color: #d5ebf2; font-size: 11px; font-weight: 700; letter-spacing: 1.5px; }
    .history-hero h1 { margin: 0; font-size: clamp(25px, 4vw, 34px); font-weight: 700; letter-spacing: -.5px; }
    .patient-id { display: inline-flex; align-items: center; gap: 8px; margin-top: 14px; padding: 7px 11px; color: #eff8ff; background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.16); border-radius: 30px; font-size: 13px; }
    .back-link, .page-link, .filter-button { display: inline-flex; align-items: center; justify-content: center; min-height: 40px; padding: 9px 14px; border: 1px solid var(--line); border-radius: 9px; color: var(--ink); background: #fff; text-decoration: none; font-size: 13px; font-weight: 600; transition: background .15s, border-color .15s, transform .15s; cursor: pointer; }
    .back-link { position: relative; z-index: 1; border-color: rgba(255,255,255,.45); color: #fff; background: rgba(255,255,255,.08); }
    .back-link:hover { color: #fff; background: rgba(255,255,255,.16); }
    .page-link:hover, .filter-button:hover { border-color: #a9c8d4; background: #f5fafc; }
    .summary-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-bottom: 28px; }
    .summary-card { display: flex; align-items: center; gap: 13px; min-height: 88px; padding: 17px; background: var(--surface); border: 1px solid var(--line); border-radius: 14px; box-shadow: 0 4px 14px rgba(31, 62, 82, .035); }
    .summary-icon { display: grid; flex: 0 0 42px; width: 42px; height: 42px; place-items: center; color: var(--brand); background: var(--brand-soft); border-radius: 12px; font-size: 19px; font-weight: 700; }
    .summary-label { display: block; margin-bottom: 4px; color: var(--muted); font-size: 11px; font-weight: 700; letter-spacing: .55px; text-transform: uppercase; }
    .summary-value { color: var(--ink); font-size: 16px; font-weight: 700; overflow-wrap: anywhere; }
    .section-heading { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; margin: 0 0 14px; }
    .section-heading h2 { margin: 0; font-size: 20px; font-weight: 700; letter-spacing: -.2px; }
    .section-heading p { margin: 5px 0 0; color: var(--muted); font-size: 13px; }
    .schedule-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
    .schedule-card { min-width: 0; padding: 18px; background: var(--surface); border: 1px solid var(--line); border-top: 3px solid #5595a5; border-radius: 14px; box-shadow: 0 5px 16px rgba(31, 62, 82, .04); }
    .schedule-card.is-overdue { border-top-color: #d88768; }
    .schedule-card.is-neutral { border-top-color: #9aaab6; }
    .schedule-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; }
    .schedule-card h3 { margin: 0; color: var(--ink); font-size: 16px; font-weight: 700; }
    .schedule-caption { margin: 4px 0 0; color: var(--muted); font-size: 12px; }
    .schedule-state { flex: 0 0 auto; padding: 6px 9px; color: #235e68; background: #e4f2f1; border-radius: 20px; font-size: 11px; font-weight: 700; }
    .is-overdue .schedule-state { color: #8d452f; background: #fff0e9; }
    .is-neutral .schedule-state { color: #586b78; background: #edf2f5; }
    .schedule-date { margin: 18px 0 12px; }
    .schedule-date-label { display: block; margin-bottom: 3px; color: var(--muted); font-size: 11px; font-weight: 700; letter-spacing: .4px; text-transform: uppercase; }
    .schedule-date-value { font-size: 20px; font-weight: 700; letter-spacing: -.3px; }
    .schedule-date-value.is-unset { color: #738392; font-size: 15px; font-weight: 600; letter-spacing: 0; }
    .schedule-countdown { display: flex; align-items: center; gap: 8px; padding: 10px 12px; color: #235e68; background: #f0f7f9; border-radius: 9px; font-size: 13px; font-weight: 600; }
    .is-overdue .schedule-countdown { color: #8d452f; background: #fff5f0; }
    .is-neutral .schedule-countdown { color: #586b78; background: #f2f5f7; }
    .schedule-details { display: flex; flex-wrap: wrap; gap: 7px 18px; margin-top: 12px; color: var(--muted); font-size: 12px; }
    .schedule-details strong { color: #40586b; font-weight: 600; }
    .history-section { margin-top: 30px; }
    .filters { display: flex; flex-wrap: wrap; align-items: end; gap: 12px; margin: 0 0 12px; padding: 16px; background: var(--surface); border: 1px solid var(--line); border-radius: 14px; }
    .filter-field { display: grid; gap: 6px; }
    .filter-field label { color: #4a6274; font-size: 11px; font-weight: 700; letter-spacing: .3px; }
    .filters select, .filters input { min-width: 150px; min-height: 40px; padding: 8px 10px; color: var(--ink); background: #fff; border: 1px solid #cadbe3; border-radius: 8px; font: inherit; font-size: 13px; }
    .filter-button.primary { color: #fff; background: var(--brand); border-color: var(--brand); }
    .filter-button.primary:hover { background: #1e657f; }
    .records-count { margin: 13px 2px; color: var(--muted); font-size: 12px; }
    .screening-card { margin-bottom: 10px; padding: 0; background: var(--surface); border: 1px solid var(--line); border-radius: 13px; box-shadow: 0 4px 13px rgba(31, 62, 82, .035); }
    .screening-card[hidden] { display: none; }
    .screening-card summary { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 17px 18px; cursor: pointer; list-style: none; }
    .screening-card summary::-webkit-details-marker { display: none; }
    .record-heading { min-width: 0; }
    .record-title { margin: 0; color: var(--ink); font-size: 15px; font-weight: 700; }
    .record-subtitle { margin-top: 5px; color: var(--muted); font-size: 12px; }
    .record-summary-right { display: flex; flex: 0 0 auto; align-items: center; gap: 12px; }
    .score-pill { padding: 7px 10px; color: #235e68; background: #e4f2f1; border-radius: 8px; font-size: 12px; font-weight: 700; }
    .record-state { padding: 6px 9px; color: #356b78; background: #eaf4f6; border-radius: 20px; font-size: 10px; font-weight: 700; text-transform: uppercase; }
    .expand-mark { color: #6f8391; font-size: 18px; transition: transform .15s; }
    details[open] .expand-mark { transform: rotate(180deg); }
    .record-details { padding: 0 18px 18px; color: #40586b; font-size: 13px; }
    .record-details p { margin: 0 0 10px; }
    .record-details h3 { margin: 15px 0 7px; color: var(--ink); font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .4px; }
    .record-details ul { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 5px 20px; margin: 0; padding-left: 18px; }
    .record-details li { margin: 2px 0; }
    .muted { color: var(--muted); }
    .error, .empty-state { padding: 18px; color: #822727; background: #fff4f1; border: 1px solid #f0d7cf; border-radius: 12px; }
    .empty-state { color: var(--muted); background: #fff; border-color: var(--line); text-align: center; }
    .pagination-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-top: 16px; padding: 14px 0; }
    @media (max-width: 760px) { body { padding: 16px; } .history-hero { padding: 22px; } .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } .summary-card:last-child { grid-column: 1 / -1; } .schedule-grid { grid-template-columns: 1fr; } }
    @media (max-width: 540px) { body { padding: 10px; } .history-hero { flex-direction: column; padding: 20px; border-radius: 15px; } .back-link { align-self: flex-start; } .summary-grid { grid-template-columns: 1fr 1fr; gap: 8px; } .summary-card { min-height: 78px; padding: 12px; gap: 9px; } .summary-icon { flex-basis: 34px; width: 34px; height: 34px; } .summary-value { font-size: 14px; } .section-heading { align-items: flex-start; flex-direction: column; } .filters { align-items: stretch; } .filter-field { flex: 1 1 42%; } .filters select, .filters input { width: 100%; min-width: 0; } .filters button { flex: 1 1 auto; } .screening-card summary { align-items: flex-start; padding: 14px; } .record-summary-right { gap: 6px; } .score-pill { padding: 6px 7px; font-size: 11px; } .record-details ul { grid-template-columns: 1fr; } .pagination-row { align-items: flex-start; flex-direction: column; } }
    @media (prefers-reduced-motion: reduce) { *, *:before, *:after { scroll-behavior: auto !important; transition-duration: .01ms !important; } }
  </style>
</head>
<body>
  <main class="history-shell">
    <header class="history-hero">
      <div class="hero-copy">
        <p class="eyebrow">PATIENT CARE · CLINICAL OVERVIEW</p>
        <h1>Screening history</h1>
        <span class="patient-id">Patient ID <strong><%= html(patientId) %></strong></span>
      </div>
      <a class="back-link" href="psychologistPatientList.jsp" onclick="return navigateAppPanel('psychologistPatientList.jsp');">Back to Patient List</a>
    </header>
    <% if (error != null) { %>
      <div class="error"><%= html(error) %></div>
    <% } else { %>
      <section class="summary-grid" aria-label="Screening summary">
        <article class="summary-card">
          <span class="summary-icon" aria-hidden="true">#</span>
          <div><span class="summary-label">Saved records</span><strong class="summary-value"><%= totalRecords %></strong></div>
        </article>
        <article class="summary-card">
          <span class="summary-icon" aria-hidden="true">↻</span>
          <div><span class="summary-label">Screening types</span><strong class="summary-value"><%= screeningSchedule.size() %> tracked</strong></div>
        </article>
        <article class="summary-card">
          <span class="summary-icon" aria-hidden="true">◷</span>
          <div><span class="summary-label">History page</span><strong class="summary-value"><%= pageNumber %> of <%= totalPages %></strong></div>
        </article>
      </section>
      <section aria-labelledby="schedule-heading">
        <div class="section-heading">
          <div>
            <h2 id="schedule-heading">Follow-up schedule</h2>
            <p>Each screening has its own next date and countdown.</p>
          </div>
        </div>
        <div class="schedule-grid">
          <% for (Map<String, Object> item : screeningSchedule) { %>
            <% String countdownText = Objects.toString(item.get("countdown"), "Schedule unavailable");
               String scheduleState = item.get("dueDate") == null ? "is-neutral"
                 : countdownText.startsWith("Due date passed") ? "is-overdue" : "is-upcoming"; %>
            <article class="schedule-card <%= scheduleState %>">
              <div class="schedule-top">
                <div>
                  <h3><%= html(item.get("screeningType")) %></h3>
                  <p class="schedule-caption"><%= html(item.get("nextCheckpoint") == null ? "Follow-up schedule" : item.get("nextCheckpoint")) %></p>
                </div>
                <span class="schedule-state"><%= item.get("dueDate") == null ? "NO DATE" : scheduleState.equals("is-overdue") ? "OVERDUE" : "UPCOMING" %></span>
              </div>
              <div class="schedule-date">
                <span class="schedule-date-label">Next follow-up date</span>
                <strong class="schedule-date-value <%= item.get("dueDate") == null ? "is-unset" : "" %>"><%= item.get("dueDate") == null ? "Not scheduled" : html(item.get("dueDate")) %></strong>
              </div>
              <div class="schedule-countdown"><span aria-hidden="true">◷</span><%= html(countdownText) %></div>
              <div class="schedule-details">
                <% if (item.get("baselineDate") != null) { %><span>Baseline <strong><%= html(item.get("baselineDate")) %></strong></span><% } %>
                <% if (item.get("lastCompletedCheckpoint") != null) { %><span>Last completed <strong><%= html(item.get("lastCompletedCheckpoint")) %></strong></span><% } %>
              </div>
            </article>
          <% } %>
        </div>
      </section>
      <section class="history-section" aria-labelledby="records-heading">
        <div class="section-heading">
          <div>
            <h2 id="records-heading">Screening records</h2>
            <p>Review completed assessments, scores and recorded answers.</p>
          </div>
        </div>
        <div class="filters" aria-label="Filter screening records">
          <div class="filter-field">
            <label for="type-filter">SCREENING TYPE</label>
            <select id="type-filter">
              <option value="">All screening types</option>
              <option>PO Bado</option><option>Distress Thermometer</option><option>PHQ-9</option><option>GAD-7</option>
            </select>
          </div>
          <div class="filter-field"><label for="from-date">FROM DATE</label><input id="from-date" type="date"></div>
          <div class="filter-field"><label for="to-date">TO DATE</label><input id="to-date" type="date"></div>
          <button class="filter-button primary" type="button" onclick="applyFilters()">Apply filters</button>
          <button class="filter-button" type="button" onclick="clearFilters()">Clear</button>
        </div>
        <p class="records-count">Showing <%= Math.min(pageSize, Math.max(0, totalRecords - offset)) %> of <%= totalRecords %> saved screening records</p>
        <div id="screening-records">
        <% for (int i = offset; i < Math.min(offset + pageSize, records.size()); i++) {
             Map<String, Object> record = records.get(i);
             List<Map<String, Object>> responses = (List<Map<String, Object>>) record.get("responses");
             List<Map<String, Object>> concerns = (List<Map<String, Object>>) record.get("concerns");
        %>
          <details class="screening-card" data-type="<%= html(record.get("type")) %>" data-date="<%= html(record.get("date")) %>">
            <summary>
              <div class="record-heading">
                <h3 class="record-title"><%= html(record.get("type")) %></h3>
                <div class="record-subtitle"><%= html(record.get("date")) %> · <%= html(record.get("checkpoint") == null ? "Checkpoint not recorded" : record.get("checkpoint")) %></div>
              </div>
              <div class="record-summary-right">
                <span class="record-state">Completed</span>
                <span class="score-pill"><%= record.get("score") == null ? "Score unavailable" : html(record.get("score")) + " / " + html(record.get("maximum")) %></span>
                <span class="expand-mark" aria-hidden="true">⌄</span>
              </div>
            </summary>
            <div class="record-details">
              <% if (record.get("interpretation") != null) { %>
                <p><strong>Recorded interpretation:</strong> <%= html(record.get("interpretation")) %></p>
              <% } %>
              <h3>Recorded responses</h3>
              <ul>
                <% for (Map<String, Object> answer : responses) { %>
                  <li><%= html(answer.get("label")) %>: <%= html(answer.get("value")) %></li>
                <% } %>
              </ul>
              <% if (concerns != null && !concerns.isEmpty()) { %>
                <h3>Recorded concerns</h3>
                <ul>
                  <% for (Map<String, Object> concern : concerns) { %>
                    <li><%= html(concern.get("category")) %>: <%= html(concern.get("concern")) %></li>
                  <% } %>
                </ul>
              <% } %>
            </div>
          </details>
        <% } %>
        <% if (records.isEmpty()) { %><div class="empty-state">No screening records are available for this patient.</div><% } %>
        </div>
      <nav class="pagination-row" aria-label="Screening history pages">
        <span class="muted">Page <%= pageNumber %> of <%= totalPages %></span>
        <span>
          <% if (pageNumber > 1) { %><a class="page-link" href="patientScreeningReport.jsp?pat_id=<%= java.net.URLEncoder.encode(patientId, "UTF-8") %>&amp;page=<%= pageNumber - 1 %>" onclick="return navigateAppPanel('patientScreeningReport.jsp?pat_id=<%= java.net.URLEncoder.encode(patientId, "UTF-8") %>&page=<%= pageNumber - 1 %>');">Previous</a><% } %>
          <% if (pageNumber < totalPages) { %><a class="page-link" href="patientScreeningReport.jsp?pat_id=<%= java.net.URLEncoder.encode(patientId, "UTF-8") %>&amp;page=<%= pageNumber + 1 %>" onclick="return navigateAppPanel('patientScreeningReport.jsp?pat_id=<%= java.net.URLEncoder.encode(patientId, "UTF-8") %>&page=<%= pageNumber + 1 %>');">Next</a><% } %>
        </span>
      </nav>
      </section>
    <% } %>
  </main>
  <script>
    function navigateAppPanel(fileName) {
      if (window.parent !== window && typeof window.parent.clearPanel === 'function') {
        window.parent.clearPanel(fileName);
        return false;
      }
      if (typeof window.clearPanel === 'function') {
        window.clearPanel(fileName);
        return false;
      }
      return true;
    }

    function applyFilters() {
      var type = document.getElementById('type-filter').value;
      var from = document.getElementById('from-date').value;
      var to = document.getElementById('to-date').value;
      document.querySelectorAll('#screening-records .screening-card').forEach(function (card) {
        var matchesType = !type || card.dataset.type === type;
        var matchesFrom = !from || card.dataset.date >= from;
        var matchesTo = !to || card.dataset.date <= to;
        card.hidden = !(matchesType && matchesFrom && matchesTo);
      });
    }
    function clearFilters() {
      document.getElementById('type-filter').value = '';
      document.getElementById('from-date').value = '';
      document.getElementById('to-date').value = '';
      applyFilters();
    }
  </script>
</body>
</html>
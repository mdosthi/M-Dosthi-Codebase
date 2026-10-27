<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,imedix.rcPatqueueInfo,imedix.dataobj,java.sql.*,java.io.*,java.net.*,java.util.Vector" %>
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

  private String text(HttpServletRequest request, String name) {
    String value = request.getParameter(name);
    return value == null || value.trim().isEmpty() ? null : value.trim();
  }

  private int score(HttpServletRequest request, String name) {
    String value = text(request, name);
    if (value == null) throw new IllegalArgumentException("All seven GAD-7 questions are required");
    try {
      int score = Integer.parseInt(value);
      if (score < 0 || score > 3) throw new IllegalArgumentException("Invalid GAD-7 answer");
      return score;
    } catch (NumberFormatException exception) {
      throw new IllegalArgumentException("Invalid GAD-7 answer");
    }
  }

  private String anxietyCategory(int total) {
    if (total <= 4) return "Minimal anxiety";
    if (total <= 9) return "Mild anxiety";
    if (total <= 14) return "Moderate anxiety";
    return "Severe anxiety";
  }

  private String nextPendingPatientId(HttpServletRequest request, String currentPatientId) {
    try {
      cook cookx = new cook();
      String center = cookx.getCookieValue("center", request.getCookies());
      rcPatqueueInfo patientQueue = new rcPatqueueInfo(request.getRealPath("/"));
      int total = Integer.parseInt(patientQueue.getTotalLPatAdmin2(center));
      Object queue = patientQueue.getLPatqueueAdmin(center, 0, total);
      if (!(queue instanceof Vector)) return null;
      Vector queuePatients = (Vector) queue;
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
        statement = connection.prepareStatement("SELECT COUNT(*) FROM gad7_screening WHERE pat_id=?");
        for (int index = 0; index < queuePatients.size(); index++) {
          dataobj patient = (dataobj) queuePatients.get(index);
          String patientId = patient.getValue("pat_id");
          if (patientId == null || patientId.equals(currentPatientId)) continue;
          statement.setString(1, patientId);
          result = statement.executeQuery();
          if (result.next() && result.getInt(1) == 0) return patientId;
          result.close();
          result = null;
        }
      } finally {
        if (result != null) try { result.close(); } catch (SQLException ignored) { }
        if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
        if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
      }
    } catch (Exception ignored) {
    }
    return null;
  }
%>
<%
  if (!"POST".equalsIgnoreCase(request.getMethod())) {
    response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
    return;
  }

  String patientId = text(request, "pat_id");
  String assessmentCheckpoint = text(request, "assessment_checkpoint");
  if (assessmentCheckpoint == null) assessmentCheckpoint = "Baseline Assessment";
  String patientName = text(request, "patient_name");
  String screeningDate = text(request, "screening_date");
  String actor = new cook().getCookieValue("userid", request.getCookies());
  String role = new cook().getCookieValue("usertype", request.getCookies());
  String redirect = "gad7Screening.jsp?pat_id=" + URLEncoder.encode(patientId == null ? "" : patientId, "UTF-8") + "&checkpoint=" + URLEncoder.encode(assessmentCheckpoint, "UTF-8");
  Connection connection = null;
  PreparedStatement statement = null;
  try {
    if (patientId == null || screeningDate == null) throw new IllegalArgumentException("Patient ID and screening date are required");
    if (!assessmentCheckpoint.matches("Baseline Assessment|4 week Assessment|8 week Assessment|12 week Assessment")) throw new IllegalArgumentException("Invalid assessment checkpoint");
    if (actor == null || role == null) throw new SecurityException("Unauthenticated user");
    if (!"adm".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) throw new SecurityException("Role is not allowed");

    int[] itemScores = new int[7];
    int total = 0;
    for (int index = 0; index < itemScores.length; index++) {
      itemScores[index] = score(request, "q" + (index + 1));
      total += itemScores[index];
    }
    java.sql.Date sqlDate = java.sql.Date.valueOf(screeningDate);

    String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi?useUnicode=true&characterEncoding=UTF-8", request);
    String dbUser = dbValue("gbldbusername", "root", request);
    String dbPassword = dbValue("gbldbpasswd", "", request);
    String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
    Class.forName(dbDriver);
    connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);
    statement = connection.prepareStatement("SELECT COUNT(*) FROM med WHERE pat_id=?");
    statement.setString(1, patientId);
    ResultSet patient = statement.executeQuery();
    if (!patient.next() || patient.getInt(1) == 0) throw new IllegalArgumentException("Patient not found");
    patient.close();
    statement.close();
    statement = null;

    statement = connection.prepareStatement("INSERT INTO gad7_screening (pat_id, assessment_checkpoint, patient_name, screening_date, q1, q2, q3, q4, q5, q6, q7, total_score, anxiety_category, recorded_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    int parameter = 1;
    statement.setString(parameter++, patientId);
    statement.setString(parameter++, assessmentCheckpoint);
    statement.setString(parameter++, patientName == null ? "" : patientName);
    statement.setDate(parameter++, sqlDate);
    for (int itemScore : itemScores) statement.setInt(parameter++, itemScore);
    statement.setInt(parameter++, total);
    statement.setString(parameter++, anxietyCategory(total));
    statement.setString(parameter, actor);
    statement.executeUpdate();
    statement.close();
    statement = null;

    redirect += "&saved=1";
  } catch (Exception exception) {
    redirect += "&error=" + URLEncoder.encode(exception.getMessage() == null ? "Unable to save GAD-7 screening" : exception.getMessage(), "UTF-8");
  } finally {
    if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
    if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
  }
  response.sendRedirect(redirect);
%>

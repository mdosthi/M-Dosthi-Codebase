<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.sql.*,java.io.*,java.net.URLEncoder" %>
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

  private String[] problemDetails(String problemId) {
    switch (problemId) {
      case "pain": return new String[] {"Physical Concerns", "Pain"};
      case "sleep": return new String[] {"Physical Concerns", "Sleep"};
      case "fatigue": return new String[] {"Physical Concerns", "Fatigue"};
      case "tobacco_use": return new String[] {"Physical Concerns", "Tobacco use"};
      case "substance_use": return new String[] {"Physical Concerns", "Substance use"};
      case "memory_concentration": return new String[] {"Physical Concerns", "Memory or concentration"};
      case "sexual_health": return new String[] {"Physical Concerns", "Sexual health"};
      case "changes_eating": return new String[] {"Physical Concerns", "Changes in eating"};
      case "physical_abilities": return new String[] {"Physical Concerns", "Loss or change of physical abilities"};
      case "care_self": return new String[] {"Practical Concerns", "Taking care of myself"};
      case "care_others": return new String[] {"Practical Concerns", "Taking care of others"};
      case "safety": return new String[] {"Practical Concerns", "Safety"};
      case "work": return new String[] {"Practical Concerns", "Work"};
      case "school": return new String[] {"Practical Concerns", "School"};
      case "housing_utilities": return new String[] {"Practical Concerns", "Housing/Utilities"};
      case "finances": return new String[] {"Practical Concerns", "Finances"};
      case "insurance": return new String[] {"Practical Concerns", "Insurance"};
      case "transportation": return new String[] {"Practical Concerns", "Transportation"};
      case "child_care": return new String[] {"Practical Concerns", "Child care"};
      case "enough_food": return new String[] {"Practical Concerns", "Having enough food"};
      case "access_medicine": return new String[] {"Practical Concerns", "Access to medicine"};
      case "treatment_decisions": return new String[] {"Practical Concerns", "Treatment decisions"};
      case "worry_anxiety": return new String[] {"Emotional Concerns", "Worry or anxiety"};
      case "sadness_depression": return new String[] {"Emotional Concerns", "Sadness or depression"};
      case "loss_interest": return new String[] {"Emotional Concerns", "Loss of interest or enjoyment"};
      case "grief_loss": return new String[] {"Emotional Concerns", "Grief or loss"};
      case "fear": return new String[] {"Emotional Concerns", "Fear"};
      case "loneliness": return new String[] {"Emotional Concerns", "Loneliness"};
      case "anger": return new String[] {"Emotional Concerns", "Anger"};
      case "changes_appearance": return new String[] {"Emotional Concerns", "Changes in appearance"};
      case "worthlessness_burden": return new String[] {"Emotional Concerns", "Feelings of worthlessness or being a burden"};
      case "meaning_purpose": return new String[] {"Spiritual or Religious Concerns", "Sense of meaning or purpose"};
      case "faith_beliefs": return new String[] {"Spiritual or Religious Concerns", "Changes in faith or beliefs"};
      case "death_afterlife": return new String[] {"Spiritual or Religious Concerns", "Death, dying, or afterlife"};
      case "beliefs_treatment_conflict": return new String[] {"Spiritual or Religious Concerns", "Conflict between beliefs and cancer treatments"};
      case "sacred_relationship": return new String[] {"Spiritual or Religious Concerns", "Relationship with the sacred"};
      case "ritual_dietary": return new String[] {"Spiritual or Religious Concerns", "Ritual or dietary needs"};
      case "relationship_partner": return new String[] {"Social Concerns", "Relationship with spouse or partner"};
      case "relationship_children": return new String[] {"Social Concerns", "Relationship with children"};
      case "relationship_family": return new String[] {"Social Concerns", "Relationship with family members"};
      case "relationship_friends": return new String[] {"Social Concerns", "Relationship with friends or coworkers"};
      case "healthcare_communication": return new String[] {"Social Concerns", "Communication with health care team"};
      case "ability_have_children": return new String[] {"Social Concerns", "Ability to have children"};
      case "prejudice_discrimination": return new String[] {"Social Concerns", "Prejudice or discrimination"};
      default: throw new IllegalArgumentException("Invalid problem-list selection");
    }
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
  String screeningDate = text(request, "screening_date");
  String[] selectedProblems = request.getParameterValues("problem_id");
  String actor = new cook().getCookieValue("userid", request.getCookies());
  String role = new cook().getCookieValue("usertype", request.getCookies());
  String pageUrl = "distressThermometerScreening.jsp?pat_id=" + URLEncoder.encode(patientId == null ? "" : patientId, "UTF-8") + "&checkpoint=" + URLEncoder.encode(assessmentCheckpoint, "UTF-8");
  Connection connection = null;
  PreparedStatement statement = null;
  try {
    if (patientId == null || screeningDate == null) throw new IllegalArgumentException("Patient and screening date are required");
    if (!assessmentCheckpoint.matches("Baseline Assessment|4 week Assessment|8 week Assessment|12 week Assessment")) throw new IllegalArgumentException("Invalid assessment checkpoint");
    if (actor == null || role == null) throw new SecurityException("Unauthenticated user");
    if (!"adm".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) throw new SecurityException("Role is not allowed");

    int score;
    try {
      score = Integer.parseInt(text(request, "distress_score"));
    } catch (Exception invalidScore) {
      throw new IllegalArgumentException("Select a distress score from 0 to 10");
    }
    if (score < 0 || score > 10) throw new IllegalArgumentException("Select a distress score from 0 to 10");
    java.sql.Date sqlDate = java.sql.Date.valueOf(screeningDate);

    String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi_merged?useUnicode=true&characterEncoding=UTF-8", request);
    String dbUser = dbValue("gbldbusername", "root", request);
    String dbPassword = dbValue("gbldbpasswd", "", request);
    String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
    Class.forName(dbDriver);
    connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);
    connection.setAutoCommit(false);

    statement = connection.prepareStatement("SELECT COUNT(*) FROM med WHERE pat_id=?");
    statement.setString(1, patientId);
    ResultSet patient = statement.executeQuery();
    if (!patient.next() || patient.getInt(1) == 0) throw new IllegalArgumentException("Patient not found");
    patient.close();
    statement.close();
    statement = null;

    statement = connection.prepareStatement("INSERT INTO distress_thermometer (pat_id, assessment_checkpoint, distress_score, screening_date, recorded_by) VALUES (?, ?, ?, ?, ?)", Statement.RETURN_GENERATED_KEYS);
    statement.setString(1, patientId);
    statement.setString(2, assessmentCheckpoint);
    statement.setInt(3, score);
    statement.setDate(4, sqlDate);
    statement.setString(5, actor);
    statement.executeUpdate();
    ResultSet insertedScreening = statement.getGeneratedKeys();
    if (!insertedScreening.next()) throw new SQLException("Unable to retrieve screening record ID");
    long screeningId = insertedScreening.getLong(1);
    insertedScreening.close();
    statement.close();
    statement = null;

    boolean hasSelectedProblem = selectedProblems != null && selectedProblems.length > 0;
    for (int otherIndex = 1; otherIndex <= 3; otherIndex++) {
      if ("1".equals(text(request, "other_concern_selected_" + otherIndex))) hasSelectedProblem = true;
    }
    if (hasSelectedProblem) {
      statement = connection.prepareStatement("INSERT INTO distress_thermometer_problem (screening_id, category, concern) VALUES (?, ?, ?)");
      if (selectedProblems != null) {
        for (String problemId : selectedProblems) {
          String[] details = problemDetails(problemId);
          statement.setLong(1, screeningId);
          statement.setString(2, details[0]);
          statement.setString(3, details[1]);
          statement.addBatch();
        }
      }
      for (int otherIndex = 1; otherIndex <= 3; otherIndex++) {
        if ("1".equals(text(request, "other_concern_selected_" + otherIndex))) {
          String otherConcern = text(request, "other_concern_" + otherIndex);
          if (otherConcern == null) throw new IllegalArgumentException("Enter each checked other concern");
          if (otherConcern.length() > 100) throw new IllegalArgumentException("Other concerns must be 100 characters or fewer");
          statement.setLong(1, screeningId);
          statement.setString(2, "Other Concerns");
          statement.setString(3, otherConcern);
          statement.addBatch();
        }
      }
      statement.executeBatch();
      statement.close();
      statement = null;
    }

    statement = connection.prepareStatement("UPDATE med SET distress_bit=? WHERE pat_id=?");
    statement.setBoolean(1, score > 4);
    statement.setString(2, patientId);
    statement.executeUpdate();
    statement.close();
    statement = null;

    connection.commit();
    pageUrl += "&saved=1";
  } catch (Exception exception) {
    if (connection != null) try { connection.rollback(); } catch (SQLException ignored) { }
    pageUrl += "&error=" + URLEncoder.encode(exception.getMessage() == null ? "Unable to save screening" : exception.getMessage(), "UTF-8");
  } finally {
    if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
    if (connection != null) try { connection.setAutoCommit(true); connection.close(); } catch (SQLException ignored) { }
  }
  response.sendRedirect(pageUrl);
%>

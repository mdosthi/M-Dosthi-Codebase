<%@page contentType="text/html" pageEncoding="UTF-8" import="imedix.cook,java.io.*,java.sql.*,java.util.*"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
  private String jsonString(String value) {
    if (value == null) return "\"\"";
    StringBuilder out = new StringBuilder("\"");
    for (int i = 0; i < value.length(); i++) {
      char c = value.charAt(i);
      switch (c) {
        case '"': out.append("\\\""); break;
        case '\\': out.append("\\\\"); break;
        case '\n': out.append("\\n"); break;
        case '\r': out.append("\\r"); break;
        case '\t': out.append("\\t"); break;
        default:
          if (c < 0x20) out.append(String.format("\\u%04x", (int) c)); else out.append(c);
      }
    }
    return out.append('"').toString();
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

  private String trimmed(String value) {
    return value == null ? "" : value.trim();
  }

  private String day(String value) {
    return value != null && value.length() >= 10 ? value.substring(0, 10) : (value == null ? "" : value);
  }
%>
<%
  cook apiCook = new cook();
  String role = apiCook.getCookieValue("usertype", request.getCookies());
  String userId = apiCook.getCookieValue("userid", request.getCookies());
  String op = trimmed(request.getParameter("op"));
  String patientId = trimmed(request.getParameter("patientId"));
  int status = 200;
  String body = null;
  boolean isWrite = op.startsWith("create");

  if (!"doc".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) {
    status = 403;
    body = "{\"message\":\"Not allowed\"}";
  } else if (patientId.isEmpty()) {
    status = 400;
    body = "{\"message\":\"Patient ID is required\"}";
  } else if (isWrite && !"POST".equalsIgnoreCase(request.getMethod())) {
    status = 405;
    body = "{\"message\":\"POST required\"}";
  }

  Connection connection = null;
  PreparedStatement statement = null;
  ResultSet result = null;
  if (body == null) {
    try {
      String url = monitoringDbValue("gbldburl", "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
      Class.forName(monitoringDbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request));
      connection = DriverManager.getConnection(url + (url.contains("?") ? "&" : "?") + "useSSL=false",
          monitoringDbValue("gbldbusername", "root", request), monitoringDbValue("gbldbpasswd", "", request));

      boolean allowed;
      if ("doc".equalsIgnoreCase(role)) {
        statement = connection.prepareStatement("SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) " +
            "WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'");
        statement.setString(1, patientId);
        statement.setString(2, userId == null ? "" : userId);
      } else {
        statement = connection.prepareStatement("SELECT COUNT(*) FROM med WHERE pat_id=?");
        statement.setString(1, patientId);
      }
      result = statement.executeQuery();
      allowed = result.next() && result.getInt(1) > 0;
      result.close();
      statement.close();
      result = null;
      statement = null;

      if (!allowed) {
        status = 403;
        body = "{\"message\":\"Patient not found or not assigned to you\"}";
      } else if ("summary".equals(op)) {
        statement = connection.prepareStatement("SELECT new_therapy FROM patient_therapy_change WHERE pat_id=? ORDER BY change_date DESC, id DESC LIMIT 1");
        statement.setString(1, patientId);
        result = statement.executeQuery();
        String currentTherapy = result.next() ? result.getString(1) : "";
        result.close();
        statement.close();
        statement = connection.prepareStatement("SELECT distress_score, screening_date FROM distress_thermometer WHERE pat_id=? ORDER BY id DESC LIMIT 1");
        statement.setString(1, patientId);
        result = statement.executeQuery();
        String distress = "null";
        if (result.next()) {
          int score = result.getInt("distress_score");
          distress = "{\"status\":" + jsonString(score > 4 ? "High" : "Low") + ",\"score\":" + score +
              ",\"assessmentDate\":" + jsonString(day(result.getString("screening_date"))) +
              ",\"physicalMeetingRecommended\":" + (score > 4) + "}";
        }
        body = "{\"currentTherapy\":" + jsonString(currentTherapy) + ",\"distress\":" + distress + "}";
      } else if ("therapyHistory".equals(op)) {
        statement = connection.prepareStatement("SELECT previous_therapy, new_therapy, reason, change_date FROM patient_therapy_change WHERE pat_id=? ORDER BY change_date DESC, id DESC LIMIT 100");
        statement.setString(1, patientId);
        result = statement.executeQuery();
        StringBuilder rows = new StringBuilder();
        while (result.next()) {
          if (rows.length() > 0) rows.append(',');
          rows.append("{\"dateOfChange\":").append(jsonString(day(result.getString("change_date"))))
              .append(",\"previousTherapy\":").append(jsonString(result.getString("previous_therapy")))
              .append(",\"newTherapy\":").append(jsonString(result.getString("new_therapy")))
              .append(",\"reason\":").append(jsonString(result.getString("reason"))).append('}');
        }
        body = "{\"records\":[" + rows + "]}";
      } else if ("metastasisHistory".equals(op)) {
        statement = connection.prepareStatement("SELECT state, notes, recorded_at FROM patient_metastasis_state WHERE pat_id=? ORDER BY id DESC LIMIT 100");
        statement.setString(1, patientId);
        result = statement.executeQuery();
        StringBuilder rows = new StringBuilder();
        while (result.next()) {
          if (rows.length() > 0) rows.append(',');
          rows.append("{\"recordedAt\":").append(jsonString(day(result.getString("recorded_at"))))
              .append(",\"state\":").append(jsonString(result.getString("state")))
              .append(",\"notes\":").append(jsonString(result.getString("notes"))).append('}');
        }
        body = "{\"records\":[" + rows + "]}";
      } else if ("createTherapy".equals(op)) {
        String newTherapy = trimmed(request.getParameter("newTherapy"));
        String previousTherapy = trimmed(request.getParameter("previousTherapy"));
        String reason = trimmed(request.getParameter("reason"));
        String changeDate = trimmed(request.getParameter("dateOfChange"));
        if (newTherapy.isEmpty() || newTherapy.length() > 255 || previousTherapy.length() > 255 || reason.length() > 1000 || !changeDate.matches("\\d{4}-\\d{2}-\\d{2}")) {
          status = 400;
          body = "{\"message\":\"Invalid therapy details\"}";
        } else {
          statement = connection.prepareStatement("INSERT INTO patient_therapy_change (pat_id, previous_therapy, new_therapy, reason, change_date, recorded_by) VALUES (?,?,?,?,?,?)");
          statement.setString(1, patientId);
          statement.setString(2, previousTherapy);
          statement.setString(3, newTherapy);
          statement.setString(4, reason);
          statement.setDate(5, java.sql.Date.valueOf(changeDate));
          statement.setString(6, userId);
          statement.executeUpdate();
          body = "{\"status\":\"success\"}";
        }
      } else if ("createMetastasis".equals(op)) {
        String state = trimmed(request.getParameter("state"));
        String notes = trimmed(request.getParameter("notes"));
        if (state.isEmpty() || state.length() > 2000 || notes.length() > 1000) {
          status = 400;
          body = "{\"message\":\"Invalid metastasis state\"}";
        } else {
          statement = connection.prepareStatement("INSERT INTO patient_metastasis_state (pat_id, state, notes, recorded_by) VALUES (?,?,?,?)");
          statement.setString(1, patientId);
          statement.setString(2, state);
          statement.setString(3, notes);
          statement.setString(4, userId);
          statement.executeUpdate();
          body = "{\"status\":\"success\"}";
        }
      } else if ("createAction".equals(op)) {
        String action = trimmed(request.getParameter("action"));
        String remarks = trimmed(request.getParameter("remarks"));
        if (action.isEmpty() || action.length() > 100 || remarks.length() > 1000) {
          status = 400;
          body = "{\"message\":\"Invalid action\"}";
        } else {
          statement = connection.prepareStatement("INSERT INTO patient_distress_action (pat_id, action, remarks, recorded_by) VALUES (?,?,?,?)");
          statement.setString(1, patientId);
          statement.setString(2, action);
          statement.setString(3, remarks);
          statement.setString(4, userId);
          statement.executeUpdate();
          body = "{\"status\":\"success\"}";
        }
      } else {
        status = 400;
        body = "{\"message\":\"Unknown operation\"}";
      }
    } catch (Exception exception) {
      application.log("Patient monitoring API failed.", exception);
      status = 500;
      body = "{\"message\":\"Unable to complete the request\"}";
    } finally {
      if (result != null) try { result.close(); } catch (SQLException ignored) { }
      if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
      if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
    }
  }
  response.setStatus(status);
  response.setContentType("application/json;charset=UTF-8");
  out.clear();
  out.print(body);
%>

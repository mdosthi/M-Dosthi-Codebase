<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.io.*,java.sql.*,java.util.*" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
  private String html(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
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
%>
<%
  String role = new cook().getCookieValue("usertype", request.getCookies());
  if (!"psy".equalsIgnoreCase(role)) {
    out.println("<div class=\"alert alert-danger\">Access denied.</div>");
    return;
  }

  int pageSize = 50;
  int pageNumber = 1;
  String patientSearch = request.getParameter("search");
  if (patientSearch == null) patientSearch = request.getParameter("pat_id");
  patientSearch = patientSearch == null ? "" : patientSearch.trim();
  try { pageNumber = Math.max(1, Integer.parseInt(request.getParameter("page"))); } catch (Exception ignored) { }
  int totalPatients = 0;
  int totalPages = 1;
  String error = null;
  List<Map<String, String>> patients = new ArrayList<Map<String, String>>();
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

    String filterSql = patientSearch.isEmpty() ? "" : " WHERE (pat_id LIKE ? OR CONCAT_WS(' ', pat_name, m_name, l_name) LIKE ?)";
    statement = connection.prepareStatement("SELECT COUNT(*) FROM med" + filterSql);
    if (!patientSearch.isEmpty()) {
      statement.setString(1, "%" + patientSearch + "%");
      statement.setString(2, "%" + patientSearch + "%");
    }
    result = statement.executeQuery();
    if (result.next()) totalPatients = result.getInt(1);
    result.close();
    statement.close();
    result = null;
    statement = null;

    totalPages = Math.max(1, (int) Math.ceil(totalPatients / (double) pageSize));
    pageNumber = Math.min(pageNumber, totalPages);
    int offset = (pageNumber - 1) * pageSize;
    statement = connection.prepareStatement("SELECT pat_id, pat_name, m_name, l_name, dateofbirth, sex, phone, opdno, city, dist, state FROM med" + filterSql + " ORDER BY pat_id DESC LIMIT ? OFFSET ?");
    int parameterIndex = 1;
    if (!patientSearch.isEmpty()) {
      statement.setString(parameterIndex++, "%" + patientSearch + "%");
      statement.setString(parameterIndex++, "%" + patientSearch + "%");
    }
    statement.setInt(parameterIndex++, pageSize);
    statement.setInt(parameterIndex, offset);
    result = statement.executeQuery();
    while (result.next()) {
      Map<String, String> patient = new LinkedHashMap<String, String>();
      patient.put("pat_id", result.getString("pat_id"));
      StringBuilder name = new StringBuilder();
      String[] nameParts = { result.getString("pat_name"), result.getString("m_name"), result.getString("l_name") };
      for (String part : nameParts) if (part != null && !part.trim().isEmpty()) {
        if (name.length() > 0) name.append(' ');
        name.append(part.trim());
      }
      patient.put("name", name.toString().replaceFirst("^\\s*\\d+\\s*", ""));
      patient.put("dateofbirth", result.getString("dateofbirth"));
      patient.put("sex", result.getString("sex"));
      patient.put("phone", result.getString("phone"));
      patient.put("opdno", result.getString("opdno"));
      patient.put("city", result.getString("city"));
      patient.put("dist", result.getString("dist"));
      patient.put("state", result.getString("state"));
      patients.add(patient);
    }
  } catch (Exception exception) {
    error = "Unable to load patient details.";
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
  <title>List of Patients</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <style>
    body { margin: 0; padding: 22px; background: #f3f7f9; color: #263746; font-family: Arial, sans-serif; }
    .list-shell { max-width: 1280px; margin: 0 auto; }
    .list-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 16px; }
    h1 { margin: 0; font-size: 25px; }
    .back-link, .page-link { display: inline-block; padding: 8px 12px; border: 1px solid #b8cbd5; border-radius: 3px; color: #245b86; background: #fff; text-decoration: none; }
    .search-form { display: flex; align-items: end; gap: 8px; flex-wrap: wrap; margin-bottom: 16px; }
    .search-form label { margin: 0; }
    .search-form input { width: min(100%, 320px); height: 36px; padding: 6px 10px; border: 1px solid #b8cbd5; border-radius: 3px; }
    .search-form button { min-height: 36px; padding: 6px 12px; color: #fff; background: #245b86; border: 1px solid #245b86; border-radius: 3px; }
    .search-form button[type="button"] { color: #245b86; background: #fff; }
    .table-wrap { overflow-x: auto; background: #fff; border: 1px solid #d4e0e6; border-radius: 4px; }
    table { width: 100%; border-collapse: collapse; white-space: nowrap; }
    th, td { padding: 10px 12px; border-bottom: 1px solid #e3ebef; text-align: left; }
    th { color: #334e5c; background: #eaf2f6; }
    .pagination-row { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-top: 14px; }
    .muted { color: #667985; }
    .error { padding: 12px; color: #822727; background: #fbeaea; border: 1px solid #eccaca; }
    @media (max-width: 600px) { body { padding: 12px; } .list-header, .pagination-row { align-items: flex-start; flex-direction: column; } }
  </style>
</head>
<body>
  <main class="list-shell">
    <header class="list-header">
      <h1>List of Patients</h1>
      <a class="back-link" href="#" onclick="clearPanel('psychologistPatientMenu.jsp'); return false;">Back to Patient Details</a>
    </header>
    <form class="search-form" onsubmit="clearPanel('psychologistPatientList.jsp?search=' + encodeURIComponent(this.search.value.trim())); return false;">
      <label for="search">Patient ID or Name</label>
      <input id="search" name="search" type="search" maxlength="100" value="<%= html(patientSearch) %>" placeholder="Search by patient ID or name">
      <button type="submit">Search</button>
      <% if (!patientSearch.isEmpty()) { %><button type="button" onclick="clearPanel('psychologistPatientList.jsp'); return false;">Clear</button><% } %>
    </form>
    <% if (error != null) { %>
      <div class="error"><%= html(error) %></div>
    <% } else { %>
      <p class="muted">Patients <%= totalPatients == 0 ? 0 : ((pageNumber - 1) * pageSize + 1) %> to <%= Math.min(pageNumber * pageSize, totalPatients) %> of <%= totalPatients %></p>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Patient ID</th><th>Name</th><th>Date of Birth</th><th>Sex</th><th>Phone</th><th>OPD No.</th><th>City</th><th>District</th><th>State</th></tr></thead>
          <tbody>
            <% for (Map<String, String> patient : patients) { %>
              <tr>
                <td><%= html(patient.get("pat_id")) %></td><td><%= html(patient.get("name")) %></td>
                <td><%= html(patient.get("dateofbirth")) %></td><td><%= html(patient.get("sex")) %></td>
                <td><%= html(patient.get("phone")) %></td><td><%= html(patient.get("opdno")) %></td>
                <td><%= html(patient.get("city")) %></td><td><%= html(patient.get("dist")) %></td><td><%= html(patient.get("state")) %></td>
              </tr>
            <% } %>
            <% if (patients.isEmpty()) { %><tr><td colspan="9" class="muted">No patients found.</td></tr><% } %>
          </tbody>
        </table>
      </div>
      <nav class="pagination-row" aria-label="Patient list pages">
        <span class="muted">Page <%= pageNumber %> of <%= totalPages %></span>
        <span>
          <% if (pageNumber > 1) { %><a class="page-link" href="#" onclick="clearPanel('psychologistPatientList.jsp?page=<%= pageNumber - 1 %>&search=<%= java.net.URLEncoder.encode(patientSearch, "UTF-8") %>'); return false;">Previous</a><% } %>
          <% if (pageNumber < totalPages) { %><a class="page-link" href="#" onclick="clearPanel('psychologistPatientList.jsp?page=<%= pageNumber + 1 %>&search=<%= java.net.URLEncoder.encode(patientSearch, "UTF-8") %>'); return false;">Next</a><% } %>
        </span>
      </nav>
    <% } %>
  </main>
</body>
</html>

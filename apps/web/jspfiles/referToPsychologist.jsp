<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.sql.*,java.io.*" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
    private String dbValue(String key, String defaultValue, HttpServletRequest request) {
        BufferedReader reader = null;
        try {
            File webappDir = new File(request.getRealPath("/"));
            File config = new File(webappDir.getParentFile().getParentFile(), "M-Dosthi-BL/gblinfo.inf");
            if (!config.exists() && webappDir.getParentFile().getParentFile().getParentFile() != null) {
                config = new File(webappDir.getParentFile().getParentFile().getParentFile(), "M-Dosthi-BL/gblinfo.inf");
            }
            if (!config.exists()) config = new File("M-Dosthi-BL/gblinfo.inf");
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
    String patientId = request.getParameter("pat_id");
    String actor = new cook().getCookieValue("userid", request.getCookies());
    String role = new cook().getCookieValue("usertype", request.getCookies());
    String error = null;

    if (patientId == null || patientId.trim().length() == 0) {
        error = "Patient id is required.";
    } else if (!"adm".equalsIgnoreCase(role)) {
        error = "Only an admin can refer a patient to a psychologist.";
    } else {
        Connection connection = null;
        PreparedStatement statement = null;
        try {
            String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8", request);
            String dbUser = dbValue("gbldbusername", "root", request);
            String dbPassword = dbValue("gbldbpasswd", "", request);
            String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.jdbc.Driver", request);
            Class.forName(dbDriver);
            connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);

            statement = connection.prepareStatement("SELECT COUNT(*) FROM med WHERE pat_id=?");
            statement.setString(1, patientId);
            ResultSet patient = statement.executeQuery();
            boolean found = patient.next() && patient.getInt(1) > 0;
            patient.close();
            statement.close();
            statement = null;
            if (!found) throw new IllegalArgumentException("Patient not found");

            statement = connection.prepareStatement("UPDATE med SET psy_referred='Y', psy_referred_date=NOW() WHERE pat_id=?");
            statement.setString(1, patientId);
            statement.executeUpdate();
        } catch (Exception exception) {
            error = "Unable to refer patient to psychologist. Please try again.";
        } finally {
            if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
            if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Refer to Psychologist</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
</head>
<body>
  <div style="max-width:520px;margin:60px auto;padding:24px;border:1px solid #c8dce8;border-radius:6px;font-family:Arial,Helvetica,sans-serif;background:#eaf5fb;">
    <% if (error != null) { %>
      <div class="alert alert-danger"><%= error %></div>
    <% } else { %>
      <div class="alert alert-success">Patient <%= patientId %> has been referred to the psychologist queue.</div>
    <% } %>
    <a href="dashb.jsp" style="display:inline-block;padding:10px 16px;background:#245b86;color:#fff;border-radius:3px;text-decoration:none;">Back to Dashboard</a>
  </div>
</body>
</html>

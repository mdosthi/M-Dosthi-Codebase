<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
  String role = new cook().getCookieValue("usertype", request.getCookies());
  if (!"psy".equalsIgnoreCase(role)) {
    out.println("<div class=\"alert alert-danger\">Access denied.</div>");
    return;
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Patient Details</title>
  <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
  <style>
    body { margin: 0; padding: 24px; background: #f3f7f9; color: #263746; font-family: Arial, sans-serif; }
    .choice-shell { max-width: 780px; margin: 24px auto; }
    h1 { margin: 0 0 22px; font-size: 25px; }
    .choice-list { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
    .choice-button { min-height: 112px; display: flex; align-items: center; justify-content: center; padding: 20px; color: #fff; background: #245b86; border-radius: 4px; font-size: 20px; font-weight: 600; text-align: center; text-decoration: none; }
    .choice-button:hover, .choice-button:focus { color: #fff; background: #194568; text-decoration: none; }
    .choice-button.secondary { background: #526b78; }
    .choice-button.secondary:hover, .choice-button.secondary:focus { background: #3e5663; }
    @media (max-width: 600px) { body { padding: 12px; } .choice-list { grid-template-columns: 1fr; } .choice-button { min-height: 82px; font-size: 18px; } }
  </style>
</head>
<body>
  <main class="choice-shell">
    <h1>Patient Details</h1>
    <nav class="choice-list" aria-label="Patient views">
      <a class="choice-button" href="#" onclick="clearPanel('psychologistPatientList.jsp'); return false;">List of Patients</a>
      <a class="choice-button secondary" href="#" onclick="clearPanel('poBadoPending.jsp'); return false;">Pending Screening</a>
    </nav>
  </main>
</body>
</html>

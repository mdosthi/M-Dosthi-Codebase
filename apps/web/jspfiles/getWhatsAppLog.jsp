<%@page contentType="application/json" import="java.sql.*,org.json.simple.JSONObject,org.json.simple.JSONArray"%>
<%!
    private String nvl(String s) { return s != null ? s : ""; }
%>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
JSONArray  logs = new JSONArray();

try {
    Class.forName("com.mysql.jdbc.Driver");
    Connection conn = DriverManager.getConnection(
        "jdbc:mysql://127.0.0.1:3306/M-Dosthi_merged?characterEncoding=latin1",
        "root", "Root@1234!");
    PreparedStatement ps = conn.prepareStatement(
        "SELECT w.pat_id, l.name, w.phone, w.template_name, w.status, w.error_msg, " +
        "       DATE_FORMAT(w.sent_at,'%d-%m-%Y %H:%i') AS sent_at " +
        "FROM whatsapp_logs w " +
        "LEFT JOIN login l ON l.uid = w.pat_id " +
        "ORDER BY w.sent_at DESC LIMIT 100");
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
        JSONObject row = new JSONObject();
        row.put("pat_id",        nvl(rs.getString("pat_id")));
        row.put("name",          nvl(rs.getString("name")));
        row.put("phone",         nvl(rs.getString("phone")));
        row.put("template_name", nvl(rs.getString("template_name")));
        row.put("status",        nvl(rs.getString("status")));
        row.put("error_msg",     nvl(rs.getString("error_msg")));
        row.put("sent_at",       nvl(rs.getString("sent_at")));
        logs.add(row);
    }
    rs.close(); ps.close(); conn.close();
    r.put("success", true);
    r.put("logs", logs);
} catch (Exception e) {
    r.put("success", false);
    r.put("message", e.getMessage());
}
out.print(r.toJSONString());
%>

<%@page contentType="application/json" import="java.io.*,java.sql.*,org.json.simple.JSONObject,org.json.simple.JSONArray"%>
<%!
    private String nvl(String s) { return s != null ? s : ""; }
%>
<%
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

JSONObject r = new JSONObject();
JSONArray  logs = new JSONArray();

try {
    String dbURL = System.getenv("LEGACY_DB_URL") != null ? System.getenv("LEGACY_DB_URL")
        : "jdbc:mysql://127.0.0.1:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8";
    String dbUser = System.getenv("LEGACY_DB_USERNAME") != null ? System.getenv("LEGACY_DB_USERNAME") : "root";
    String dbPass = System.getenv("LEGACY_DB_PASSWORD") != null ? System.getenv("LEGACY_DB_PASSWORD") : "";
    try {
        File webappDir = new File(request.getRealPath("/"));
        File repoRoot = webappDir.getParentFile().getParentFile();
        File blInf = new File(repoRoot, "services/legacy/runtime/gblinfo.inf");
        if (!blInf.exists()) blInf = new File(repoRoot, "M-Dosthi-BL/gblinfo.inf");
        if (blInf.exists()) {
            try (BufferedReader br = new BufferedReader(new FileReader(blInf))) {
                String cfgLine;
                while ((cfgLine = br.readLine()) != null) {
                    int eq = cfgLine.indexOf('=');
                    if (eq > 0) {
                        String k = cfgLine.substring(0, eq).trim().toLowerCase();
                        String v = cfgLine.substring(eq + 1).trim();
                        if ("gbldburl".equals(k) && System.getenv("LEGACY_DB_URL") == null) dbURL = v;
                        else if ("gbldbusername".equals(k) && System.getenv("LEGACY_DB_USERNAME") == null) dbUser = v;
                        else if ("gbldbpasswd".equals(k) && System.getenv("LEGACY_DB_PASSWORD") == null) dbPass = v;
                    }
                }
            }
        }
    } catch (Exception ignored) {}
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
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

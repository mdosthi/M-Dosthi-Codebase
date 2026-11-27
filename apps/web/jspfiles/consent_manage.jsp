<%@page pageEncoding="UTF-8"%>
<%@page language="java" import="java.sql.*,java.io.*,org.json.simple.JSONObject"%>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    String cmd = request.getParameter("cmd");
    String uid = request.getParameter("uid");

    JSONObject result = new JSONObject();

    if (cmd == null || uid == null || cmd.trim().isEmpty() || uid.trim().isEmpty()) {
        result.put("status", "error");
        result.put("message", "Missing required parameters: cmd and uid are required.");
        out.print(result.toJSONString());
        return;
    }

    int dpdpValue = 0;
    if (cmd.equalsIgnoreCase("activate")) {
        dpdpValue = 1;
    } else if (cmd.equalsIgnoreCase("deactivate")) {
        dpdpValue = 0;
    } else {
        result.put("status", "error");
        result.put("message", "Invalid command value: must be 'activate' or 'deactivate'.");
        out.print(result.toJSONString());
        return;
    }

    // Default connection parameters (with env/gblinfo.inf overrides)
    String dbURL = System.getenv("LEGACY_DB_URL") != null ? System.getenv("LEGACY_DB_URL") : "jdbc:mysql://localhost:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8";
    String dbUser = System.getenv("LEGACY_DB_USERNAME") != null ? System.getenv("LEGACY_DB_USERNAME") : "root";
    String dbPass = System.getenv("LEGACY_DB_PASSWORD") != null ? System.getenv("LEGACY_DB_PASSWORD") : "";
    String dbDriver = "com.mysql.cj.jdbc.Driver";

    // Dynamically load database configuration from gblinfo.inf if available
    try {
        String realPath = request.getRealPath("/");
        File webappDir = new File(realPath);
        File repoRoot = webappDir.getParentFile().getParentFile();
        File blInf = new File(repoRoot, "services/legacy/runtime/gblinfo.inf");
        if (!blInf.exists()) {
            blInf = new File(repoRoot, "M-Dosthi-BL/gblinfo.inf");
        }
        if (!blInf.exists()) {
            blInf = new File("M-Dosthi-BL/gblinfo.inf");
        }
        if (blInf.exists()) {
            BufferedReader reader = new BufferedReader(new FileReader(blInf));
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.contains("=")) {
                    String key = line.substring(0, line.indexOf("=")).trim().toLowerCase();
                    String val = line.substring(line.indexOf("=") + 1).trim();
                    if (key.equals("gbldburl")) {
                        dbURL = val;
                    } else if (key.equals("gbldbusername")) {
                        dbUser = val;
                    } else if (key.equals("gbldbpasswd")) {
                        dbPass = val;
                    } else if (key.equals("gbldbjdbccriver") || key.equals("gbldbjdbcdriver")) {
                        dbDriver = val;
                    }
                }
            }
            reader.close();
        }
    } catch (Exception e) {
        // Fall back silently
    }

    // Post-process connection URL to ensure SSL is deactivated
    if (dbURL != null && !dbURL.contains("useSSL=")) {
        if (dbURL.contains("?")) {
            dbURL += "&useSSL=false";
        } else {
            dbURL += "?useSSL=false";
        }
    }

    // Try loading the driver class
    try {
        Class.forName(dbDriver);
    } catch (ClassNotFoundException e) {
        dbDriver = "com.mysql.jdbc.Driver";
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    try {
        Class.forName(dbDriver);
        conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
        
        String sql = "UPDATE login SET dpdp_agreed = ? WHERE uid = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, dpdpValue);
        pstmt.setString(2, uid);
        
        int rowsUpdated = pstmt.executeUpdate();
        if (rowsUpdated > 0) {
            result.put("status", "success");
            if (dpdpValue == 1) {
                result.put("message", "DPDP consent for patient (" + uid + ") has been successfully activated.");
            } else {
                result.put("message", "DPDP consent for patient (" + uid + ") has been successfully deactivated.");
            }
        } else {
            result.put("status", "error");
            result.put("message", "No changes made. Patient (" + uid + ") was not found in the login credentials registry.");
        }
    } catch (Exception e) {
        result.put("status", "error");
        result.put("message", "Database Error: " + e.getMessage());
        e.printStackTrace();
    } finally {
        try {
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException se) {
            // Ignore
        }
    }

    out.print(result.toJSONString());
%>

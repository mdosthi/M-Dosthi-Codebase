<%@ page language="java" contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,java.sql.*,java.io.*,java.text.*,java.util.*" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%
    // Fetch database connection params with env/gblinfo.inf overrides
    String dbURL = System.getenv("LEGACY_DB_URL") != null ? System.getenv("LEGACY_DB_URL") : "jdbc:mysql://localhost:3306/mDosthi?useUnicode=true&characterEncoding=UTF-8";
    String dbUser = System.getenv("LEGACY_DB_USERNAME") != null ? System.getenv("LEGACY_DB_USERNAME") : "root";
    String dbPass = System.getenv("LEGACY_DB_PASSWORD") != null ? System.getenv("LEGACY_DB_PASSWORD") : "";
    String dbDriver = "com.mysql.cj.jdbc.Driver";

    // Attempt to load dynamically from gblinfo.inf if available
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
        // Fall back silently to default credentials
    }

    // Post-process connection parameters to ensure compatibility
    if (dbURL != null && !dbURL.contains("useSSL=")) {
        if (dbURL.contains("?")) {
            dbURL += "&useSSL=false";
        } else {
            dbURL += "?useSSL=false";
        }
    }

    // Verify driver availability and fallback if necessary
    try {
        Class.forName(dbDriver);
    } catch (ClassNotFoundException e) {
        dbDriver = "com.mysql.jdbc.Driver";
    }


    String search = request.getParameter("search");
    String download = request.getParameter("download");

    // CSV Download Logic
    if ("csv".equalsIgnoreCase(download)) {
        response.setContentType("text/csv");
        response.setHeader("Content-Disposition", "attachment; filename=\"patient_progress.csv\"");
        PrintWriter csvWriter = response.getWriter();
        
        // Write CSV Header
        csvWriter.println("Patient ID,Patient Name,Item ID,Item Type,Open Count,Last Accessed,Time Spent (secs)");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            Class.forName(dbDriver);
            conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
            
            String sql = "SELECT up.*, l.name AS PAT_NAME FROM user_progress up LEFT JOIN login l ON up.userid = l.uid";
            if (search != null && !search.trim().isEmpty()) {
                sql += " WHERE up.userid LIKE ? OR l.name LIKE ? OR up.item_id LIKE ? OR up.item_type LIKE ?";
            }
            sql += " ORDER BY up.last_accessed DESC";
            
            pstmt = conn.prepareStatement(sql);
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim() + "%";
                pstmt.setString(1, searchPattern);
                pstmt.setString(2, searchPattern);
                pstmt.setString(3, searchPattern);
                pstmt.setString(4, searchPattern);
            }
            
            rs = pstmt.executeQuery();
            
            // Build a map of userid -> total time spent from user_time_app
            Map<String, Integer> csvTimeMap = new HashMap<String, Integer>();
            PreparedStatement tStmt = conn.prepareStatement("SELECT userid, SUM(timespent) AS total_time FROM user_time_app GROUP BY userid");
            ResultSet tRs = tStmt.executeQuery();
            while (tRs.next()) {
                csvTimeMap.put(tRs.getString("userid"), tRs.getInt("total_time"));
            }
            tRs.close();
            tStmt.close();
            
            while (rs.next()) {
                String userid = rs.getString("userid");
                String fullName = rs.getString("PAT_NAME");
                if (fullName == null || fullName.trim().isEmpty()) {
                    fullName = "Unknown";
                } else {
                    fullName = fullName.trim();
                }
                
                String itemId = rs.getString("item_id");
                String itemType = rs.getString("item_type");
                int openCount = rs.getInt("open_count");
                Timestamp lastAccessed = rs.getTimestamp("last_accessed");
                String formattedDate = lastAccessed != null ? lastAccessed.toString() : "";
                Integer timeSpentVal = csvTimeMap.get(userid);
                int timeSpentSecs = (timeSpentVal != null) ? timeSpentVal : 0;
                
                csvWriter.println(escapeCsv(userid) + "," +
                                  escapeCsv(fullName) + "," +
                                  escapeCsv(itemId) + "," +
                                  escapeCsv(itemType) + "," +
                                  openCount + "," +
                                  escapeCsv(formattedDate) + "," +
                                  timeSpentSecs);
            }
        } catch (Exception e) {
            csvWriter.println("Error generating CSV: " + e.getMessage());
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
            if (conn != null) try { conn.close(); } catch (Exception e) {}
        }
        return; // Terminate execution after writing CSV content
    }
%>
<%!
    // Helper to escape special characters for CSV format
    public String escapeCsv(String val) {
        if (val == null) return "";
        val = val.replace("\"", "\"\"");
        if (val.contains(",") || val.contains("\"") || val.contains("\n") || val.contains("\r")) {
            return "\"" + val + "\"";
        }
        return val;
    }

    public static class ItemProgress {
        public String itemId;
        public String itemType;
        public int openCount;
        public java.sql.Timestamp lastAccessed;
    }

    public static class PatientProgress {
        public String userid;
        public String name;
        public java.sql.Timestamp lastAccessed;
        public int totalOpenCount;
        public java.util.List<ItemProgress> items = new java.util.ArrayList<ItemProgress>();
        public java.util.Map<String, Integer> dailyTimeSpent = new java.util.LinkedHashMap<String, Integer>();
        public int totalTimeSpent = 0;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Patient Progress App - Statistics</title>
    <link rel="stylesheet" href="../bootstrap/css/bootstrap.min.css">
    <script src="../bootstrap/jquery-2.2.1.min.js"></script>
    <script src="../bootstrap/js/bootstrap.min.js"></script>
    
    <style>
        :root {
            --primary: #0f766e;
            --primary-dark: #115e59;
            --bg-gradient: linear-gradient(135deg, #f0fdfa 0%, #e2e8f0 100%);
            --card-bg: rgba(255, 255, 255, 0.95);
            --card-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
            --text-main: #0f172a;
            --text-muted: #475569;
            --border-color: #cbd5e1;
        }

        body {
            background: var(--bg-gradient);
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            color: var(--text-main);
            min-height: 100vh;
            padding: 30px 15px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header-container {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
        }

        .header-title {
            font-weight: 700;
            font-size: 26px;
            color: var(--text-main);
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 0;
        }

        .btn-back {
            background-color: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
            font-weight: 600;
            padding: 8px 20px;
            border-radius: 8px;
            transition: all 0.2s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-back:hover {
            background-color: #e2e8f0;
            color: #1e293b;
            text-decoration: none;
        }

        .action-card {
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: var(--card-shadow);
            border: 1px solid var(--border-color);
            padding: 20px;
            margin-bottom: 25px;
        }

        .table-card {
            background: var(--card-bg);
            border-radius: 12px;
            box-shadow: var(--card-shadow);
            border: 1px solid var(--border-color);
            padding: 24px;
            overflow: hidden;
        }

        .stats-table {
            width: 100%;
            margin-bottom: 0;
        }

        .stats-table th {
            background-color: #f8fafc;
            color: var(--text-muted);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 0.5px;
            padding: 14px 16px;
            border-bottom: 2px solid var(--border-color) !important;
        }

        .stats-table td {
            padding: 14px 16px;
            vertical-align: middle !important;
            border-bottom: 1px solid #f1f5f9 !important;
            font-size: 14px;
        }

        .stats-table tbody tr:hover {
            background-color: #f8fafc;
            transition: background-color 0.2s ease;
        }

        .badge-type {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .badge-pdf {
            background-color: rgba(239, 68, 68, 0.1);
            color: #b91c1c;
        }

        .badge-video {
            background-color: rgba(59, 130, 246, 0.1);
            color: #0D6B44;
        }

        .badge-other {
            background-color: rgba(107, 114, 128, 0.1);
            color: #374151;
        }

        .btn-teal {
            background-color: var(--primary);
            color: #ffffff;
            font-weight: 600;
            border: none;
            border-radius: 6px;
            padding: 8px 16px;
            transition: background-color 0.2s ease;
        }

        .btn-teal:hover {
            background-color: var(--primary-dark);
            color: #ffffff;
        }

        .btn-blue {
            background-color: #138A4E;
            color: #ffffff;
            font-weight: 600;
            border: none;
            border-radius: 6px;
            padding: 8px 16px;
            transition: background-color 0.2s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }

        .btn-blue:hover {
            background-color: #0D6B44;
            color: #ffffff;
            text-decoration: none;
        }

        .btn-reset {
            background-color: #94a3b8;
            color: #ffffff;
            font-weight: 600;
            border: none;
            border-radius: 6px;
            padding: 8px 16px;
            transition: background-color 0.2s ease;
        }

        .btn-reset:hover {
            background-color: #64748b;
            color: #ffffff;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header-container">
            <h1 class="header-title">
                <span class="glyphicon glyphicon-stats" style="color: var(--primary);"></span>
                Patient Progress App Statistics
            </h1>
            <a href="jobadmin.jsp" class="btn-back">
                <span class="glyphicon glyphicon-arrow-left"></span> Back
            </a>
        </div>

        <!-- Filters Form -->
        <div class="action-card">
            <form method="GET" action="patientProgressApp.jsp" id="searchForm">
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group mb-md-0">
                            <label for="searchInput" style="font-weight: 600; margin-bottom: 6px;">Search Statistics</label>
                            <input type="text" name="search" id="searchInput" class="form-control" 
                                   value="<%= search != null ? search : "" %>" 
                                   placeholder="Search by Patient ID, Name, Item ID, or Type...">
                        </div>
                    </div>
                    <div class="col-md-6" style="margin-top: 25px; display: flex; gap: 10px;">
                        <button type="submit" class="btn btn-teal">
                            <span class="glyphicon glyphicon-search"></span> Search
                        </button>
                        <button type="button" class="btn btn-reset" onclick="window.location.href='patientProgressApp.jsp'">
                            Reset
                        </button>
                        <a href="patientProgressApp.jsp?download=csv<%= (search != null && !search.trim().isEmpty()) ? "&search=" + java.net.URLEncoder.encode(search, "UTF-8") : "" %>" class="btn-blue">
                            <span class="glyphicon glyphicon-download-alt"></span> Download CSV
                        </a>
                    </div>
                </div>
            </form>
        </div>

        <!-- Table Display -->
        <div class="table-card">
            <div class="table-responsive">
                <table class="table stats-table">
                    <thead>
                        <tr>
                            <th width="17%">Patient ID</th>
                            <th width="20%">Patient Name</th>
                            <th width="12%">Items Accessed</th>
                            <th width="12%">Total Open Count</th>
                            <th width="15%">Time Spent</th>
                            <th width="14%">Last Activity</th>
                            <th width="10%" class="text-center">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            Connection conn = null;
                            PreparedStatement pstmt = null;
                            ResultSet rs = null;
                            boolean hasRecords = false;

                            try {
                                Class.forName(dbDriver);
                                conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
                                
                                String sql = "SELECT up.*, l.name AS PAT_NAME FROM user_progress up LEFT JOIN login l ON up.userid = l.uid";
                                if (search != null && !search.trim().isEmpty()) {
                                    sql += " WHERE up.userid LIKE ? OR l.name LIKE ? OR up.item_id LIKE ? OR up.item_type LIKE ?";
                                }
                                sql += " ORDER BY up.last_accessed DESC";
                                
                                pstmt = conn.prepareStatement(sql);
                                if (search != null && !search.trim().isEmpty()) {
                                    String searchPattern = "%" + search.trim() + "%";
                                    pstmt.setString(1, searchPattern);
                                    pstmt.setString(2, searchPattern);
                                    pstmt.setString(3, searchPattern);
                                    pstmt.setString(4, searchPattern);
                                }
                                
                                rs = pstmt.executeQuery();
                                Map<String, PatientProgress> patientMap = new LinkedHashMap<String, PatientProgress>();
                                while (rs.next()) {
                                    hasRecords = true;
                                    String userid = rs.getString("userid");
                                    String fullName = rs.getString("PAT_NAME");
                                    if (fullName == null || fullName.trim().isEmpty()) {
                                        fullName = "Unknown";
                                    } else {
                                        fullName = fullName.trim();
                                    }

                                    String itemId = rs.getString("item_id");
                                    String itemType = rs.getString("item_type");
                                    int openCount = rs.getInt("open_count");
                                    Timestamp lastAccessed = rs.getTimestamp("last_accessed");

                                    PatientProgress pat = patientMap.get(userid);
                                    if (pat == null) {
                                        pat = new PatientProgress();
                                        pat.userid = userid;
                                        pat.name = fullName;
                                        pat.totalOpenCount = 0;
                                        pat.lastAccessed = lastAccessed;
                                        patientMap.put(userid, pat);
                                    }
                                    
                                    pat.totalOpenCount += openCount;
                                    if (lastAccessed != null && (pat.lastAccessed == null || lastAccessed.after(pat.lastAccessed))) {
                                        pat.lastAccessed = lastAccessed;
                                    }
                                    
                                    ItemProgress item = new ItemProgress();
                                    item.itemId = itemId;
                                    item.itemType = itemType;
                                    item.openCount = openCount;
                                    item.lastAccessed = lastAccessed;
                                    pat.items.add(item);
                                }

                                // Query user_time_app for daily time spent per user
                                PreparedStatement timeStmt = conn.prepareStatement(
                                    "SELECT userid, date, timespent FROM user_time_app ORDER BY userid, date DESC"
                                );
                                ResultSet timeRs = timeStmt.executeQuery();
                                while (timeRs.next()) {
                                    String tUid = timeRs.getString("userid");
                                    String tDate = timeRs.getString("date");
                                    int tSpent = timeRs.getInt("timespent");
                                    PatientProgress tPat = patientMap.get(tUid);
                                    if (tPat != null) {
                                        tPat.dailyTimeSpent.put(tDate, tSpent);
                                        tPat.totalTimeSpent += tSpent;
                                        // Update lastAccessed if time_app date is more recent
                                        try {
                                            java.sql.Date timeAppDate = java.sql.Date.valueOf(tDate);
                                            Timestamp timeAppTs = new Timestamp(timeAppDate.getTime());
                                            if (tPat.lastAccessed == null || timeAppTs.after(tPat.lastAccessed)) {
                                                tPat.lastAccessed = timeAppTs;
                                            }
                                        } catch (Exception ignore) {}
                                    }
                                }
                                timeRs.close();
                                timeStmt.close();

                                int idx = 0;
                                for (PatientProgress pat : patientMap.values()) {
                                    idx++;
                        %>
                                    <tr data-toggle="collapse" data-target="#details-<%= idx %>" class="accordion-toggle" style="cursor: pointer;">
                                        <td><strong><%= pat.userid %></strong></td>
                                        <td><%= pat.name %></td>
                                        <td><span class="badge" style="background-color: var(--primary);"><%= pat.items.size() %> items</span></td>
                                        <td style="font-weight: 600;"><%= pat.totalOpenCount %></td>
                                        <td>
                                            <%
                                                int totalSecs = pat.totalTimeSpent;
                                                int hrs = totalSecs / 3600;
                                                int mins = (totalSecs % 3600) / 60;
                                                String timeDisplay = (hrs > 0) ? (hrs + "h " + mins + "m") : (mins + "m");
                                            %>
                                            <span class="badge" style="background-color: #7c3aed; color: #fff; font-size: 12px; padding: 4px 10px;">
                                                <span class="glyphicon glyphicon-time"></span> <%= timeDisplay %>
                                            </span>
                                        </td>
                                        <td>
                                            <%
                                                String lastActivityStr = "-";
                                                if (pat.lastAccessed != null) {
                                                    SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd-MMM-yyyy, hh:mm a");
                                                    lastActivityStr = sdfDisplay.format(pat.lastAccessed);
                                                    // If time is midnight (came from user_time_app date-only), show just date
                                                    if (lastActivityStr.endsWith("12:00 AM")) {
                                                        lastActivityStr = new SimpleDateFormat("dd-MMM-yyyy").format(pat.lastAccessed);
                                                    }
                                                }
                                            %>
                                            <%= lastActivityStr %>
                                        </td>
                                        <td class="text-center">
                                            <button class="btn btn-default btn-xs" type="button" style="color: var(--primary); border-color: var(--primary);">
                                                <span class="glyphicon glyphicon-chevron-down"></span> Details
                                            </button>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="7" style="padding: 0 !important; border-top: none !important;">
                                            <div class="accordion-body collapse" id="details-<%= idx %>" style="padding: 15px 25px; background-color: #f8fafc; border-bottom: 2px solid var(--border-color);">
                                                
                                                <%-- Daily Time Spent Section --%>
                                                <% if (!pat.dailyTimeSpent.isEmpty()) { %>
                                                <h5 style="margin-top: 0; margin-bottom: 12px; font-weight: 600; color: #7c3aed;">
                                                    <span class="glyphicon glyphicon-time"></span> Daily Time Spent
                                                </h5>
                                                <table class="table table-bordered" style="margin-bottom: 18px; background: #ffffff; border: 1px solid var(--border-color);">
                                                    <thead>
                                                        <tr style="background-color: #f5f3ff; color: #6d28d9;">
                                                            <th>Date</th>
                                                            <th>Time Spent</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <%
                                                            for (Map.Entry<String, Integer> timeEntry : pat.dailyTimeSpent.entrySet()) {
                                                                int daySecs = timeEntry.getValue();
                                                                int dayHrs = daySecs / 3600;
                                                                int dayRemMins = (daySecs % 3600) / 60;
                                                                String dayTimeStr = (dayHrs > 0) ? (dayHrs + "h " + dayRemMins + "m") : (dayRemMins + "m");
                                                        %>
                                                                <tr>
                                                                    <td><%= timeEntry.getKey() %></td>
                                                                    <td>
                                                                        <span style="color: #7c3aed; font-weight: 600;">
                                                                            <span class="glyphicon glyphicon-time"></span> <%= dayTimeStr %>
                                                                        </span>
                                                                        <span style="color: #94a3b8; font-size: 12px;">(<%= daySecs %> secs)</span>
                                                                    </td>
                                                                </tr>
                                                        <%
                                                            }
                                                        %>
                                                    </tbody>
                                                </table>
                                                <% } %>

                                                <h5 style="margin-top: 0; margin-bottom: 12px; font-weight: 600; color: var(--primary-dark);">
                                                    <span class="glyphicon glyphicon-list-alt"></span> Accessed Content Details
                                                </h5>
                                                <table class="table table-bordered" style="margin-bottom: 0; background: #ffffff; border: 1px solid var(--border-color);">
                                                    <thead>
                                                        <tr style="background-color: #f1f5f9; color: var(--text-muted);">
                                                            <th>Item ID</th>
                                                            <th>Item Type</th>
                                                            <th>Open Count</th>
                                                            <th>Last Accessed</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <%
                                                            for (ItemProgress item : pat.items) {
                                                                String badgeClass = "badge-other";
                                                                if ("pdf".equalsIgnoreCase(item.itemType)) {
                                                                    badgeClass = "badge-pdf";
                                                                } else if ("video".equalsIgnoreCase(item.itemType)) {
                                                                    badgeClass = "badge-video";
                                                                }
                                                        %>
                                                                <tr>
                                                                    <td><code><%= item.itemId %></code></td>
                                                                    <td><span class="badge-type <%= badgeClass %>"><%= item.itemType %></span></td>
                                                                    <td style="font-weight: 600;"><%= item.openCount %></td>
                                                                    <td><%= item.lastAccessed != null ? item.lastAccessed.toString() : "-" %></td>
                                                                </tr>
                                                        <%
                                                            }
                                                        %>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </td>
                                    </tr>
                        <%
                                }
                                if (!hasRecords) {
                        %>
                                    <tr>
                                        <td colspan="7" class="text-center" style="padding: 40px; color: var(--text-muted);">
                                            No patient progress statistics found.
                                        </td>
                                    </tr>
                        <%
                                }
                            } catch (Exception e) {
                        %>
                                <tr>
                                    <td colspan="7" class="text-danger text-center" style="padding: 40px;">
                                        <span class="glyphicon glyphicon-exclamation-sign"></span> 
                                        <strong>Error loading data:</strong> <%= e.getMessage() %>
                                    </td>
                                </tr>
                        <%
                            } finally {
                                if (rs != null) try { rs.close(); } catch (Exception e) {}
                                if (pstmt != null) try { pstmt.close(); } catch (Exception e) {}
                                if (conn != null) try { conn.close(); } catch (Exception e) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>

<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,imedix.rcGenOperations,imedix.rcPatqueueInfo,imedix.dataobj,java.sql.*,java.io.*,java.net.*,java.util.Vector" %>
<%@ include file="..//includes/chkcook.jsp" %>
<%!
    private String dbValue(String key, String defaultValue, HttpServletRequest request) {
        String value = defaultValue;
        BufferedReader reader = null;
        try {
            String realPath = request.getRealPath("/");
            File webappDir = new File(realPath);
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

    private Integer integer(HttpServletRequest request, String name) {
        String value = text(request, name);
        if (value == null) return null;
        try {
            int parsed = Integer.parseInt(value);
            if (parsed < 0 || parsed > 3) throw new IllegalArgumentException(name);
            return parsed;
        } catch (NumberFormatException exception) {
            throw new IllegalArgumentException(name);
        }
    }

    private String nextPendingPatientId(HttpServletRequest request, String currentPatientId) {
        try {
            cook cookx = new cook();
            String center = cookx.getCookieValue("center", request.getCookies());
            rcPatqueueInfo patientQueue = new rcPatqueueInfo(request.getRealPath("/"));
            rcGenOperations records = new rcGenOperations(request.getRealPath("/"));
            int total = Integer.parseInt(patientQueue.getTotalLPatAdmin2(center));
            Object queue = patientQueue.getLPatqueueAdmin(center, 0, total);
            if (!(queue instanceof Vector)) {
                return null;
            }

            Vector queuePatients = (Vector) queue;
            for (int index = 0; index < queuePatients.size(); index++) {
                dataobj patient = (dataobj) queuePatients.get(index);
                String patientId = patient.getValue("pat_id");
                if (patientId == null || patientId.equals(currentPatientId)) continue;
                String completed = records.FindCount("phq9_screening", "pat_id='" + patientId.replace("'", "''") + "'");
                if (completed == null || completed.trim().length() == 0 || "0".equals(completed.trim())) {
                    return patientId;
                }
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
    String redirect = "phq9Screening.jsp?pat_id=" + URLEncoder.encode(patientId == null ? "" : patientId, "UTF-8") + "&checkpoint=" + URLEncoder.encode(assessmentCheckpoint, "UTF-8");

    Connection connection = null;
    PreparedStatement statement = null;
    try {
        if (patientId == null || screeningDate == null) {
            throw new IllegalArgumentException("Patient ID and screening date are required");
        }
        if (!assessmentCheckpoint.matches("Baseline Assessment|4 week Assessment|8 week Assessment|12 week Assessment")) throw new IllegalArgumentException("Invalid assessment checkpoint");
        if (actor == null || role == null) {
            throw new SecurityException("Unauthenticated user");
        }
        if (!"adm".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) {
            throw new SecurityException("Role is not allowed");
        }

        String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi_merged?useUnicode=true&characterEncoding=UTF-8", request);
        String dbUser = dbValue("gbldbusername", "root", request);
        String dbPassword = dbValue("gbldbpasswd", "", request);
        String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
        Class.forName(dbDriver);
        connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);

        statement = connection.prepareStatement("SELECT pat_name FROM med WHERE pat_id=?");
        statement.setString(1, patientId);
        ResultSet patient = statement.executeQuery();
        if (!patient.next()) {
            throw new IllegalArgumentException("Patient not found");
        }
        patient.close();
        statement.close();
        statement = null;

        Integer q1 = integer(request, "q1");
        Integer q2 = integer(request, "q2");
        Integer q3 = integer(request, "q3");
        Integer q4 = integer(request, "q4");
        Integer q5 = integer(request, "q5");
        Integer q6 = integer(request, "q6");
        Integer q7 = integer(request, "q7");
        Integer q8 = integer(request, "q8");
        Integer q9 = integer(request, "q9");
        int total = (q1 == null ? 0 : q1)
                + (q2 == null ? 0 : q2)
                + (q3 == null ? 0 : q3)
                + (q4 == null ? 0 : q4)
                + (q5 == null ? 0 : q5)
                + (q6 == null ? 0 : q6)
                + (q7 == null ? 0 : q7)
                + (q8 == null ? 0 : q8)
                + (q9 == null ? 0 : q9);

        if (q1 == null || q2 == null || q3 == null || q4 == null || q5 == null || q6 == null || q7 == null || q8 == null || q9 == null) {
            throw new IllegalArgumentException("All PHQ-9 items are required");
        }

        statement = connection.prepareStatement(
            "INSERT INTO phq9_screening (pat_id, assessment_checkpoint, patient_name, screening_date, q1, q2, q3, q4, q5, q6, q7, q8, q9, total_score, recorded_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        int index = 1;
        statement.setString(index++, patientId);
        statement.setString(index++, assessmentCheckpoint);
        statement.setString(index++, patientName == null ? "" : patientName);
        statement.setDate(index++, java.sql.Date.valueOf(screeningDate));
        statement.setInt(index++, q1);
        statement.setInt(index++, q2);
        statement.setInt(index++, q3);
        statement.setInt(index++, q4);
        statement.setInt(index++, q5);
        statement.setInt(index++, q6);
        statement.setInt(index++, q7);
        statement.setInt(index++, q8);
        statement.setInt(index++, q9);
        statement.setInt(index++, total);
        statement.setString(index, actor);
        statement.executeUpdate();
        statement.close();
        statement = null;

        redirect += "&saved=1";
    } catch (Exception exception) {
        redirect = "pendingScreeningSelection.jsp?pat_id=" + URLEncoder.encode(patientId == null ? "" : patientId, "UTF-8") + "&checkpoint=" + URLEncoder.encode(assessmentCheckpoint, "UTF-8") + "&error=" + URLEncoder.encode(exception.getMessage() == null ? "Unable to save PHQ-9 screening" : exception.getMessage(), "UTF-8");
    } finally {
        if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
        if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
    }
    response.sendRedirect(redirect);
%>

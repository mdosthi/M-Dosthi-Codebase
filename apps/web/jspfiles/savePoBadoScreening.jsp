<%@ page contentType="text/html" pageEncoding="UTF-8" %>
<%@ page import="imedix.cook,imedix.rcGenOperations,java.sql.*,java.io.*,java.net.*,java.time.*" %>
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

    private Integer number(HttpServletRequest request, String name, int min, int max) {
        String value = text(request, name);
        if (value == null) return null;
        try {
            int number = Integer.parseInt(value);
            if (number < min || number > max) throw new IllegalArgumentException(name);
            return number;
        } catch (NumberFormatException exception) {
            throw new IllegalArgumentException(name);
        }
    }

    private void setString(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) statement.setNull(index, Types.VARCHAR); else statement.setString(index, value);
    }

    private void setInteger(PreparedStatement statement, int index, Integer value) throws SQLException {
        if (value == null) statement.setNull(index, Types.INTEGER); else statement.setInt(index, value);
    }

    private void setDate(PreparedStatement statement, int index, String value) throws SQLException {
        if (value == null) statement.setNull(index, Types.DATE); else statement.setDate(index, java.sql.Date.valueOf(value));
    }
%>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        return;
    }

    String patientId = text(request, "crNumber");
    String assessmentCheckpoint = text(request, "assessment_checkpoint");
    if (assessmentCheckpoint == null) assessmentCheckpoint = "Baseline Assessment";
    String patientName = text(request, "patientName");
    String patientPhone = null;
    String patientSex = null;
    Integer age = null;
    String screeningDate = text(request, "screeningDate");
    String actor = new cook().getCookieValue("userid", request.getCookies());
    String role = new cook().getCookieValue("usertype", request.getCookies());
    String redirect = "poBadoScreening.jsp?pat_id=" + URLEncoder.encode(patientId == null ? "" : patientId, "UTF-8") + "&checkpoint=" + URLEncoder.encode(assessmentCheckpoint, "UTF-8");
    Connection connection = null;
    PreparedStatement statement = null;
    try {
        if (patientId == null || patientName == null || screeningDate == null) throw new IllegalArgumentException("CR number, patient name and screening date are required");
        if (!assessmentCheckpoint.matches("Baseline Assessment|4 week Assessment|8 week Assessment|12 week Assessment")) throw new IllegalArgumentException("Invalid assessment checkpoint");
        if (actor == null || role == null) throw new SecurityException("Unauthenticated user");
        if (!"PAT".equalsIgnoreCase(role) && !"doc".equalsIgnoreCase(role) && !"adm".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) throw new SecurityException("Role is not allowed");
        if ("PAT".equalsIgnoreCase(role) && !actor.equalsIgnoreCase(patientId)) throw new SecurityException("Patient access is restricted to the authenticated patient");

        String dbUrl = dbValue("gbldburl", "jdbc:mysql://localhost:3306/M-Dosthi_merged?useUnicode=true&characterEncoding=UTF-8", request);
        String dbUser = dbValue("gbldbusername", "root", request);
        String dbPassword = dbValue("gbldbpasswd", "", request);
        String dbDriver = dbValue("gbldbjdbccriver", "com.mysql.cj.jdbc.Driver", request);
        Class.forName(dbDriver);
        connection = DriverManager.getConnection(dbUrl + (dbUrl.contains("?") ? "&" : "?") + "useSSL=false", dbUser, dbPassword);

        statement = connection.prepareStatement("SELECT pat_name,phone,age,sex FROM med WHERE pat_id=?");
        statement.setString(1, patientId);
        ResultSet patient = statement.executeQuery();
        if (!patient.next()) throw new IllegalArgumentException("Patient not found");
        patientName = new rcGenOperations(request.getRealPath("/")).getPatientName(patientId);
        if (patientName == null || patientName.trim().isEmpty()) patientName = patient.getString("pat_name");
        if (patientName != null) patientName = patientName.replaceFirst("^\\s*\\d+\\s*", "");
        patientPhone = patient.getString("phone");
        patientSex = patient.getString("sex");
        String storedAge = patient.getString("age");
        if (storedAge != null) {
            try {
                String years = storedAge.split(",", 2)[0].trim();
                int parsedAge = Integer.parseInt(years);
                if (parsedAge >= 0 && parsedAge <= 120) age = parsedAge;
            } catch (NumberFormatException ignored) {
            }
        }
        patient.close();
        statement.close();
        statement = null;

        if ("doc".equalsIgnoreCase(role)) {
            statement = connection.prepareStatement("SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'");
            statement.setString(1, patientId);
            statement.setString(2, actor);
            ResultSet assignment = statement.executeQuery();
            if (!assignment.next() || assignment.getInt(1) == 0) throw new SecurityException("Doctor is not assigned to this patient");
            assignment.close();
            statement.close();
            statement = null;
        }

        Integer fatigue = number(request, "fatigue", 0, 4);
        Integer mood = number(request, "mood", 0, 4);
        Integer anxiety = number(request, "anxiety", 0, 4);
        Integer depression = number(request, "depression", 0, 4);
        Integer limitations = number(request, "limitations", 0, 4);
        Integer socialProblems = number(request, "socialProblems", 0, 4);
        int total = (fatigue == null ? 0 : fatigue) + (mood == null ? 0 : mood) + (anxiety == null ? 0 : anxiety) + (depression == null ? 0 : depression) + (limitations == null ? 0 : limitations) + (socialProblems == null ? 0 : socialProblems);
        Integer performanceStatus = number(request, "performanceStatus", 0, 4);

        statement = connection.prepareStatement("INSERT INTO pobado_screening (cr_number,assessment_checkpoint,phone_number,patient_name,screening_date,age,gender,relationship,children,work_situation,tumour_diagnosis,metastasis,diagnosis_date,disease_state,treatments,physical_diseases,psychoactive_medication,psych_treatment,performance_status,fatigue,mood,anxiety,depression,limitations,social_problems,total_score,substance_use,last_substance_used,follow_up_date,bed_number,recorded_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
        int i = 1;
        setString(statement, i++, patientId);
        setString(statement, i++, assessmentCheckpoint);
        setString(statement, i++, patientPhone);
        setString(statement, i++, patientName);
        setDate(statement, i++, screeningDate);
        setInteger(statement, i++, age);
        setString(statement, i++, patientSex);
        setString(statement, i++, text(request, "relationship"));
        setString(statement, i++, text(request, "children"));
        setString(statement, i++, text(request, "workSituation"));
        setString(statement, i++, text(request, "tumourDiagnosis"));
        setString(statement, i++, text(request, "metastasis"));
        setString(statement, i++, text(request, "diagnosisDate"));
        setString(statement, i++, text(request, "diseaseState"));
        setString(statement, i++, text(request, "treatments"));
        setString(statement, i++, text(request, "physicalDiseases"));
        setString(statement, i++, text(request, "psychoactiveMedication"));
        setString(statement, i++, text(request, "psychTreatment"));
        setInteger(statement, i++, performanceStatus);
        setInteger(statement, i++, fatigue);
        setInteger(statement, i++, mood);
        setInteger(statement, i++, anxiety);
        setInteger(statement, i++, depression);
        setInteger(statement, i++, limitations);
        setInteger(statement, i++, socialProblems);
        statement.setInt(i++, total);
        setString(statement, i++, text(request, "substanceUse"));
        setString(statement, i++, text(request, "lastSubstanceUsed"));
        setDate(statement, i++, text(request, "followUpDate"));
        setString(statement, i++, text(request, "bedNumber"));
        statement.setString(i, actor);
        statement.executeUpdate();
        statement.close();

        // Turn the PO Bado flag on and mark RCT readiness once screening completes.
        // A total score between 0 and 9 (inclusive) means the patient is ready for RCT.
        statement = connection.prepareStatement("UPDATE med SET pobado_flag='Y', rct_ready=? WHERE pat_id=?");
        statement.setString(1, (total >= 0 && total <= 9) ? "Y" : "N");
        statement.setString(2, patientId);
        statement.executeUpdate();

        redirect += "&saved=1";
    } catch (Exception exception) {
        redirect += "&error=" + URLEncoder.encode(exception.getMessage() == null ? "Unable to save screening" : exception.getMessage(), "UTF-8");
    } finally {
        if (statement != null) try { statement.close(); } catch (SQLException ignored) { }
        if (connection != null) try { connection.close(); } catch (SQLException ignored) { }
    }
    response.sendRedirect(redirect);
%>

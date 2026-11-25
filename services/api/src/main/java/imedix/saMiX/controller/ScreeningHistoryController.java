package imedix.saMiX.controller;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.rowset.SqlRowSet;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import imedix.saMiX.helper.JwtUtil;

/**
 * POST /api/user/get-screening-history (see docs/api.md, "Patient screening history").
 * Returns persisted PO Bado, Distress Thermometer, PHQ-9 and GAD-7 records for a patient,
 * newest first, plus a per-instrument 4/8/12-week follow-up schedule.
 * Doctors and psychologists only; doctors are restricted to their assigned patients.
 */
@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/user")
public class ScreeningHistoryController {

    private static final String[] ANSWER_LABELS = {
        "Not at all", "Several days", "More than half the days", "Nearly every day"
    };

    private static final String[] PHQ9_QUESTIONS = {
        "Little interest or pleasure in doing things",
        "Feeling down, depressed, or hopeless",
        "Trouble falling or staying asleep, or sleeping too much",
        "Feeling tired or having little energy",
        "Poor appetite or overeating",
        "Feeling bad about yourself or that you are a failure or have let yourself or your family down",
        "Trouble concentrating on things, such as reading the newspaper or watching television",
        "Moving or speaking so slowly that other people could have noticed, or being so fidgety or restless that you have been moving around a lot more than usual",
        "Thoughts that you would be better off dead, or of hurting yourself"
    };

    private static final String[] GAD7_QUESTIONS = {
        "Feeling nervous, anxious, or on edge",
        "Not being able to stop or control worrying",
        "Worrying too much about different things",
        "Trouble relaxing",
        "Being so restless that it is hard to sit still",
        "Becoming easily annoyed or irritable",
        "Feeling afraid, as if something awful might happen"
    };

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/get-screening-history")
    public Map<String, Object> getScreeningHistory(@RequestBody Map<String, Object> body,
                                                   HttpServletRequest request) {
        Map<String, Object> response = new LinkedHashMap<>();
        try {
            String token = bearerToken(request);
            String username = token == null ? null : jwtUtil.extractUsername(token);
            String type = token == null ? null : jwtUtil.extractType(token);
            if (!"doc".equalsIgnoreCase(type) && !"psy".equalsIgnoreCase(type)) {
                return error(response, "Only doctors and psychologists can access screening history");
            }

            String patientId = body == null || body.get("patientId") == null
                ? "" : body.get("patientId").toString().trim();
            if (patientId.isEmpty()) {
                return error(response, "Patient ID is required");
            }
            int offset = Math.max(0, intValue(body.get("offset"), 0));
            int limit = Math.min(100, Math.max(1, intValue(body.get("limit"), 50)));

            Integer exists = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM med WHERE pat_id=?", Integer.class, patientId);
            if (exists == null || exists == 0) {
                return error(response, "Patient not found");
            }
            if ("doc".equalsIgnoreCase(type)) {
                Integer assigned = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) "
                        + "WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'",
                    Integer.class, patientId, username);
                if (assigned == null || assigned == 0) {
                    return error(response, "Patient not found");
                }
            }

            int totalCount = count("pobado_screening", "cr_number", patientId)
                + count("distress_thermometer", "pat_id", patientId)
                + count("phq9_screening", "pat_id", patientId)
                + count("gad7_screening", "pat_id", patientId);
            int fetchLimit = offset + limit;

            List<Map<String, Object>> records = new ArrayList<>();
            String followUpDate = null;

            SqlRowSet rs = jdbcTemplate.queryForRowSet(
                "SELECT id, screening_date, assessment_checkpoint, total_score, fatigue, mood, anxiety, depression, "
                    + "limitations, social_problems, follow_up_date, recorded_at FROM pobado_screening "
                    + "WHERE cr_number=? ORDER BY screening_date DESC, id DESC LIMIT ?", patientId, fetchLimit);
            boolean first = true;
            while (rs.next()) {
                Map<String, Object> record = baseRecord("pobado:" + rs.getString("id"), "PO Bado",
                    rs.getString("screening_date"), rs.getString("assessment_checkpoint"),
                    rs.getObject("total_score"), 24, null, rs.getString("recorded_at"));
                record.put("followUpDate", rs.getString("follow_up_date"));
                if (first) {
                    followUpDate = rs.getString("follow_up_date");
                    first = false;
                }
                record.put("responses", responses(
                    new String[] {"Fatigue", "Mood", "Anxiety", "Depression", "Limitations", "Social problems"},
                    new Object[] {rs.getObject("fatigue"), rs.getObject("mood"), rs.getObject("anxiety"),
                        rs.getObject("depression"), rs.getObject("limitations"), rs.getObject("social_problems")}));
                records.add(record);
            }

            rs = jdbcTemplate.queryForRowSet(
                "SELECT id, screening_date, assessment_checkpoint, distress_score, recorded_at "
                    + "FROM distress_thermometer WHERE pat_id=? ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, fetchLimit);
            while (rs.next()) {
                Map<String, Object> record = baseRecord("distress:" + rs.getString("id"), "Distress Thermometer",
                    rs.getString("screening_date"), rs.getString("assessment_checkpoint"),
                    rs.getObject("distress_score"), 10, null, rs.getString("recorded_at"));
                record.put("screeningId", rs.getObject("id"));
                record.put("responses", responses(new String[] {"Distress score"},
                    new Object[] {rs.getObject("distress_score")}));
                records.add(record);
            }

            rs = jdbcTemplate.queryForRowSet(
                "SELECT id, screening_date, assessment_checkpoint, total_score, recorded_at, "
                    + "q1, q2, q3, q4, q5, q6, q7, q8, q9 "
                    + "FROM phq9_screening WHERE pat_id=? ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, fetchLimit);
            while (rs.next()) {
                Map<String, Object> record = baseRecord("phq9:" + rs.getString("id"), "PHQ-9",
                    rs.getString("screening_date"), rs.getString("assessment_checkpoint"),
                    rs.getObject("total_score"), 27, null, rs.getString("recorded_at"));
                Object[] scores = new Object[9];
                for (int i = 0; i < 9; i++) scores[i] = rs.getObject("q" + (i + 1));
                record.put("responses", questionnaireResponses(PHQ9_QUESTIONS, scores));
                records.add(record);
            }

            rs = jdbcTemplate.queryForRowSet(
                "SELECT id, screening_date, assessment_checkpoint, total_score, anxiety_category, recorded_at, "
                    + "q1, q2, q3, q4, q5, q6, q7 "
                    + "FROM gad7_screening WHERE pat_id=? ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, fetchLimit);
            while (rs.next()) {
                Map<String, Object> record = baseRecord("gad7:" + rs.getString("id"), "GAD-7",
                    rs.getString("screening_date"), rs.getString("assessment_checkpoint"),
                    rs.getObject("total_score"), 21, rs.getString("anxiety_category"), rs.getString("recorded_at"));
                Object[] scores = new Object[7];
                for (int i = 0; i < 7; i++) scores[i] = rs.getObject("q" + (i + 1));
                record.put("responses", questionnaireResponses(GAD7_QUESTIONS, scores));
                records.add(record);
            }

            records.sort((left, right) -> {
                int byDate = Objects.toString(right.get("screeningDate"), "")
                    .compareTo(Objects.toString(left.get("screeningDate"), ""));
                if (byDate != 0) return byDate;
                return Objects.toString(right.get("recordedAt"), "")
                    .compareTo(Objects.toString(left.get("recordedAt"), ""));
            });

            String lastScreeningDate = records.isEmpty() ? null : (String) records.get(0).get("screeningDate");
            List<Map<String, Object>> page = new ArrayList<>(
                records.subList(Math.min(offset, records.size()), Math.min(offset + limit, records.size())));

            for (Map<String, Object> record : page) {
                if (!"Distress Thermometer".equals(record.get("screeningType"))) continue;
                List<Map<String, Object>> concerns = new ArrayList<>();
                SqlRowSet concernRows = jdbcTemplate.queryForRowSet(
                    "SELECT category, concern FROM distress_thermometer_problem WHERE screening_id=? ORDER BY id",
                    record.get("screeningId"));
                while (concernRows.next()) {
                    Map<String, Object> concern = new LinkedHashMap<>();
                    concern.put("category", concernRows.getString("category"));
                    concern.put("concern", concernRows.getString("concern"));
                    concerns.add(concern);
                }
                record.put("concerns", concerns);
            }

            List<Map<String, Object>> schedule = new ArrayList<>();
            schedule.add(scheduleItem(patientId, "PO Bado", "pobado_screening", "cr_number", true));
            schedule.add(scheduleItem(patientId, "Distress Thermometer", "distress_thermometer", "pat_id", false));
            schedule.add(scheduleItem(patientId, "PHQ-9", "phq9_screening", "pat_id", false));
            schedule.add(scheduleItem(patientId, "GAD-7", "gad7_screening", "pat_id", false));

            response.put("status", "success");
            response.put("patientId", patientId);
            response.put("offset", offset);
            response.put("limit", limit);
            response.put("totalCount", totalCount);
            response.put("hasMore", offset + page.size() < totalCount);
            response.put("lastScreeningDate", lastScreeningDate);
            response.put("followUpDate", followUpDate);
            response.put("records", page);
            response.put("screeningSchedule", schedule);
            return response;
        } catch (Exception exception) {
            System.err.println("get-screening-history failed: " + exception);
            return error(response, "Unable to load screening history");
        }
    }

    private static String bearerToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) return null;
        String token = header.substring(7).trim();
        return token.isEmpty() ? null : token;
    }

    private static Map<String, Object> error(Map<String, Object> response, String message) {
        response.clear();
        response.put("status", "error");
        response.put("message", message);
        return response;
    }

    private static int intValue(Object value, int defaultValue) {
        if (value instanceof Number number) return number.intValue();
        if (value == null) return defaultValue;
        try {
            return Integer.parseInt(value.toString().trim());
        } catch (NumberFormatException ignored) {
            return defaultValue;
        }
    }

    private int count(String table, String column, String patientId) {
        Integer value = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM " + table + " WHERE " + column + "=?", Integer.class, patientId);
        return value == null ? 0 : value;
    }

    private static Map<String, Object> baseRecord(String id, String screeningType, String screeningDate,
                                                  String checkpoint, Object score, int maximumScore,
                                                  String interpretation, String recordedAt) {
        Map<String, Object> record = new LinkedHashMap<>();
        record.put("id", id);
        record.put("screeningType", screeningType);
        record.put("screeningDate", screeningDate);
        record.put("assessmentCheckpoint", checkpoint);
        record.put("status", "Completed");
        record.put("score", score);
        record.put("maximumScore", maximumScore);
        record.put("interpretation", interpretation);
        record.put("recordedAt", recordedAt);
        return record;
    }

    private static List<Map<String, Object>> responses(String[] labels, Object[] values) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (int i = 0; i < labels.length; i++) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label", labels[i]);
            item.put("value", values[i]);
            list.add(item);
        }
        return list;
    }

    private static List<Map<String, Object>> questionnaireResponses(String[] questions, Object[] scores) {
        Object[] answers = new Object[scores.length];
        for (int i = 0; i < scores.length; i++) {
            Object score = scores[i];
            if (score instanceof Number number) {
                int index = number.intValue();
                answers[i] = index >= 0 && index < ANSWER_LABELS.length ? ANSWER_LABELS[index] : score;
            } else {
                answers[i] = score;
            }
        }
        return responses(questions, answers);
    }

    private static int checkpointWeek(String checkpoint) {
        if (checkpoint == null) return -1;
        if ("Baseline Assessment".equalsIgnoreCase(checkpoint)) return 0;
        if ("4 week Assessment".equalsIgnoreCase(checkpoint)) return 4;
        if ("8 week Assessment".equalsIgnoreCase(checkpoint)) return 8;
        if ("12 week Assessment".equalsIgnoreCase(checkpoint)) return 12;
        return -1;
    }

    private static String countdown(long days) {
        if (days < 0) {
            long overdue = Math.abs(days);
            return "Due date passed by " + overdue + (overdue == 1 ? " day" : " days")
                + "; no completion is recorded for this checkpoint";
        }
        if (days == 0) return "Due today";
        return "Due in " + days + (days == 1 ? " day" : " days");
    }

    private static LocalDate localDate(String value) {
        if (value == null || value.trim().length() < 10) return null;
        try {
            return LocalDate.parse(value.trim().substring(0, 10));
        } catch (Exception ignored) {
            return null;
        }
    }

    private Map<String, Object> scheduleItem(String patientId, String name, String table,
                                             String patientColumn, boolean hasSavedFollowUpDate) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("screeningType", name);

        String baselineDate = null;
        SqlRowSet baseline = jdbcTemplate.queryForRowSet(
            "SELECT screening_date FROM " + table + " WHERE " + patientColumn
                + "=? AND assessment_checkpoint=? ORDER BY screening_date ASC, id ASC LIMIT 1",
            patientId, "Baseline Assessment");
        if (baseline.next()) baselineDate = baseline.getString("screening_date");

        String latestDate = null;
        String latestCheckpoint = null;
        String savedFollowUpDate = null;
        SqlRowSet latest = jdbcTemplate.queryForRowSet(
            "SELECT screening_date, assessment_checkpoint"
                + (hasSavedFollowUpDate ? ", follow_up_date" : "")
                + " FROM " + table + " WHERE " + patientColumn
                + "=? ORDER BY screening_date DESC, id DESC LIMIT 1", patientId);
        if (latest.next()) {
            latestDate = latest.getString("screening_date");
            latestCheckpoint = latest.getString("assessment_checkpoint");
            if (hasSavedFollowUpDate) savedFollowUpDate = latest.getString("follow_up_date");
        }

        item.put("baselineDate", baselineDate);
        item.put("lastCompletedCheckpoint", latestCheckpoint);
        if (latestDate == null) {
            item.put("nextCheckpoint", "Baseline Assessment");
            item.put("dueDate", null);
            item.put("countdown", "Baseline screening not completed");
            return item;
        }
        LocalDate baselineLocal = localDate(baselineDate);
        if (baselineLocal == null) {
            item.put("nextCheckpoint", "Baseline Assessment");
            item.put("dueDate", null);
            item.put("countdown", "Baseline date unavailable; schedule cannot be calculated");
            return item;
        }
        int completedWeek = checkpointWeek(latestCheckpoint);
        if (completedWeek < 0) {
            item.put("nextCheckpoint", null);
            item.put("dueDate", null);
            item.put("countdown", "Schedule checkpoint unavailable");
            return item;
        }
        if (completedWeek >= 12) {
            item.put("nextCheckpoint", null);
            item.put("dueDate", null);
            item.put("countdown", "12-week schedule complete");
            return item;
        }
        int nextWeek = completedWeek + 4;
        LocalDate dueDate = localDate(savedFollowUpDate);
        if (dueDate == null) dueDate = baselineLocal.plusWeeks(nextWeek);
        item.put("nextCheckpoint", nextWeek + " week Assessment");
        item.put("dueDate", dueDate.toString());
        item.put("countdown", countdown(ChronoUnit.DAYS.between(LocalDate.now(), dueDate)));
        return item;
    }
}

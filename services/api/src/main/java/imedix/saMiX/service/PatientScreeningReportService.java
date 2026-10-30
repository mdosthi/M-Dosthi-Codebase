package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class PatientScreeningReportService {
    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_OFFSET = 10_000;

    private final JdbcTemplate jdbc;
    private final UserRepository userRepository;

    public PatientScreeningReportService(JdbcTemplate jdbc, UserRepository userRepository) {
        this.jdbc = jdbc;
        this.userRepository = userRepository;
    }

    public Map<String, Object> getHistory(
            String patientId, String actor, int requestedOffset, int requestedLimit) {
        if (patientId == null || patientId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Patient ID is required");
        }
        if (actor == null || actor.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        if (requestedOffset < 0 || requestedOffset > MAX_OFFSET
                || requestedLimit < 1 || requestedLimit > MAX_PAGE_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid page range");
        }

        String normalizedPatientId = patientId.trim();
        Map<String, Object> userInfo = userRepository.getUserInfo(actor);
        String role = Objects.toString(userInfo.get("type"), "");
        if (!"doc".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only clinicians can access screening history");
        }

        Integer patientCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM med WHERE pat_id = ?", Integer.class, normalizedPatientId);
        if (patientCount == null || patientCount == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found");
        }
        if ("doc".equalsIgnoreCase(role)) {
            Integer assignmentCount = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM lpatq lp " +
                            "JOIN login d ON UPPER(d.rg_no) = UPPER(lp.assigneddoc) " +
                            "WHERE lp.pat_id = ? AND UPPER(d.uid) = UPPER(?) " +
                            "AND UPPER(lp.delflag) = 'N'",
                    Integer.class, normalizedPatientId, actor);
            if (assignmentCount == null || assignmentCount == 0) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                        "Doctor is not assigned to this patient");
            }
        }

        int fetchLimit = requestedOffset + requestedLimit;
        List<Map<String, Object>> records = new ArrayList<>();
        records.addAll(loadPoBado(normalizedPatientId, fetchLimit));
        records.addAll(loadDistressThermometer(normalizedPatientId, fetchLimit));
        records.addAll(loadPhq9(normalizedPatientId, fetchLimit));
        records.addAll(loadGad7(normalizedPatientId, fetchLimit));
        records.sort(Comparator
                .comparing((Map<String, Object> record) -> Objects.toString(record.get("screeningDate"), ""))
                .reversed()
                .thenComparing(record -> Objects.toString(record.get("recordedAt"), ""), Comparator.reverseOrder())
                .thenComparing(record -> Objects.toString(record.get("screeningType"), "")));

        int total = count("pobado_screening", "cr_number", normalizedPatientId)
                + count("distress_thermometer", "pat_id", normalizedPatientId)
                + count("phq9_screening", "pat_id", normalizedPatientId)
                + count("gad7_screening", "pat_id", normalizedPatientId);
        String followUpDate = findLatestPoBadoFollowUp(normalizedPatientId);
        List<Map<String, Object>> screeningSchedule = loadScreeningSchedule(normalizedPatientId);
        attachDistressConcerns(records, requestedOffset, requestedLimit);

        int start = Math.min(requestedOffset, records.size());
        int end = Math.min(start + requestedLimit, records.size());
        List<Map<String, Object>> page = new ArrayList<>(records.subList(start, end));
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "success");
        response.put("patientId", normalizedPatientId);
        response.put("records", page);
        response.put("totalCount", total);
        response.put("offset", requestedOffset);
        response.put("limit", requestedLimit);
        response.put("hasMore", requestedOffset + page.size() < total);
        response.put("lastScreeningDate",
                records.isEmpty() ? null : records.get(0).get("screeningDate"));
        response.put("followUpDate", followUpDate);
        response.put("screeningSchedule", screeningSchedule);
        return response;
    }

    private List<Map<String, Object>> loadScreeningSchedule(String patientId) {
        List<Map<String, Object>> schedule = new ArrayList<>();
        schedule.add(loadScheduleItem(
                patientId, "PO Bado", "pobado_screening", "cr_number", true));
        schedule.add(loadScheduleItem(
                patientId, "Distress Thermometer", "distress_thermometer", "pat_id", false));
        schedule.add(loadScheduleItem(
                patientId, "PHQ-9", "phq9_screening", "pat_id", false));
        schedule.add(loadScheduleItem(
                patientId, "GAD-7", "gad7_screening", "pat_id", false));
        return schedule;
    }

    private Map<String, Object> loadScheduleItem(
            String patientId, String screeningType, String table, String patientColumn,
            boolean hasSavedFollowUpDate) {
        List<Map<String, Object>> baselineRows = jdbc.queryForList(
                "SELECT screening_date FROM " + table + " WHERE " + patientColumn +
                        " = ? AND assessment_checkpoint = 'Baseline Assessment' " +
                        "ORDER BY screening_date ASC, id ASC LIMIT 1",
                patientId);
        List<Map<String, Object>> latestRows = jdbc.queryForList(
                "SELECT screening_date, assessment_checkpoint" +
                        (hasSavedFollowUpDate ? ", follow_up_date" : "") +
                        " FROM " + table + " WHERE " + patientColumn +
                        " = ? ORDER BY screening_date DESC, id DESC LIMIT 1",
                patientId);

        LocalDate baselineDate = baselineRows.isEmpty()
                ? null : toLocalDate(baselineRows.get(0).get("screening_date"));
        Map<String, Object> latest = latestRows.isEmpty() ? null : latestRows.get(0);
        String latestCheckpoint = latest == null
                ? null : Objects.toString(latest.get("assessment_checkpoint"), null);
        LocalDate savedFollowUpDate = hasSavedFollowUpDate && latest != null
                ? toLocalDate(latest.get("follow_up_date")) : null;

        Map<String, Object> item = new LinkedHashMap<>();
        item.put("screeningType", screeningType);
        item.put("baselineDate", baselineDate == null ? null : baselineDate.toString());
        item.put("lastCompletedCheckpoint", latestCheckpoint);

        if (latest == null) {
            item.put("nextCheckpoint", "Baseline Assessment");
            item.put("dueDate", null);
            item.put("countdown", "Baseline screening not completed");
            return item;
        }
        if (baselineDate == null) {
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
        LocalDate dueDate = savedFollowUpDate != null
                ? savedFollowUpDate : baselineDate.plusWeeks(nextWeek);
        long daysRemaining = ChronoUnit.DAYS.between(LocalDate.now(), dueDate);
        item.put("nextCheckpoint", nextWeek + " week Assessment");
        item.put("dueDate", dueDate.toString());
        item.put("daysRemaining", daysRemaining);
        item.put("countdown", countdown(daysRemaining));
        return item;
    }

    private int checkpointWeek(String checkpoint) {
        if ("Baseline Assessment".equalsIgnoreCase(checkpoint)) return 0;
        if (checkpoint == null) return -1;
        java.util.regex.Matcher matcher =
                java.util.regex.Pattern.compile("^(4|8|12) week Assessment$", java.util.regex.Pattern.CASE_INSENSITIVE)
                        .matcher(checkpoint.trim());
        return matcher.matches() ? Integer.parseInt(matcher.group(1)) : -1;
    }

    private String countdown(long daysRemaining) {
        if (daysRemaining < 0) {
            return "Due date passed by " + Math.abs(daysRemaining) +
                    " " + (Math.abs(daysRemaining) == 1 ? "day" : "days") +
                    "; no completion is recorded for this checkpoint";
        }
        if (daysRemaining == 0) return "Due today";
        return "Due in " + daysRemaining + " " + (daysRemaining == 1 ? "day" : "days");
    }

    private LocalDate toLocalDate(Object value) {
        if (value == null) return null;
        if (value instanceof java.sql.Date sqlDate) return sqlDate.toLocalDate();
        return LocalDate.parse(value.toString().substring(0, 10));
    }

    private List<Map<String, Object>> loadPoBado(String patientId, int limit) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT id, screening_date, assessment_checkpoint, total_score, fatigue, mood, " +
                        "anxiety, depression, limitations, social_problems, follow_up_date, " +
                        "recorded_at FROM pobado_screening WHERE cr_number = ? " +
                        "ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, limit);
        List<Map<String, Object>> records = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            Map<String, Object> record = baseRecord(
                    "PO Bado", row, row.get("total_score"), 24, null);
            record.put("followUpDate", dateString(row.get("follow_up_date")));
            addResponse(record, "Fatigue", row.get("fatigue"));
            addResponse(record, "Mood", row.get("mood"));
            addResponse(record, "Anxiety", row.get("anxiety"));
            addResponse(record, "Depression", row.get("depression"));
            addResponse(record, "Limitations", row.get("limitations"));
            addResponse(record, "Social problems", row.get("social_problems"));
            records.add(record);
        }
        return records;
    }

    private List<Map<String, Object>> loadDistressThermometer(String patientId, int limit) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT id, screening_date, assessment_checkpoint, distress_score, recorded_at " +
                "FROM distress_thermometer WHERE pat_id = ? " +
                        "ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, limit);
        List<Map<String, Object>> records = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            Map<String, Object> record = baseRecord(
                    "Distress Thermometer", row, row.get("distress_score"), 10, null);
            record.put("id", "distress:" + row.get("id"));
            record.put("sourceId", row.get("id"));
            addResponse(record, "Distress score", row.get("distress_score"));
            records.add(record);
        }
        return records;
    }

    private List<Map<String, Object>> loadPhq9(String patientId, int limit) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT id, screening_date, assessment_checkpoint, total_score, q1, q2, q3, q4, " +
                        "q5, q6, q7, q8, q9 FROM phq9_screening " +
                        "WHERE pat_id = ? ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, limit);
        List<Map<String, Object>> records = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            Map<String, Object> record = baseRecord(
                    "PHQ-9", row, row.get("total_score"), 27, null);
            for (int question = 1; question <= 9; question++) {
                addResponse(record, "Question " + question, row.get("q" + question));
            }
            records.add(record);
        }
        return records;
    }

    private List<Map<String, Object>> loadGad7(String patientId, int limit) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT id, screening_date, assessment_checkpoint, total_score, anxiety_category, " +
                        "q1, q2, q3, q4, q5, q6, q7 FROM gad7_screening " +
                        "WHERE pat_id = ? ORDER BY screening_date DESC, id DESC LIMIT ?",
                patientId, limit);
        List<Map<String, Object>> records = new ArrayList<>();
        for (Map<String, Object> row : rows) {
            Map<String, Object> record = baseRecord(
                    "GAD-7", row, row.get("total_score"), 21, row.get("anxiety_category"));
            for (int question = 1; question <= 7; question++) {
                addResponse(record, "Question " + question, row.get("q" + question));
            }
            records.add(record);
        }
        return records;
    }

    private Map<String, Object> baseRecord(
            String type, Map<String, Object> row, Object score, int maximumScore, Object interpretation) {
        Map<String, Object> record = new LinkedHashMap<>();
        record.put("id", type.toLowerCase().replaceAll("[^a-z0-9]+", "-") + ":" + row.get("id"));
        record.put("sourceId", row.get("id"));
        record.put("screeningType", type);
        record.put("screeningDate", dateString(row.get("screening_date")));
        record.put("assessmentCheckpoint", row.get("assessment_checkpoint"));
        record.put("status", "Completed");
        record.put("score", score);
        record.put("maximumScore", maximumScore);
        record.put("interpretation", interpretation);
        record.put("recordedAt", row.get("recorded_at") == null ? null : row.get("recorded_at").toString());
        record.put("responses", new ArrayList<Map<String, Object>>());
        return record;
    }

    private void addResponse(Map<String, Object> record, String label, Object value) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> responses = (List<Map<String, Object>>) record.get("responses");
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("label", label);
        response.put("value", value);
        responses.add(response);
    }

    private int count(String table, String patientColumn, String patientId) {
        Integer result = jdbc.queryForObject(
                "SELECT COUNT(*) FROM " + table + " WHERE " + patientColumn + " = ?",
                Integer.class, patientId);
        return result == null ? 0 : result;
    }

    private String findLatestPoBadoFollowUp(String patientId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT follow_up_date FROM pobado_screening WHERE cr_number = ? " +
                        "ORDER BY screening_date DESC, id DESC LIMIT 1",
                patientId);
        return rows.isEmpty() ? null : dateString(rows.get(0).get("follow_up_date"));
    }

    private void attachDistressConcerns(
            List<Map<String, Object>> records, int offset, int limit) {
        int start = Math.min(offset, records.size());
        int end = Math.min(start + limit, records.size());
        List<Map<String, Object>> page = records.subList(start, end);
        List<Object> ids = page.stream()
                .filter(record -> "Distress Thermometer".equals(record.get("screeningType")))
                .map(record -> record.get("sourceId"))
                .toList();
        if (ids.isEmpty()) return;

        String placeholders = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
        List<Map<String, Object>> concerns = jdbc.queryForList(
                "SELECT screening_id, category, concern FROM distress_thermometer_problem " +
                        "WHERE screening_id IN (" + placeholders + ") ORDER BY screening_id, id",
                ids.toArray());
        Map<String, List<Map<String, Object>>> grouped = new HashMap<>();
        for (Map<String, Object> concern : concerns) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("category", concern.get("category"));
            item.put("concern", concern.get("concern"));
            grouped.computeIfAbsent(String.valueOf(concern.get("screening_id")), key -> new ArrayList<>())
                    .add(item);
        }
        for (Map<String, Object> record : page) {
            if (!"Distress Thermometer".equals(record.get("screeningType"))) continue;
            record.put("concerns", grouped.getOrDefault(
                    String.valueOf(record.get("sourceId")), List.of()));
        }
    }

    private String dateString(Object value) {
        return value == null ? null : value.toString();
    }
}
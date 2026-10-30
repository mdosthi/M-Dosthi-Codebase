package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class PatientScreeningReportService {
    private static final int DEFAULT_PAGE_SIZE = 50;
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
        if (!"doc".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role)
                && !"adm".equalsIgnoreCase(role)) {
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
        String nextScreeningDate = findLatestPoBadoFollowUp(normalizedPatientId);
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
        response.put("nextScreeningDate", nextScreeningDate);
        return response;
    }

    private List<Map<String, Object>> loadPoBado(String patientId, int limit) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT id, screening_date, assessment_checkpoint, total_score, fatigue, mood, " +
                        "anxiety, depression, limitations, social_problems, follow_up_date, " +
                        "recorded_at, recorded_by FROM pobado_screening WHERE cr_number = ? " +
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
                "SELECT id, screening_date, assessment_checkpoint, distress_score, recorded_at, " +
                        "recorded_by FROM distress_thermometer WHERE pat_id = ? " +
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
                        "q5, q6, q7, q8, q9, recorded_at, recorded_by FROM phq9_screening " +
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
                        "q1, q2, q3, q4, q5, q6, q7, recorded_at, recorded_by FROM gad7_screening " +
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
        record.put("recordedBy", row.get("recorded_by"));
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
            grouped.computeIfAbsent(String.valueOf(concern.get("screening_id")), key -> new ArrayList<>())
                    .add(Map.of("category", concern.get("category"), "concern", concern.get("concern")));
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
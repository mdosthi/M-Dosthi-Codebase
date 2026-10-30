package imedix.saMiX.service;

import imedix.saMiX.dao.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PatientScreeningReportServiceTest {
    private static final String PATIENT_ID = "PAT-123";
    private static final String DOCTOR_LOGIN = "doctor.login";

    @Mock
    private JdbcTemplate jdbc;

    @Mock
    private UserRepository userRepository;

    private PatientScreeningReportService service;

    @BeforeEach
    void setUp() {
        service = new PatientScreeningReportService(jdbc, userRepository);
    }

    @Test
    void deniesPatientAccountsBeforeQueryingScreeningData() {
        when(userRepository.getUserInfo("patient.login"))
                .thenReturn(Map.of("type", "pat"));

        assertThatThrownBy(() -> service.getHistory(PATIENT_ID, "patient.login", 0, 50))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("403");

        verify(jdbc, never()).queryForObject(anyString(), eq(Integer.class), any(Object[].class));
    }

    @Test
    void deniesDoctorsWhoAreNotAssignedToThePatient() {
        when(userRepository.getUserInfo(DOCTOR_LOGIN))
                .thenReturn(Map.of("type", "doc"));
        when(jdbc.queryForObject(
                org.mockito.ArgumentMatchers.contains("FROM med"),
                eq(Integer.class), any(Object[].class))).thenReturn(1);
        when(jdbc.queryForObject(
                org.mockito.ArgumentMatchers.contains("FROM lpatq"),
                eq(Integer.class), any(Object[].class))).thenReturn(0);

        assertThatThrownBy(() -> service.getHistory(PATIENT_ID, DOCTOR_LOGIN, 0, 50))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("403");
    }

    @Test
    void returnsAnEmptyHistoryWithoutInventingASchedule() {
        when(userRepository.getUserInfo("psy.login"))
                .thenReturn(Map.of("type", "psy"));
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
                .thenReturn(1, 0, 0, 0, 0);
        when(jdbc.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());

        Map<String, Object> response = service.getHistory("PAT-123", "psy.login", 0, 50);

        assertThat(response.get("status")).isEqualTo("success");
        assertThat((List<?>) response.get("records")).isEmpty();
        assertThat(response.get("totalCount")).isEqualTo(0);
        assertThat(response.get("lastScreeningDate")).isNull();
        assertThat(response.get("followUpDate")).isNull();
        assertThat(response.get("hasMore")).isEqualTo(false);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> schedule =
                (List<Map<String, Object>>) response.get("screeningSchedule");
        assertThat(schedule).hasSize(4)
                .allSatisfy(item -> assertThat(item.get("countdown"))
                        .isEqualTo("Baseline screening not completed"));
    }

    @Test
    void combinesSavedScreeningsInDateOrderAndUsesOnlySavedFollowUpDates() {
        when(userRepository.getUserInfo("psy.login"))
                .thenReturn(Map.of("type", "psy"));
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
                .thenReturn(1);
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenAnswer(invocation -> {
                    String sql = invocation.getArgument(0);
                    if (sql.contains("assessment_checkpoint = 'Baseline Assessment'")) {
                        String date = sql.contains("pobado_screening") ? "2025-01-01"
                                : sql.contains("distress_thermometer") ? "2025-01-10"
                                : sql.contains("phq9_screening") ? "2025-02-05"
                                : "2025-02-06";
                        return List.of(Map.of("screening_date", date));
                    }
                    if (sql.contains("SELECT screening_date, assessment_checkpoint")) {
                        if (sql.contains("pobado_screening")) {
                            return List.of(Map.of(
                                    "screening_date", "2025-01-01",
                                    "assessment_checkpoint", "Baseline Assessment",
                                    "follow_up_date", "2025-05-01"));
                        }
                        if (sql.contains("distress_thermometer")) {
                            return List.of(Map.of(
                                    "screening_date", "2025-04-04",
                                    "assessment_checkpoint", "12 week Assessment"));
                        }
                        if (sql.contains("phq9_screening")) {
                            return List.of(Map.of(
                                    "screening_date", "2025-04-02",
                                    "assessment_checkpoint", "8 week Assessment"));
                        }
                        if (sql.contains("gad7_screening")) {
                            return List.of(Map.of(
                                    "screening_date", "2025-04-03",
                                    "assessment_checkpoint", "8 week Assessment"));
                        }
                    }
                    if (sql.contains("FROM pobado_screening") && sql.contains("follow_up_date")) {
                        return List.of(Map.of("follow_up_date", "2025-05-01"));
                    }
                    if (sql.contains("FROM pobado_screening")) {
                        return List.of(pobadoRow());
                    }
                    if (sql.contains("FROM distress_thermometer_problem")) {
                        return List.of();
                    }
                    if (sql.contains("FROM distress_thermometer")) {
                        return List.of(distressRow());
                    }
                    if (sql.contains("FROM phq9_screening")) {
                        return List.of(phq9Row());
                    }
                    if (sql.contains("FROM gad7_screening")) {
                        return List.of(gad7Row());
                    }
                    return List.of();
                });

        Map<String, Object> response = service.getHistory("PAT-123", "psy.login", 0, 50);

        assertThat(response.get("status")).isEqualTo("success");
        assertThat(response.get("totalCount")).isEqualTo(4);
        assertThat(response.get("lastScreeningDate")).isEqualTo("2025-04-04");
        assertThat(response.get("followUpDate")).isEqualTo("2025-05-01");
        assertThat(response.get("hasMore")).isEqualTo(false);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> records = (List<Map<String, Object>>) response.get("records");
        assertThat(records).extracting(record -> record.get("screeningType"))
                .containsExactly("Distress Thermometer", "GAD-7", "PHQ-9", "PO Bado");
        assertThat(records.get(0).get("screeningDate")).isEqualTo("2025-04-04");
        assertThat(records.get(3).get("followUpDate")).isEqualTo("2025-05-01");
        assertThat(records).allSatisfy(record -> assertThat(record.get("status")).isEqualTo("Completed"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> gadResponses =
                (List<Map<String, Object>>) records.get(1).get("responses");
        assertThat(gadResponses.get(0))
                .containsEntry("label", "Feeling nervous, anxious, or on edge")
                .containsEntry("value", "Nearly every day");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> phqResponses =
                (List<Map<String, Object>>) records.get(2).get("responses");
        assertThat(phqResponses.get(0))
                .containsEntry("label", "Little interest or pleasure in doing things")
                .containsEntry("value", "Nearly every day");
        assertThat(phqResponses.get(1))
                .containsEntry("label", "Feeling down, depressed, or hopeless")
                .containsEntry("value", "More than half the days");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> schedule =
                (List<Map<String, Object>>) response.get("screeningSchedule");
        assertThat(schedule).extracting(item -> item.get("screeningType"))
                .containsExactly("PO Bado", "Distress Thermometer", "PHQ-9", "GAD-7");
        assertThat(schedule.get(0))
                .containsEntry("baselineDate", "2025-01-01")
                .containsEntry("nextCheckpoint", "4 week Assessment")
                .containsEntry("dueDate", "2025-05-01");
        assertThat(schedule.get(0).get("countdown").toString())
                .contains("Due date passed by")
                .contains("no completion is recorded for this checkpoint");
        assertThat(schedule.get(1)).containsEntry("countdown", "12-week schedule complete");
        assertThat(schedule.get(2))
                .containsEntry("nextCheckpoint", "12 week Assessment")
                .containsEntry("dueDate", "2025-04-30");
        assertThat(schedule.get(3))
                .containsEntry("nextCheckpoint", "12 week Assessment")
                .containsEntry("dueDate", "2025-05-01");
    }

    @Test
    void doesNotCalculateDatesWithoutABaselineAndCountsDownToTheNextCheckpoint() {
        when(userRepository.getUserInfo("psy.login"))
                .thenReturn(Map.of("type", "psy"));
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(Object[].class)))
                .thenReturn(1, 0, 0, 0, 0);
        String baselineDate = LocalDate.now().minusWeeks(4).toString();
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenAnswer(invocation -> {
                    String sql = invocation.getArgument(0);
                    if (sql.contains("assessment_checkpoint = 'Baseline Assessment'")) {
                        if (sql.contains("distress_thermometer")) {
                            return List.of(Map.of("screening_date", baselineDate));
                        }
                        return List.of();
                    }
                    if (sql.contains("SELECT screening_date, assessment_checkpoint")) {
                        if (sql.contains("distress_thermometer")) {
                            return List.of(Map.of(
                                    "screening_date", baselineDate,
                                    "assessment_checkpoint", "Baseline Assessment"));
                        }
                        if (sql.contains("phq9_screening")) {
                            return List.of(Map.of(
                                    "screening_date", LocalDate.now().toString(),
                                    "assessment_checkpoint", "4 week Assessment"));
                        }
                    }
                    return List.of();
                });

        Map<String, Object> response = service.getHistory("PAT-123", "psy.login", 0, 50);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> schedule =
                (List<Map<String, Object>>) response.get("screeningSchedule");
        assertThat(schedule.get(1))
                .containsEntry("baselineDate", baselineDate)
                .containsEntry("nextCheckpoint", "4 week Assessment")
                .containsEntry("dueDate", LocalDate.now().toString())
                .containsEntry("countdown", "Due today");
        assertThat(schedule.get(2))
                .containsEntry("baselineDate", null)
                .containsEntry("dueDate", null)
                .containsEntry("countdown",
                        "Baseline date unavailable; schedule cannot be calculated");
    }

    private Map<String, Object> pobadoRow() {
        Map<String, Object> row = baseRow("pobado-1", "2025-01-01", "Baseline Assessment");
        row.put("total_score", 12);
        row.put("fatigue", 2);
        row.put("mood", 2);
        row.put("anxiety", 2);
        row.put("depression", 2);
        row.put("limitations", 2);
        row.put("social_problems", 2);
        row.put("follow_up_date", "2025-05-01");
        return row;
    }

    private Map<String, Object> distressRow() {
        Map<String, Object> row = baseRow("distress-1", "2025-04-04", "12 week Assessment");
        row.put("distress_score", 5);
        return row;
    }

    private Map<String, Object> phq9Row() {
        Map<String, Object> row = baseRow("phq9-1", "2025-04-02", "8 week Assessment");
        row.put("total_score", 12);
        for (int question = 1; question <= 9; question++) row.put("q" + question, 1);
        row.put("q1", 3);
        row.put("q2", 2);
        return row;
    }

    private Map<String, Object> gad7Row() {
        Map<String, Object> row = baseRow("gad7-1", "2025-04-03", "8 week Assessment");
        row.put("total_score", 9);
        row.put("anxiety_category", "Mild");
        for (int question = 1; question <= 7; question++) row.put("q" + question, 1);
        row.put("q1", 3);
        return row;
    }

    private Map<String, Object> baseRow(String id, String date, String checkpoint) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", id);
        row.put("screening_date", date);
        row.put("assessment_checkpoint", checkpoint);
        row.put("recorded_at", date + " 10:00:00");
        row.put("recorded_by", "clinician");
        return row;
    }
}
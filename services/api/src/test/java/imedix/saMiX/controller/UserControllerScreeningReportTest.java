package imedix.saMiX.controller;

import imedix.saMiX.service.PatientScreeningReportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;

@ExtendWith(MockitoExtension.class)
class UserControllerScreeningReportTest {
    @Mock
    private PatientScreeningReportService screeningReportService;

    private UserController controller;
    private Authentication authentication;

    @BeforeEach
    void setUp() {
        controller = new UserController();
        ReflectionTestUtils.setField(controller, "patientScreeningReportService", screeningReportService);
        authentication = UsernamePasswordAuthenticationToken.authenticated(
                "doctor.login", null, List.of());
    }

    @Test
    void returnsTheRequestedHistoryPage() {
        Map<String, Object> responseBody = Map.of(
                "status", "success", "records", List.of(), "totalCount", 0);
        when(screeningReportService.getHistory("PAT-123", "doctor.login", 50, 25))
                .thenReturn(responseBody);

        ResponseEntity<Map<String, Object>> response = controller.getPatientScreeningHistory(
                Map.of("patientId", "PAT-123", "offset", 50, "limit", 25), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isEqualTo(responseBody);
    }

    @Test
    void rejectsNonIntegerPageParameters() {
        ResponseEntity<Map<String, Object>> response = controller.getPatientScreeningHistory(
                Map.of("patientId", "PAT-123", "offset", "next"), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).containsEntry("status", "error");
        verify(screeningReportService, never())
                .getHistory(anyString(), anyString(), anyInt(), anyInt());
    }

    @Test
    void preservesAuthorizationFailuresAsForbiddenResponses() {
        when(screeningReportService.getHistory(eq("PAT-123"), eq("doctor.login"), eq(0), eq(50)))
                .thenThrow(new ResponseStatusException(HttpStatus.FORBIDDEN, "Not assigned"));

        ResponseEntity<Map<String, Object>> response = controller.getPatientScreeningHistory(
                Map.of("patientId", "PAT-123"), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(response.getBody()).containsEntry("message", "Not assigned");
    }
}
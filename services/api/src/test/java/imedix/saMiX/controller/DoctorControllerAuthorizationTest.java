package imedix.saMiX.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import imedix.saMiX.filter.JwtFilter;
import imedix.saMiX.service.PatientQueueInfoService;

@ExtendWith(MockitoExtension.class)
class DoctorControllerAuthorizationTest {

    @Mock
    private JwtFilter jwtFilter;

    @Mock
    private PatientQueueInfoService patientQueueInfoService;

    private DoctorController controller;

    @BeforeEach
    void setUp() {
        controller = new DoctorController();
        ReflectionTestUtils.setField(controller, "jwtFilter", jwtFilter);
        ReflectionTestUtils.setField(controller, "patientQueueInfoService", patientQueueInfoService);
    }

    @Test
    void allowsDoctorToReadAssignedPatientQueue() {
        allowsClinicianToReadAssignedPatientQueue("doc", "docAIMK0190000");
    }

    @Test
    void allowsPsychologistToReadAllPatients() {
        when(jwtFilter.getType()).thenReturn("psy");
        when(patientQueueInfoService.getAllPatientsForPsychologist())
                .thenReturn(List.of(Map.of("pat_id", "PAT-ALL-1")));

        Map<String, Object> response = controller.getLocalPatients();

        assertThat(response.get("status")).isEqualTo("success");
        assertThat((List<?>) response.get("data")).hasSize(1);
        verify(patientQueueInfoService).getAllPatientsForPsychologist();
    }

    @Test
    void rejectsNonClinicianRoles() {
        when(jwtFilter.getType()).thenReturn("admin");

        Map<String, Object> response = controller.getLocalPatients();

        assertThat(response.get("status")).isEqualTo("error");
        assertThat(response.get("message")).isEqualTo("You are not authorized to access this resource");
    }

    private void allowsClinicianToReadAssignedPatientQueue(String type, String registrationNumber) {
        when(jwtFilter.getType()).thenReturn(type);
        when(jwtFilter.get_reg_no()).thenReturn(registrationNumber);
        when(patientQueueInfoService.getLocalPatientQueue(registrationNumber))
                .thenReturn(List.of(Map.of("pat_id", "PAT-1")));

        Map<String, Object> response = controller.getLocalPatients();

        assertThat(response.get("status")).isEqualTo("success");
        assertThat((List<?>) response.get("data")).hasSize(1);
        verify(patientQueueInfoService).getLocalPatientQueue(registrationNumber);
    }
}
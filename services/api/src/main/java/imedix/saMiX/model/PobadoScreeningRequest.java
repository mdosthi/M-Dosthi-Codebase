package imedix.saMiX.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.YearMonth;

public record PobadoScreeningRequest(
        @NotBlank @Size(max = 64) String crNumber,
        @Size(max = 32) String phoneNumber,
        @NotBlank @Size(max = 200) String patientName,
        @NotNull LocalDate screeningDate,
        @Min(0) @Max(120) Integer age,
        @Pattern(regexp = "M|F|\\s*") String gender,
        @Pattern(regexp = "Yes|No|Not known|\\s*") String relationship,
        @Pattern(regexp = "Yes|No|Not known|\\s*") String children,
        @Size(max = 100) String workSituation,
        @Size(max = 3000) String tumourDiagnosis,
        @Pattern(regexp = "Yes|No|Not known|\\s*") String metastasis,
        YearMonth diagnosisDate,
        @Size(max = 100) String diseaseState,
        @Size(max = 3000) String treatments,
        @Size(max = 3000) String physicalDiseases,
        @Size(max = 3000) String psychoactiveMedication,
        @Pattern(regexp = "Yes|No|Not known|\\s*") String psychTreatment,
        @Min(0) @Max(4) Integer performanceStatus,
        @Min(0) @Max(4) Integer fatigue,
        @Min(0) @Max(4) Integer mood,
        @Min(0) @Max(4) Integer anxiety,
        @Min(0) @Max(4) Integer depression,
        @Min(0) @Max(4) Integer limitations,
        @Min(0) @Max(4) Integer socialProblems,
        @Min(0) @Max(24) Integer totalScore,
        @Size(max = 100) String substanceUse,
        @Size(max = 100) String lastSubstanceUsed,
        LocalDate followUpDate,
        @Size(max = 50) String bedNumber) {
}
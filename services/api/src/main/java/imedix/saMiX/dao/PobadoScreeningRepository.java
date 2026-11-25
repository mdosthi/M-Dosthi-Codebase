package imedix.saMiX.dao;

import imedix.saMiX.model.PobadoScreeningRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Date;
import java.util.List;
import java.util.Map;

@Repository
public class PobadoScreeningRepository {
    private final JdbcTemplate jdbc;

    public PobadoScreeningRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public boolean patientExists(String patientId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM med WHERE pat_id = ?", Integer.class, patientId);
        return count != null && count > 0;
    }

    public boolean doctorHasPatient(String doctorId, String patientId) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'", Integer.class, patientId, doctorId);
        return count != null && count > 0;
    }

    public long save(String actor, PobadoScreeningRequest r, int calculatedScore) {
        jdbc.update("""
                INSERT INTO pobado_screening (
                    cr_number, phone_number, patient_name, screening_date, age, gender,
                    relationship, children, work_situation, tumour_diagnosis, metastasis,
                    diagnosis_date, disease_state, treatments, physical_diseases,
                    psychoactive_medication, psych_treatment, performance_status,
                    fatigue, mood, anxiety, depression, limitations, social_problems,
                    total_score, substance_use, last_substance_used, follow_up_date,
                    bed_number, recorded_by
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, r.crNumber(), r.phoneNumber(), r.patientName(), Date.valueOf(r.screeningDate()),
                r.age(), r.gender(), r.relationship(), r.children(), r.workSituation(), r.tumourDiagnosis(),
                r.metastasis(), r.diagnosisDate() == null ? null : r.diagnosisDate().toString(), r.diseaseState(),
                r.treatments(), r.physicalDiseases(), r.psychoactiveMedication(), r.psychTreatment(),
                r.performanceStatus(), r.fatigue(), r.mood(), r.anxiety(), r.depression(), r.limitations(),
                r.socialProblems(), calculatedScore, r.substanceUse(), r.lastSubstanceUsed(),
                r.followUpDate() == null ? null : Date.valueOf(r.followUpDate()), r.bedNumber(), actor);
        Long id = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
        return id == null ? 0L : id;
    }

    public List<Map<String, Object>> findByPatient(String patientId) {
        return jdbc.queryForList("SELECT id, cr_number AS crNumber, phone_number AS phoneNumber, patient_name AS patientName, screening_date AS screeningDate, age, gender, relationship, children, work_situation AS workSituation, tumour_diagnosis AS tumourDiagnosis, metastasis, diagnosis_date AS diagnosisDate, disease_state AS diseaseState, treatments, physical_diseases AS physicalDiseases, psychoactive_medication AS psychoactiveMedication, psych_treatment AS psychTreatment, performance_status AS performanceStatus, fatigue, mood, anxiety, depression, limitations, social_problems AS socialProblems, total_score AS totalScore, substance_use AS substanceUse, last_substance_used AS lastSubstanceUsed, follow_up_date AS followUpDate, bed_number AS bedNumber, recorded_by AS recordedBy, recorded_at AS recordedAt FROM pobado_screening WHERE cr_number=? ORDER BY screening_date DESC, id DESC", patientId);
    }
}
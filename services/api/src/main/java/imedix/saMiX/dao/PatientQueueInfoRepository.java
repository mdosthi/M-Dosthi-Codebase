package imedix.saMiX.dao;

import java.util.List;
import java.util.Map;

public interface PatientQueueInfoRepository {
    public int getLPatQueueCount(String patid);
    public int getLPatQueueCount(String patid, String doc_reg_no);
    public List<Map<String,Object>> getLocalPatientQueue(String docrgno);
    public List<Map<String,Object>> getAllPatientsForPsychologist();
    public List<Map<String,Object>> getPendingAppointments(String docrgno);
    public Map<String,Object> getQueueInfo(String patid);
}

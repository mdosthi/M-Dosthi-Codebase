package imedix.saMiX.service;

import imedix.saMiX.dao.PatientQueueInfoRepository;
import imedix.saMiX.dao.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class PatientQueueInfoService {
    @Autowired
    private PatientQueueInfoRepository patientQueueInfoRepository;

    @Autowired
    private UserRepository userRepository;

    public boolean isPatientInLPatQ(String patid){
        int count = patientQueueInfoRepository.getLPatQueueCount(patid);
        if(count > 0){
            return true;
        }else{
            return false;
        }
    }

    public boolean isPatientInLPatQ(String patid, String doc_reg_no){
        int count = patientQueueInfoRepository.getLPatQueueCount(patid, doc_reg_no);
        if(count > 0){
            return true;
        }else{
            return false;
        }
    }

    public List<Map<String,Object>> getLocalPatientQueue(String docrgno){
        List<Map<String,Object>> lpatq = patientQueueInfoRepository.getLocalPatientQueue(docrgno);
        return formatPatientQueue(lpatq);
    }

    public List<Map<String,Object>> getAllPatientsForPsychologist(){
        List<Map<String,Object>> patients = patientQueueInfoRepository.getAllPatientsForPsychologist();
        return formatPatientQueue(patients);
    }

    private List<Map<String,Object>> formatPatientQueue(List<Map<String,Object>> lpatq){
        Map<String,String> gender = new HashMap<>();
        gender.put("M","Male");
        gender.put("F","Female");
        gender.put("O", "Other");

        lpatq.forEach(l-> {
            Object sex = l.get("sex");
            l.put("sex", sex == null ? "" : gender.getOrDefault(sex.toString(), sex.toString()));
            //if(l.get("session") == null){
            l.put("session", "");
            //}
            // calculate age
            if(l.get("dateofbirth") != null) {
                String _dob = l.get("dateofbirth").toString().substring(0, 10);
                LocalDate dob = LocalDate.parse(_dob, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
                Period period = Period.between(dob, LocalDate.now());
                int years = period.getYears();
                int months = period.getMonths();
                int days = period.getDays();
                String age = String.format("%d years", years);
                if (months > 0) {
                    age += String.format(", %d months", months);
                }
                if (days > 0) {
                    age += String.format(", %d days", days);
                }
                l.put("age", age);
            }else{
                l.put("age", "");
            }
            // online/offline information
//            if(iMediXWebSocket.isPatientLoggedIn(l.get("pat_id").toString()))
//                l.put("online", "yes");
//            else{
//                l.put("online", "no");
//            }
            l.put("online", "no");
        });
        lpatq.forEach(l -> l.remove("dateofbirth"));

        return lpatq;
    }



}

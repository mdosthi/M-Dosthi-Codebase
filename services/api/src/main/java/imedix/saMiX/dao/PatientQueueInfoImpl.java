package imedix.saMiX.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Locale;
import java.util.Map;

@Repository
public class PatientQueueInfoImpl implements PatientQueueInfoRepository{
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public int getLPatQueueCount(String patid) {
        String sql = "select count(*) as tq from lpatq where delflag=? and pat_id=?";
        return jdbcTemplate.queryForObject(sql, Integer.class, "N", patid);
    }

    @Override
    public int getLPatQueueCount(String patid, String doc_reg_no) {
        String sql = "select count(*) as tq from lpatq where delflag=? and pat_id=? and assigneddoc=?";
        return jdbcTemplate.queryForObject(sql, Integer.class, "N", patid, doc_reg_no);
    }

    @Override
    public List<Map<String, Object>> getLocalPatientQueue(String docrgno) {
        String sql = "select lpatq.pat_id, concat_ws(' ',m.pat_name,m.m_name,m.l_name) as name, m.dateofbirth, m.sex, " +
                "date_format(lpatq.appdate, '%d-%m-%Y %H:%i') as appointment_date, date_format(lpatq.entrydate, '%d-%m-%Y %H:%i') as entry_date from lpatq inner join med m on lpatq.pat_id = m.pat_id " +
                "where upper(lpatq.assigneddoc)=? AND upper(lpatq.delflag)='N' and " +
                "DATE(lpatq.appdate) <= DATE(NOW()) order by lpatq.appdate desc, lpatq.entrydate;";
        return jdbcTemplate.queryForList(sql, docrgno == null ? null : docrgno.trim().toUpperCase(Locale.ROOT));
    }

    @Override
    public List<Map<String, Object>> getAllPatientsForPsychologist() {
        String sql = "select m.pat_id, concat_ws(' ',m.pat_name,m.m_name,m.l_name) as name, m.dateofbirth, m.sex, " +
                "NULL as appointment_date, NULL as entry_date " +
                "from med m order by m.pat_id";
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> getPendingAppointments(String docrgno) {
        String sql = "select lpatq.pat_id, concat(med.pat_name, ' ', med.l_name) as name, " +
                "DATE(lpatq.entrydate) as entry_date " +
                "from lpatq inner join med on lpatq.pat_id=med.pat_id " +
                "where lpatq.appdate IS NULL and lpatq.assigneddoc=?";
        return jdbcTemplate.queryForList(sql, docrgno);
    }

    @Override
    public Map<String, Object> getQueueInfo(String patid) {
        String sql = "select * from lpatq where pat_id=?";
        Map<String,Object> res = jdbcTemplate.queryForMap(sql,patid);
        return res;
    }
}

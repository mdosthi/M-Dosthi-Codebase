package imedix.saMiX.model;

public class ServiceEnrollment {
    //service_id | subject_id | sid  | start_date | end_date
    private String service_id;
    private String subject_id;
    private String sid;
    private String start_date;
    private String end_date;

    public ServiceEnrollment(String service_id, String subject_id, String sid, String start_date, String end_date) {
        this.service_id = service_id;
        this.subject_id = subject_id;
        this.sid = sid;
        this.start_date = start_date;
        this.end_date = end_date;
    }

    public ServiceEnrollment() {
    }

    public String getService_id() {
        return service_id;
    }

    public void setService_id(String service_id) {
        this.service_id = service_id;
    }

    public String getSubject_id() {
        return subject_id;
    }

    public void setSubject_id(String subject_id) {
        this.subject_id = subject_id;
    }

    public String getSid() {
        return sid;
    }

    public void setSid(String sid) {
        this.sid = sid;
    }

    public String getStart_date() {
        return start_date;
    }

    public void setStart_date(String start_date) {
        this.start_date = start_date;
    }

    public String getEnd_date() {
        return end_date;
    }

    public void setEnd_date(String end_date) {
        this.end_date = end_date;
    }

    @Override
    public String toString() {
        return "ServiceEnrollment{" +
                "service_id='" + service_id + '\'' +
                ", subject_id='" + subject_id + '\'' +
                ", sid='" + sid + '\'' +
                ", start_date='" + start_date + '\'' +
                ", end_date='" + end_date + '\'' +
                '}';
    }
}

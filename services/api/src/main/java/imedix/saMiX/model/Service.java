package imedix.saMiX.model;

public class Service {
    //service_id | sname        | description         | start_date | end_date
    private String service_id;
    private String sname;
    private String description;
    private String sid;

    public Service(String service_id, String sname, String description, String sid) {
        this.service_id = service_id;
        this.sname = sname;
        this.description = description;
        this.sid = sid;
    }

    public Service() {
    }

    public String getService_id() {
        return service_id;
    }

    public void setService_id(String service_id) {
        this.service_id = service_id;
    }

    public String getSname() {
        return sname;
    }

    public void setSname(String sname) {
        this.sname = sname;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getSid() {
        return sid;
    }

    public void setSid(String sid) {
        this.sid = sid;
    }



    @Override
    public String toString() {
        return "Service{" +
                "service_id='" + service_id + '\'' +
                ", sname='" + sname + '\'' +
                ", description='" + description + '\'' +
                ", sid='" + sid + '\'' +
                '}';
    }
}
package imedix.saMiX.model;

// rid  | subject_id | survey_datetime     | sid  | record_type | survey_data
// rid  | subject_id | survey_datetime     | sid  | record_type | survey_data   | image | voice | userid | username
public class Record {
    private String rid;
    private String subject_id;
    private String survey_datetime;

    private String sid;
    private String record_type;
    private String survey_data;
    private String instance_time;

    private String image;
    private String voice;
    private String userid;
    private String username;

    public Record(String rid, String subject_id, String survey_datetime,String sid,String record_type, String survey_data, String image, String voice, String userid, String username, String instance_time) {
        this.rid = rid;
        this.subject_id = subject_id;
        this.survey_datetime = survey_datetime;
        this.sid = sid;
        this.record_type = record_type;
        this.survey_data = survey_data;
        //String image, String voice, String userid, String username
        this.image=image;
        this.voice=voice;
        this.userid=userid;
        this.username=username;
        this.instance_time = instance_time;
    }

    public Record() {
    }

    public String getSid() {
        return sid;
    }

    public void setSid(String sid) {
        this.sid = sid;
    }

    public String getRecord_type() {
        return record_type;
    }

    public void setRecord_type(String record_type) {
        this.record_type = record_type;
    }


    public String getRid() {
        return rid;
    }

    public void setRid(String rid) {
        this.rid = rid;
    }

    public String getSubject_id() {
        return subject_id;
    }

    public void setSubject_id(String subject_id) {
        this.subject_id = subject_id;
    }

    public String getSurvey_datetime() {
        return survey_datetime;
    }

    public void setSurvey_datetime(String survey_datetime) {
        this.survey_datetime = survey_datetime;
    }

    public String getSurvey_data() {
        return survey_data;
    }

    public void setSurvey_data(String survey_data) {
        this.survey_data = survey_data;
    }

    public String getInstance_time() {
        return instance_time;
    }

    public void setInstance_time(String instance_time) {
        this.instance_time = instance_time;
    }

    public String getImage(){ return image; }
    public void setImage(String image){ this.image=image; }

    public String getVoice(){ return voice; }
    public void setVoice(String voice){ this.voice=voice; }

    public String getUserid(){ return userid; }
    public void setUserid(String userid){ this.userid=userid; }

    public String getUsername(){ return username; }
    public void setUsername(String username){ this.username=username; }


    @Override
    public String toString() {
        return "Record{" +
                "rid='" + rid + '\'' +
                ", subject_id='" + subject_id + '\'' +
                ", survey_datetime='" + survey_datetime + '\'' +
                ", sid='" + sid + '\'' +
                ", record_type='" + record_type + '\'' +
                ", survey_data='" + survey_data + '\'' +
                ", image='" + image + '\'' +
                ", voice='" + voice + '\'' +
                ", userid='" + userid + '\'' +
                ", username='" + username + '\'' +
                ", instance_time='" + instance_time + '\'' +
                '}';
    }
}
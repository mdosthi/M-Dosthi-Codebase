package imedix.saMiX.model;
//name          | subject_id | age  | sex  | occupation | zone_id | address   | mobile     | email
//subjectname *  | subject_id* | spousename | childname | relatives| maritalstatus | village | idtype | idnumber | age * | sex *   | caste | religion | image | voice | occupation* | zone_id* | address* | mobile* | email*
public class Subject {
    private String subjectname;
    private String subject_id;
    private String age;
    private String sex;
    private String occupation;
    private String zone_id;
    private String address;
    private String mobile;
    private String email;

    private String spousename;
    private String childname;
    private String relatives;
    private String maritalstatus;
    private String village;
    private String idtype;
    private String idnumber;
    private String caste;
    private String religion;
    private String image;
    private String voice;

    public Subject(String subjectname, String subject_id, String age, String sex, String occupation, String zone_id, String address,String mobile,String email,String spousename,String childname, String relatives, String maritalstatus,String village,String idtype,String idnumber,String caste,String religion,String image,String voice) {
        this.subjectname = subjectname;
        this.subject_id = subject_id;
        this.age = age;
        this.sex = sex;
        this.occupation = occupation;
        this.zone_id = zone_id;
        this.address = address;
        this.mobile = mobile;
        this.email = email;
        this.spousename = spousename;
        this.childname = childname;
        this.relatives = relatives;
        this.maritalstatus = maritalstatus;
        this.village = village;
        this.idtype = idtype;
        this.idnumber = idnumber;
        this.caste = caste;
        this.religion = religion;
        this.image = image;
        this.voice = voice;



    }

    public Subject() {
    }
    public String getCaste() {
        return caste;
    }

    public void setCaste(String caste) {
        this.caste = caste;
    }

    public String getReligion() {
        return religion;
    }

    public void setReligion(String religion) {
        this.religion = religion;
    }
    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }
    public String getVoice() {
        return voice;
    }

    public void setVoice(String voice) {
        this.voice = voice;
    }
    public String getIdnumber() {
        return idnumber;
    }

    public void setIdnumber(String idnumber) {
        this.idnumber = idnumber;
    }

    public String getVillage() {
        return village;
    }

    public void setVillage(String village) {
        this.village = village;
    }


    public String getIdtype() {
        return idtype;
    }

    public void setIdtype(String idtype) {
        this.idtype = idtype;
    }

    public String getMaritalstatus() {
        return maritalstatus;
    }

    public void setMaritalstatus(String maritalstatus) {
        this.maritalstatus = maritalstatus;
    }

    public String getChildname() {
        return childname;
    }

    public void setChildname(String childname) {
        this.childname = childname;
    }
    public String getSpousename() {
        return spousename;
    }

    public void setSpousename(String spousename) {
        this.spousename = spousename;
    }

    public String getRelatives() { return relatives; }
    public void setRelatives(String relatives) { this.relatives=relatives; }

    public String getSubjectname() {
        return subjectname;
    }

    public void setSubjectname(String subjectname) {
        this.subjectname = subjectname;
    }

    public String getSubject_id() {
        return subject_id;
    }

    public void setSubject_id(String subject_id) {
        this.subject_id = subject_id;
    }

    public String getAge() {
        return age;
    }

    public void setAge(String age) {
        this.age = age;
    }

    public String getSex() {
        return sex;
    }

    public void setSex(String sex) {
        this.sex = sex;
    }

    public String getOccupation() {
        return occupation;
    }

    public void setOccupation(String occupation) {
        this.occupation = occupation;
    }

    public String getZone_id() {
        return zone_id;
    }

    public void setZone_id(String zone_id) {
        this.zone_id = zone_id;
    }



    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }


    public String getMobile() {
        return mobile;
    }

    public void setMobile(String mobile) {
        this.mobile = mobile;
    }

    public String getEmail()
    {
        return email;
    }
    public void setEmail(String email)
    {
        this.email=email;
    }

    @Override
    public String toString() {
        return "Subject{" +
                "subjectname='" + subjectname + '\'' +
                ", subject_id='" + subject_id + '\'' +
                ", age='" + age + '\'' +
                ", sex='" + sex + '\'' +
                ", occupation='" + occupation + '\'' +
                ", zone_id='" + zone_id + '\'' +
                ", address='" + address + '\'' +
                ", mobile='" + mobile + '\'' +
                ", email='" + email + '\'' +
                ", spousename='" + spousename + '\'' +
                ", childname='" + childname + '\'' +
                ", relatives='" + relatives + '\'' +
                ", maritalstatus='" + maritalstatus + '\'' +
                ", idtype='" + idtype + '\'' +
                ", idnumber='" + idnumber + '\'' +
                ", caste='" + caste + '\'' +
                ", religion='" + religion + '\'' +
                ", image='" + image + '\'' +
                ", voice='" + voice + '\'' +
                '}';
    }
}
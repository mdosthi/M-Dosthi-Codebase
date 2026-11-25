package imedix.saMiX.model;

public class Survey {
    private String fid;
    private String sid;
    private String source_type;
    private String attribute_name;
    private String attribute_datatype;
    private String attribute_unit;
    private String required_value;

    public Survey(String fid, String sid, String source_type, String attribute_name, String attribute_datatype, String attribute_unit, String required_value) {
        this.fid = fid;
        this.sid = sid;
        this.source_type=source_type;
        this.attribute_name = attribute_name;
        this.attribute_datatype = attribute_datatype;
        this.attribute_unit = attribute_unit;
        this.required_value = required_value;
    }

    public Survey() {
    }

    public String getSource_type() {
        return source_type;
    }

    public void setSource_type(String source_type) {
        this.source_type = source_type;
    }

    public String getFid() {
        return fid;
    }

    public void setFid(String fid) {
        this.fid = fid;
    }

    public String getSid() {
        return sid;
    }

    public void setSid(String sid) {
        this.sid = sid;
    }

    public String getAttribute_name() {
        return attribute_name;
    }

    public void setAttribute_name(String attribute_name) {
        this.attribute_name = attribute_name;
    }

    public String getAttribute_datatype() {
        return attribute_datatype;
    }

    public void setAttribute_datatype(String attribute_datatype) {
        this.attribute_datatype = attribute_datatype;
    }

    public String getAttribute_unit() {
        return attribute_unit;
    }

    public void setAttribute_unit(String attribute_unit) {
        this.attribute_unit = attribute_unit;
    }

    public String getRequired_value() {
        return required_value;
    }

    public void setRequired_value(String required_value) {
        this.required_value = required_value;
    }

    @Override
    public String toString() {
        return "Survey{" +
                "fid='" + fid + '\'' +
                ", sid='" + sid + '\'' +
                ", source_type='" + source_type + '\'' +
                ", attribute_name='" + attribute_name + '\'' +
                ", attribute_datatype='" + attribute_datatype + '\'' +
                ", attribute_unit='" + attribute_unit + '\'' +
                ", required_value='" + required_value + '\'' +
                '}';
    }
}
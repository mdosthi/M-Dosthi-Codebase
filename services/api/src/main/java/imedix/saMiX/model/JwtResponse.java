package imedix.saMiX.model;

public class JwtResponse {
    private String jwtToken;
    private String type;
    private String name;

    private String userid;
    private String status;
    private String message;
    private int dpdpAgreed;



    public JwtResponse(String jwtToken, String type, String name, String userid, String status, String message) {
        this.jwtToken = jwtToken;
        this.type = type;
        this.name = name;
        this.userid= userid;
        this.status = status;
        this.message = message;
        this.dpdpAgreed = 0;

    }

    //new 7-arg constructor- for successful login
    public JwtResponse(String jwtToken, String type, String name, String userid, String status, String message, int dpdpAgreed){
        this.jwtToken = jwtToken;
        this.type = type;
        this.name = name;
        this.userid = userid;
        this.status = status;
        this.message = message;
        this.dpdpAgreed =  dpdpAgreed;
    }

    public JwtResponse() {
    }

    public String getJwtToken() {
        return jwtToken;
    }

    public void setJwtToken(String jwtToken) {
        this.jwtToken = jwtToken;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getName() {
        return name;
    }

    public String getUserid() {
        return userid;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public int getDpdpAgreed() {
        return dpdpAgreed;
    }

    public void setDpdpAgreed(int dpdpAgreed) {
        this.dpdpAgreed = dpdpAgreed;
    }
}

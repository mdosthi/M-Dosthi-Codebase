package imedix.saMiX.model;

public class JwtReqest {
    private String username;
    private String password;

    public JwtReqest(String username, String password) {
        this.username = username;
        this.password = password;
    }

    public JwtReqest() {
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }



    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}

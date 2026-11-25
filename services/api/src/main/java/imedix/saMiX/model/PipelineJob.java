package imedix.saMiX.model;

public class PipelineJob {
    private Long id;
    private String patId;
    private String sessionId;      // null means run for all sessions
    private boolean forceReannotate;

    public PipelineJob() {}

    public PipelineJob(Long id, String patId, String sessionId, boolean forceReannotate) {
        this.id = id;
        this.patId = patId;
        this.sessionId = sessionId;
        this.forceReannotate = forceReannotate;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getPatId() { return patId; }
    public void setPatId(String patId) { this.patId = patId; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public boolean isForceReannotate() { return forceReannotate; }
    public void setForceReannotate(boolean forceReannotate) { this.forceReannotate = forceReannotate; }
}

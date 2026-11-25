package imedix.saMiX.model;

import  java.time.LocalTime;
public class ChatControl {
    private String patId;
    private Integer dailyChatLimit;
    private Integer maxSessionDuration;
    private Integer minSessionInterval;
    private LocalTime blackoutStartTime;
    private LocalTime blackoutEndTime;
    private String blackoutDays;
    private String chatType;

    // Default constructor
    public ChatControl() {
        this.dailyChatLimit = 3;
        this.maxSessionDuration = 1800;
        this.minSessionInterval = 3600;
        this.chatType = "original";
    }

    // Constructor with pat_id
    public ChatControl(String patId) {
        this();
        this.patId = patId;
    }

    // Full constructor
    public ChatControl(String patId, Integer dailyChatLimit, Integer maxSessionDuration,
                       Integer minSessionInterval, LocalTime blackoutStartTime,
                       LocalTime blackoutEndTime, String blackoutDays) {
        this.patId = patId;
        this.dailyChatLimit = dailyChatLimit;
        this.maxSessionDuration = maxSessionDuration;
        this.minSessionInterval = minSessionInterval;
        this.blackoutStartTime = blackoutStartTime;
        this.blackoutEndTime = blackoutEndTime;
        this.blackoutDays = blackoutDays;
    }

    // Getters and Setters
    public String getPatId() {
        return patId;
    }

    public void setPatId(String patId) {
        this.patId = patId;
    }

    public Integer getDailyChatLimit() {
        return dailyChatLimit;
    }

    public void setDailyChatLimit(Integer dailyChatLimit) {
        this.dailyChatLimit = dailyChatLimit;
    }

    public Integer getMaxSessionDuration() {
        return maxSessionDuration;
    }

    public void setMaxSessionDuration(Integer maxSessionDuration) {
        this.maxSessionDuration = maxSessionDuration;
    }

    public Integer getMinSessionInterval() {
        return minSessionInterval;
    }

    public void setMinSessionInterval(Integer minSessionInterval) {
        this.minSessionInterval = minSessionInterval;
    }

    public LocalTime getBlackoutStartTime() {
        return blackoutStartTime;
    }

    public void setBlackoutStartTime(LocalTime blackoutStartTime) {
        this.blackoutStartTime = blackoutStartTime;
    }

    public LocalTime getBlackoutEndTime() {
        return blackoutEndTime;
    }

    public void setBlackoutEndTime(LocalTime blackoutEndTime) {
        this.blackoutEndTime = blackoutEndTime;
    }

    public String getBlackoutDays() {
        return blackoutDays;
    }

    public void setBlackoutDays(String blackoutDays) {
        this.blackoutDays = blackoutDays;
    }

    public String getChatType() {
        return chatType;
    }

    public void setChatType(String chatType) {
        this.chatType = chatType;
    }
}

package imedix.saMiX.model;

import java.time.LocalDateTime;
public class ChatMessage {
    private String messageId;
    private String sessionId;
    private Integer messageSequence;
    private String senderType;
    private String messageContent;
    private LocalDateTime timestamp;
    private Boolean isRead;
    private Integer responseTime;
    private String fileFormat;
    private Integer fileSize;

    // Default constructor
    public ChatMessage() {
        this.isRead = false;
        this.fileFormat = "json";
    }

    // Constructor with essential fields
    public ChatMessage(String messageId, String sessionId, Integer messageSequence,
                       String senderType, String messageContent) {
        this();
        this.messageId = messageId;
        this.sessionId = sessionId;
        this.messageSequence = messageSequence;
        this.senderType = senderType;
        this.messageContent = messageContent;
        this.timestamp = LocalDateTime.now();
    }

    // Full constructor
    public ChatMessage(String messageId, String sessionId, Integer messageSequence,
                       String senderType, String messageContent, LocalDateTime timestamp,
                       Boolean isRead, Integer responseTime, String fileFormat, Integer fileSize) {
        this.messageId = messageId;
        this.sessionId = sessionId;
        this.messageSequence = messageSequence;
        this.senderType = senderType;
        this.messageContent = messageContent;
        this.timestamp = timestamp;
        this.isRead = isRead;
        this.responseTime = responseTime;
        this.fileFormat = fileFormat;
        this.fileSize = fileSize;
    }

    // Getters and Setters
    public String getMessageId() {
        return messageId;
    }

    public void setMessageId(String messageId) {
        this.messageId = messageId;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public Integer getMessageSequence() {
        return messageSequence;
    }

    public void setMessageSequence(Integer messageSequence) {
        this.messageSequence = messageSequence;
    }

    public String getSenderType() {
        return senderType;
    }

    public void setSenderType(String senderType) {
        this.senderType = senderType;
    }

    public String getMessageContent() {
        return messageContent;
    }

    public void setMessageContent(String messageContent) {
        this.messageContent = messageContent;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }

    public Integer getResponseTime() {
        return responseTime;
    }

    public void setResponseTime(Integer responseTime) {
        this.responseTime = responseTime;
    }

    public String getFileFormat() {
        return fileFormat;
    }

    public void setFileFormat(String fileFormat) {
        this.fileFormat = fileFormat;
    }

    public Integer getFileSize() {
        return fileSize;
    }

    public void setFileSize(Integer fileSize) {
        this.fileSize = fileSize;
    }
}

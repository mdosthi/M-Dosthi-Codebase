//package imedix.saMiX.model;
//
//import java.time.LocalDate;
//import java.time.LocalDateTime;
//
//public class ChatSession {
//    private String sessionId;
//    private String patId;
//    private LocalDate sessionDate;
//    private LocalDateTime startTime;
//    private LocalDateTime endTime;
//    private Integer duration;
//    private String sessionNotes;
//    private String sessionStatus;
//
//    // Default constructor
//    public ChatSession() {}
//
//    // Constructor with essential fields
//    public ChatSession(String sessionId, String patId, LocalDateTime startTime, String sessionStatus) {
//        this.sessionId = sessionId;
//        this.patId = patId;
//        this.startTime = startTime;
//        this.sessionStatus = sessionStatus;
//        this.sessionDate = startTime.toLocalDate();
//    }
//
//    // Full constructor
//    public ChatSession(String sessionId, String patId, LocalDate sessionDate,
//                       LocalDateTime startTime, LocalDateTime endTime, Integer duration,
//                       String sessionNotes, String sessionStatus) {
//        this.sessionId = sessionId;
//        this.patId = patId;
//        this.sessionDate = sessionDate;
//        this.startTime = startTime;
//        this.endTime = endTime;
//        this.duration = duration;
//        this.sessionNotes = sessionNotes;
//        this.sessionStatus = sessionStatus;
//    }
//
//    // Getters and Setters
//    public String getSessionId() {
//        return sessionId;
//    }
//
//    public void setSessionId(String sessionId) {
//        this.sessionId = sessionId;
//    }
//
//    public String getPatId() {
//        return patId;
//    }
//
//    public void setPatId(String patId) {
//        this.patId = patId;
//    }
//
//    public LocalDate getSessionDate() {
//        return sessionDate;
//    }
//
//    public void setSessionDate(LocalDate sessionDate) {
//        this.sessionDate = sessionDate;
//    }
//
//    public LocalDateTime getStartTime() {
//        return startTime;
//    }
//
//    public void setStartTime(LocalDateTime startTime) {
//        this.startTime = startTime;
//    }
//
//    public LocalDateTime getEndTime() {
//        return endTime;
//    }
//
//    public void setEndTime(LocalDateTime endTime) {
//        this.endTime = endTime;
//    }
//
//    public Integer getDuration() {
//        return duration;
//    }
//
//    public void setDuration(Integer duration) {
//        this.duration = duration;
//    }
//
//    public String getSessionNotes() {
//        return sessionNotes;
//    }
//
//    public void setSessionNotes(String sessionNotes) {
//        this.sessionNotes = sessionNotes;
//    }
//
//    public String getSessionStatus() {
//        return sessionStatus;
//    }
//
//    public void setSessionStatus(String sessionStatus) {
//        this.sessionStatus = sessionStatus;
//    }
//}

package imedix.saMiX.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class ChatSession {
    private String sessionId;
    private String patId;
    private LocalDate sessionDate;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Integer duration;
    private String sessionNotes;
    private String sessionStatus;
    private String languagePreference; // "en" or "bn" — locked in when session is created

    // Default constructor
    public ChatSession() {}

    // Constructor with essential fields
    public ChatSession(String sessionId, String patId, LocalDateTime startTime, String sessionStatus) {
        this.sessionId = sessionId;
        this.patId = patId;
        this.startTime = startTime;
        this.sessionStatus = sessionStatus;
        this.sessionDate = startTime.toLocalDate();
        this.languagePreference = "en"; // default
    }

    // Constructor with essential fields + language
    public ChatSession(String sessionId, String patId, LocalDateTime startTime, String sessionStatus, String languagePreference) {
        this.sessionId = sessionId;
        this.patId = patId;
        this.startTime = startTime;
        this.sessionStatus = sessionStatus;
        this.sessionDate = startTime.toLocalDate();
        this.languagePreference = (languagePreference != null && !languagePreference.isBlank()) ? languagePreference : "en";
    }

    // Full constructor
    public ChatSession(String sessionId, String patId, LocalDate sessionDate,
                       LocalDateTime startTime, LocalDateTime endTime, Integer duration,
                       String sessionNotes, String sessionStatus, String languagePreference) {
        this.sessionId = sessionId;
        this.patId = patId;
        this.sessionDate = sessionDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.duration = duration;
        this.sessionNotes = sessionNotes;
        this.sessionStatus = sessionStatus;
        this.languagePreference = (languagePreference != null && !languagePreference.isBlank()) ? languagePreference : "en";
    }

    // Getters and Setters
    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public String getPatId() {
        return patId;
    }

    public void setPatId(String patId) {
        this.patId = patId;
    }

    public LocalDate getSessionDate() {
        return sessionDate;
    }

    public void setSessionDate(LocalDate sessionDate) {
        this.sessionDate = sessionDate;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public Integer getDuration() {
        return duration;
    }

    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    public String getSessionNotes() {
        return sessionNotes;
    }

    public void setSessionNotes(String sessionNotes) {
        this.sessionNotes = sessionNotes;
    }

    public String getSessionStatus() {
        return sessionStatus;
    }

    public void setSessionStatus(String sessionStatus) {
        this.sessionStatus = sessionStatus;
    }

    public String getLanguagePreference() {
        return languagePreference;
    }

    public void setLanguagePreference(String languagePreference) {
        this.languagePreference = (languagePreference != null && !languagePreference.isBlank()) ? languagePreference : "en";
    }
}
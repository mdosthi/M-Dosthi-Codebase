package imedix.saMiX.dao;

import imedix.saMiX.model.*;
import imedix.saMiX.model.Record; // Resolve ambiguity with java.lang.Record on modern JDKs

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface UserRepository {
    public String encodePassword(String password);
    public Map<String, Object> getUserInfo(String username);
    public Map<String, Object> getUserDetailsByIdentifier(String identifier);
    boolean changePassword(String loginId, String currentPassword, String newPassword);
    boolean updatePassword(String loginId, String newPassword);
    List<Map<String, Object>> getAllForms();
    List<Map<String, Object>> getPrescribedFormsForPatient(String patId);
    Map<String, Object> getRecordLogByRid(String rid);
    List<Map<String, Object>> getPastResponsesBySubjectAndSid(String subjectId, String sid);
    //boolean updatePassword(String loginId, String hashedNewPassword);
    public boolean updateUserDetails(Map<String, String> userDetails);
    // Add RCT enrollment check method
    public boolean isPatientEnrolledInRCT(String patId);
    // Chat Control Management
    public ChatControl getChatControls(String patId);
    public boolean updateChatControls(String patId, ChatControl chatControl);
    public String getChatType(String patId);
    public int getCompletedSessionCount(String patId);
    public String getLatestDeltaSummary(String patId);
    boolean validateChatSession(String patId);
    //user agreement check
    public boolean updateDpdpAgreed(String uid);
    public boolean withdrawDpdpConsent(String uid);
    // Helper Methods
    boolean isPatientExists(String patId);
    Integer getTodaySessionCount(String patId);
    LocalDateTime getLastSessionEndTime(String patId);

    // Chat Session Management
    public String startChatSession(String patId, String languagePreference);
    public boolean endChatSession(String sessionId, String sessionNotes);
    public List<ChatSession> getChatSessions(String patId, Integer limit, Integer offset);
    public ChatSession getActiveSession(String patId);
    // Chat Messaging
    public String sendChatMessage(String sessionId, String senderType, String messageContent);
    public List<ChatMessage> getChatMessages(String sessionId, Integer limit, Integer offset);
    public List<ChatMessage> getRecentChatMessages(String sessionId, int limit);
    public ChatMessage getAssistantMessageForPatient(String messageId, String patId);
    public boolean markMessagesAsRead(String sessionId, List<String> messageIds);
    public Integer getUnreadMessageCount(String patId);
    // Terminal command logging
    public void logTerminalCommand(String sessionId, String command, String output);
    public ChatSession getChatSessionById(String sessionId);
    public List<Map<String, Object>> getTerminalHistory(String sessionId);
    public Map<String, Object> getPatientInfo(String userid);
    public Map<String, Object> getSubjectInfo(String subject_id);
    public boolean createNewSurvey(Map<String, String> data);
    public List<String> getAllocateZone(String userid);
    public Map<String, Object> getZoneInfo(String zone_id);
    public List<String> getAllocateSurveyor(String userid);
    public Map<String, Object> getSurveyInfo(String sid);
    public List<Survey> getFieldProjectInfo(String sid);
    public boolean createFieldEntry(Map<String, String> data);
    public String getFieldEntriesValue(String rid, String fid);
    public String createRecordLog(Map<String, String> data);
    public String updateSurveyDataRecordLog(Map<String, String> data);
    public List<Record> getRecordLogBySid(String sid);
    public List<Record> getRecordLogBySubjectId(String subject_id);
    public List<Record> getRecordLogBySubjectIdInstanceTime(String subject_id, String InstanceTime);
    public String InsertSubject(Map<String, String> data);

    public List<Subject> getSubjectInfoByZone(String zone_id);

    public String createService(Map<String, String> data);
    public boolean newServiceEnrollment(Map<String, String> data);
    //public List<String> getAllServiceEnrollment_byServiceId(String service_id);
    public List<String> getAllServiceEnrollment_byServiceId_andSid(String service_id, String sid);
    public List<Service> getAllServices();
    public List<ServiceEnrollment> getAllServiceEnrollment_byServiceId(String service_id);
    public boolean createNewSurveyFields(Map<String, String> data);
    public boolean createAllocateSurveyor(Map<String, String> data);
    public boolean createAllocateZone(Map<String, String> data);
    public boolean updateFieldEntry(Map<String, String> data);
    public boolean createNewEdosthiLogin(Map<String, String> data);

    void afterPropertiesSet() throws Exception;

    // App metrics & user progress tracking
    public boolean incrementOpenCount(String userid, String itemId, String itemType);
    public Map<String, Object> getProgress(String userid, String itemId);
    public List<Map<String, Object>> getAllProgress(String userid);
    public boolean logUserTime(String userid, int timespent, String date);
    public boolean setupDb();

    // Annotation pipeline job queue
    void enqueuePipelineJob(String patId);
    void enqueuePipelineJob(String patId, String sessionId, boolean forceReannotate);
    PipelineJob fetchAndLockNextPipelineJob();
    void markPipelineJobCompleted(Long jobId);
    void markPipelineJobFailed(Long jobId, String errorMessage);
    void recoverStalePipelineJobs();
    void deleteSignalForReannotation(String patId, String sessionId);
    Map<String, Object> getPipelineWindow();
    void savePipelineWindow(String startTime, String endTime);
    void deleteOldCompletedPipelineJobs();

}

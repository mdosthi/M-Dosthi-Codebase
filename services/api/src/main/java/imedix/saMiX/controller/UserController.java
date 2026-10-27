package imedix.saMiX.controller;

import imedix.saMiX.dao.UserRepository;
import imedix.saMiX.filter.JwtFilter;
import imedix.saMiX.helper.JwtUtil;
import imedix.saMiX.model.Record;
import imedix.saMiX.model.*;
import imedix.saMiX.service.iMediXUserDetailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcOperations;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import imedix.saMiX.util.SurveyScoreCalculator;

import javax.crypto.spec.SecretKeySpec;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

import java.time.LocalTime;
import java.util.ArrayList;
import imedix.saMiX.model.ChatSession;
import imedix.saMiX.model.ChatControl;
import imedix.saMiX.model.ChatMessage;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.concurrent.TimeUnit;
import imedix.saMiX.service.OllamaService;
import org.springframework.security.crypto.codec.Hex;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.io.File;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.net.URL;
import java.net.URLConnection;
import java.nio.file.Files;
import java.security.*;
import java.security.cert.X509Certificate;


@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping(path = "/api/user")
public class UserController {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private JwtFilter jwtFilter;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private iMediXUserDetailService imedixUserDetailService;

    @Autowired
    private OllamaService ollamaService;

    @Value("${imedix.center.code}")
    String centerCode;



    private static SecretKeySpec generateMySQLAESKey(final String key, final String encoding) {
        try {
            final byte[] finalKey = new byte[16];
            int i = 0;
            for (byte b : key.getBytes(encoding))
                finalKey[i++ % 16] ^= b;
            return new SecretKeySpec(finalKey, "AES");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }


    @PostMapping("/login")
    public JwtResponse login(@RequestBody JwtReqest jwtReqest) throws Exception {
        try {

            String password = userRepository.encodePassword(jwtReqest.getPassword());

            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            jwtReqest.getUsername(), password
                    )
            );
        } catch (BadCredentialsException e) {
            System.out.println(e.getMessage());
            //throw new Exception("Invalid Credential", e);
            return new JwtResponse("", "", "","", "error", "Invalid Credential");
        }

        final UserDetails userDetails =
                imedixUserDetailService.loadUserByUsername(jwtReqest.getUsername());
        final String token = jwtUtil.generateToken(userDetails);
        Map<String, Object> userinfo = userRepository.getUserInfo(jwtReqest.getUsername());
        System.out.println("Returning response from /api/user/login");
        int dpdpAgreed = userinfo.get("dpdp_agreed") != null ? ((Number) userinfo.get("dpdp_agreed")).intValue() : 0;
        //return new JwtResponse(token, (String) userinfo.get("user_type"), (String) userinfo.get("name"), (String) userinfo.get("userid"), "success", "Login Successful");
        return new JwtResponse(token, (String) userinfo.get("type"), (String) userinfo.get("name"), (String) userinfo.get("uid"), "success", "Login Successful", dpdpAgreed);
    }

    //user agreement
    @PostMapping("/update-dpdp-agreed")
    public Map<String, Object> updateDpdpAgreed(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String uid = req.get("uid");
            if (uid == null || uid.isEmpty()) {
                result.put("status", "error");
                result.put("message", "uid is required");
                return result;
            }
            boolean updated = userRepository.updateDpdpAgreed(uid);
            if (updated) {
                result.put("status", "success");
                result.put("message", "DPDP consent recorded");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to update consent");
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Exception: " + e.getMessage());
        }
        return result;
    }
    @PostMapping("/withdraw-dpdp-consent")
    public Map<String, Object> withdrawDpdpConsent(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String uid = req.get("uid");
            if (uid == null || uid.isEmpty()) {
                result.put("status", "error");
                result.put("message", "uid is required");
                return result;
            }
            boolean updated = userRepository.withdrawDpdpConsent(uid);
            if (updated) {
                result.put("status", "success");
                result.put("message", "DPDP consent withdrawn");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to withdraw consent");
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Exception: " + e.getMessage());
        }
        return result;
    }

    @PostMapping("/get-user-details")
    public Map<String, Object> getUserDetails(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            // Check if either identifier is provided
            String identifier = req.get("identifier");
            String userId = req.get("userId");

            if ((identifier == null || identifier.isEmpty()) && (userId == null || userId.isEmpty())) {
                result.put("status", "error");
                result.put("message", "No valid identifier provided");
                return result;
            }

            // Try both identifiers
            Map<String, Object> userDetails = null;
            if (identifier != null && !identifier.isEmpty()) {
                userDetails = userRepository.getUserDetailsByIdentifier(identifier);
            }
            if (userDetails == null && userId != null && !userId.isEmpty()) {
                userDetails = userRepository.getUserDetailsByIdentifier(userId);
            }

            if (userDetails != null) {
                result.put("status", "success");
                result.put("user-info", userDetails);
            } else {
                result.put("status", "error");
                result.put("message", "User not found");
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving user details: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/update-user-details")
    public Map<String, Object> updateUserDetails(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {

            boolean success = userRepository.updateUserDetails(req);

            // Handle response
            if (success) {
                result.put("status", "success");
                result.put("message", "User details updated successfully");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to update user details");
            }
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error updating user details: " + e.getMessage());
        }

        return result;
    }



    @PostMapping("/change-password")
    public Map<String, Object> changePassword(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String currentPassword = req.get("currentPassword");
            String newPassword = req.get("newPassword");
            String loginId = req.get("loginid");

            // Get user info first
            Map<String, Object> userInfo = userRepository.getUserInfo(loginId);
            if (userInfo == null) {
                result.put("status", "error");
                result.put("message", "User not found");
                return result;
            }

            // Encode and verify current password
            String encodedCurrentPassword = userRepository.encodePassword(currentPassword);
            String storedPassword = (String) userInfo.get("pwd");

            System.out.println("Encoded current password: " + encodedCurrentPassword);
            System.out.println("Stored password: " + storedPassword);

            // Verify current password
            if (!storedPassword.equals(encodedCurrentPassword)) {
                result.put("status", "error");
                result.put("message", "Current password is incorrect");
                return result;
            }

            // Encode and update new password
            String encodedNewPassword = userRepository.encodePassword(newPassword);

            // Call repository method to update password
            boolean updated = userRepository.updatePassword(loginId, encodedNewPassword);

            if (updated) {
                result.put("status", "success");
                result.put("message", "Password updated successfully");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to update password");
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error updating password: " + e.getMessage());
        }

        return result;
    }


    @PostMapping("/get-all-forms")
    public Map<String, Object> getAllForms() {
        Map<String, Object> result = new HashMap<>();

        try {
            List<Map<String, Object>> forms = userRepository.getAllForms();

            if (forms != null && !forms.isEmpty()) {
                result.put("status", "success");
                result.put("forms", forms);
            } else {
                result.put("status", "error");
                result.put("message", "No forms found");
            }
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error retrieving forms: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/get-prescribed-forms-for-patient")
    public Map<String, Object> getPrescribedFormsForPatient(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("message", "Patient ID is required");
                return result;
            }

            List<Map<String, Object>> prescribedForms = userRepository.getPrescribedFormsForPatient(patId);

            if (prescribedForms != null && !prescribedForms.isEmpty()) {
                result.put("status", "success");
                result.put("forms", prescribedForms);
                result.put("message", "Successfully retrieved prescribed forms");
                result.put("count", prescribedForms.size());
            } else {
                result.put("status", "success");
                result.put("forms", new ArrayList<>());
                result.put("message", "No prescribed forms found for this patient");
                result.put("count", 0);
            }
        } catch (Exception e) {
            System.out.println("Error in getPrescribedFormsForPatient endpoint: " + e.getMessage());
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving prescribed forms: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/submit-form-response")
    public Map<String, Object> submitFormResponse(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            // Get form information to determine form type
            String sid = req.get("sid");
            Map<String, Object> formInfo = userRepository.getSurveyInfo(sid);
            String formName = (String) formInfo.get("name");

            // Calculate score based on form type
            String surveyData = req.get("survey_data");
            Integer score = SurveyScoreCalculator.calculateScore(formName, surveyData);

            // Log the calculated score
            System.out.println("Calculated score for " + formName + ": " + score);

            // Create data map matching your existing createRecordLog expectations
            Map<String, String> data = new HashMap<>();
            data.put("subject_id", req.get("pat_id"));
            data.put("survey_data", surveyData);
            data.put("sid", sid);
            data.put("record_type", req.get("record_type"));
            data.put("userid", req.get("userid"));
            data.put("username", req.get("username"));
            data.put("score", score != null ? score.toString() : null);

            String rid = userRepository.createRecordLog(data);

            if (!rid.equals("error")) {
                result.put("status", "success");
                result.put("rid", rid);
                result.put("score", score);
                result.put("message", "Response submitted successfully");

                // Add score interpretation if available
                if (score != null) {
                    String interpretation = SurveyScoreCalculator.getScoreInterpretation(formName, score);
                    result.put("score_interpretation", interpretation);
                }
            } else {
                result.put("status", "error");
                result.put("message", "Failed to submit response");
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error submitting response: " + e.getMessage());
        }

        return result;
    }


    @PostMapping("/get-form-response")
    public Map<String, Object> getFormResponse(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String rid = req.get("rid");

            // Get main response
            Map<String, Object> response = userRepository.getRecordLogByRid(rid);
            if (response != null) {
                result.put("status", "success");
                result.put("response", response);
            } else {
                result.put("status", "error");
                result.put("message", "Response not found");
            }
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error retrieving response: " + e.getMessage());
        }

        return result;
    }


    @PostMapping("/get-past-responses")
    public Map<String, Object> getPastResponses(@RequestBody Map<String,String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String subjectId = req.get("subject_id");
            String sid = req.get("sid");

            List<Map<String, Object>> responses = userRepository.getPastResponsesBySubjectAndSid(subjectId, sid);

            result.put("status", "success");
            result.put("responses", responses);

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error retrieving responses: " + e.getMessage());
        }

        return result;
    }
    //RCT control check
    @PostMapping("/check-rct-enrollment")
    public Map<String, Object> checkRCTEnrollment(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            boolean isEnrolled = userRepository.isPatientEnrolledInRCT(patId);

            result.put("status", "success");
            result.put("is_enrolled", isEnrolled);
            result.put("message", isEnrolled ?
                    "Patient is enrolled in RCT study" :
                    "Patient is not enrolled in RCT study");

            System.out.println("RCT enrollment check for " + patId + ": " + isEnrolled);

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error checking RCT enrollment: " + e.getMessage());
            System.out.println("Error in checkRCTEnrollment: " + e.getMessage());
        }

        return result;
    }
    //Chat Control endpoints

    @PostMapping("/get-chat-controls")
    public Map<String, Object> getChatControls(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            // Debug logging
            System.out.println("Getting chat controls for patient: " + patId);

            ChatControl controls = userRepository.getChatControls(patId);

            // Debug logging
            System.out.println("Retrieved chat controls: " + controls);

            result.put("status", "success");

            // Create a proper controls object matching frontend expectations
            Map<String, Object> controlsMap = new HashMap<>();
            controlsMap.put("pat_id", controls.getPatId());
            controlsMap.put("daily_chat_limit", controls.getDailyChatLimit());
            controlsMap.put("max_session_duration", controls.getMaxSessionDuration());
            controlsMap.put("min_session_interval", controls.getMinSessionInterval());
            controlsMap.put("blackout_start_time", controls.getBlackoutStartTime());
            controlsMap.put("blackout_end_time", controls.getBlackoutEndTime());
            controlsMap.put("blackout_days", controls.getBlackoutDays());

            result.put("controls", controlsMap);
            result.put("message", "Chat controls retrieved successfully");

            System.out.println("Returning chat controls response: " + result);

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving chat controls: " + e.getMessage());
            System.out.println("Error in getChatControls: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/check-session-duration")
    public Map<String, Object> checkSessionDuration(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            // Get active session
            ChatSession activeSession = userRepository.getActiveSession(patId);

            if (activeSession == null) {
                result.put("status", "success");
                result.put("session_active", false);
                result.put("message", "No active session found");
                return result;
            }

            // Get chat controls
            ChatControl controls = userRepository.getChatControls(patId);
            Integer maxDuration = controls.getMaxSessionDuration();

            if (maxDuration == null || maxDuration <= 0) {
                result.put("status", "success");
                result.put("session_active", true);
                result.put("duration_unlimited", true);
                result.put("session_id", activeSession.getSessionId());
                return result;
            }

            // Calculate current session duration
            LocalDateTime now = LocalDateTime.now();
            long sessionDurationSeconds = ChronoUnit.SECONDS.between(activeSession.getStartTime(), now);
            long remainingSeconds = maxDuration - sessionDurationSeconds;

            System.out.println("Session duration check for " + patId +
                    ": " + sessionDurationSeconds + "/" + maxDuration + " seconds");

            if (sessionDurationSeconds >= maxDuration) {
                // Session has exceeded maximum duration - end it
                boolean ended = userRepository.endChatSession(activeSession.getSessionId(),
                        "Session automatically ended - exceeded maximum duration of " + maxDuration + " seconds");

                if (ended) {
                    triggerAnnotatePipeline(patId, activeSession.getSessionId());
                }

                result.put("status", "success");
                result.put("session_active", false);
                result.put("session_expired", true);
                result.put("message", "Session has been ended due to exceeding maximum duration");
                result.put("duration_exceeded", true);

                System.out.println("Auto-ended session " + activeSession.getSessionId() + " due to duration limit");
            } else {
                result.put("status", "success");
                result.put("session_active", true);
                result.put("session_id", activeSession.getSessionId());
                result.put("duration_seconds", sessionDurationSeconds);
                result.put("max_duration_seconds", maxDuration);
                result.put("remaining_seconds", remainingSeconds);
                result.put("duration_percentage", (double) sessionDurationSeconds / maxDuration);
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error checking session duration: " + e.getMessage());
            System.out.println("Error in checkSessionDuration: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/update-chat-controls")
    public Map<String, Object> updateChatControls(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            ChatControl chatControl = new ChatControl(patId);

            // Parse control settings from request
            if (req.get("daily_chat_limit") != null) {
                chatControl.setDailyChatLimit(Integer.parseInt(req.get("daily_chat_limit")));
            }
            if (req.get("max_session_duration") != null) {
                chatControl.setMaxSessionDuration(Integer.parseInt(req.get("max_session_duration")));
            }
            if (req.get("min_session_interval") != null) {
                chatControl.setMinSessionInterval(Integer.parseInt(req.get("min_session_interval")));
            }
            if (req.get("blackout_start_time") != null) {
                chatControl.setBlackoutStartTime(LocalTime.parse(req.get("blackout_start_time")));
            }
            if (req.get("blackout_end_time") != null) {
                chatControl.setBlackoutEndTime(LocalTime.parse(req.get("blackout_end_time")));
            }
            if (req.get("blackout_days") != null) {
                chatControl.setBlackoutDays(req.get("blackout_days"));
            }

            boolean success = userRepository.updateChatControls(patId, chatControl);

            if (success) {
                result.put("status", "success");
                result.put("message", "Chat controls updated successfully");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to update chat controls");
            }

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error updating chat controls: " + e.getMessage());
        }

        return result;
    }
    // Chat Session Management Endpoints

    @PostMapping("/start-chat-session")
    public Map<String, Object> startChatSession(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");
            String languagePreference = req.getOrDefault("language_preference", "en").toString().toLowerCase().trim();
            // Whitelist: only "en" or "bn" are valid
            if (!languagePreference.equals("bn")) {
                languagePreference = "en";
            }
            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            System.out.println("Starting chat session for patient: " + patId);
            //checking rct enrollment
            if (!userRepository.isPatientEnrolledInRCT(patId)){
                result.put("status", "error");
                result.put("error_code", "NOT_ENROLLED_IN_RCT");
                result.put("message", "Patient is not enrolled in the RCT study. Chat feature is not available.");
                System.out.println("Chat session denied - Patient not enrolled in RCT: " + patId);
                return result;
            }  //rct enrollment

            // Validate if chat session can be started
            if (!userRepository.validateChatSession(patId)) {
                result.put("status", "error");
                result.put("error_code", "CHAT_VALIDATION_FAILED");
                result.put("message", "Chat session cannot be started due to restrictions");
                System.out.println("Chat validation failed for patient: " + patId);
                return result;
            }

            // Check if there's already an active session
            ChatSession activeSession = userRepository.getActiveSession(patId);
            if (activeSession != null) {
                result.put("status", "error");
                result.put("error_code", "ACTIVE_SESSION_EXISTS");
                result.put("message", "An active chat session already exists");
                result.put("session_id", activeSession.getSessionId());
                System.out.println("Active session already exists: " + activeSession.getSessionId());
                return result;
            }

            String sessionId = userRepository.startChatSession(patId, languagePreference);

            if (sessionId != null) {
                result.put("status", "success");
                result.put("session_id", sessionId);
                result.put("message", "Chat session started successfully");
                System.out.println("Chat session started successfully: " + sessionId);
            } else {
                result.put("status", "error");
                result.put("message", "Failed to start chat session");
                System.out.println("Failed to start chat session for patient: " + patId);
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error starting chat session: " + e.getMessage());
            System.out.println("Error in startChatSession: " + e.getMessage());
        }

        return result;
    }
    @PostMapping("/end-chat-session")
    public Map<String, Object> endChatSession(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String sessionId = req.get("session_id");
            String sessionNotes = req.get("session_notes");

            if (sessionId == null || sessionId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SESSION_ID");
                result.put("message", "Session ID is required");
                return result;
            }

            ChatSession session = userRepository.getChatSessionById(sessionId);
            boolean success = userRepository.endChatSession(sessionId, sessionNotes);

            if (success) {
                result.put("status", "success");
                result.put("message", "Chat session ended successfully");

                // Trigger annotate pipeline for every ended session so delta summary
                // is always up-to-date for the next session (regardless of chat type).
                if (session != null && session.getPatId() != null) {
                    triggerAnnotatePipeline(session.getPatId(), sessionId);
                }
            } else {
                result.put("status", "error");
                result.put("error_code", "SESSION_NOT_FOUND");
                result.put("message", "Failed to end chat session or session not found");
            }

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error ending chat session: " + e.getMessage());
        }

        return result;
    }

    private void triggerAnnotatePipeline(String patId, String sessionId) {
        try {
            userRepository.enqueuePipelineJob(patId, sessionId, false);
            System.out.println("Annotate pipeline job queued for: " + patId + " session: " + sessionId);
        } catch (Exception e) {
            System.err.println("WARNING - Could not queue annotate pipeline job for " + patId + ": " + e.getMessage());
        }
    }

    @PostMapping("/get-chat-sessions")
    public Map<String, Object> getChatSessions(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");
            Integer limit = req.get("limit") != null ? Integer.parseInt(req.get("limit")) : null;
            Integer offset = req.get("offset") != null ? Integer.parseInt(req.get("offset")) : null;

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            System.out.println("Getting chat sessions for patient: " + patId + ", limit: " + limit + ", offset: " + offset);

            List<ChatSession> sessions = userRepository.getChatSessions(patId, limit, offset);

            // Convert ChatSession objects to Maps for JSON response
            List<Map<String, Object>> sessionMaps = new ArrayList<>();
            for (ChatSession session : sessions) {
                Map<String, Object> sessionMap = new HashMap<>();
                sessionMap.put("session_id", session.getSessionId());
                sessionMap.put("pat_id", session.getPatId());
                sessionMap.put("session_date", session.getSessionDate().toString());
                sessionMap.put("start_time", session.getStartTime().toString());
                sessionMap.put("end_time", session.getEndTime() != null ? session.getEndTime().toString() : null);
                sessionMap.put("duration", session.getDuration());
                sessionMap.put("session_notes", session.getSessionNotes());
                sessionMap.put("session_status", session.getSessionStatus());
                sessionMap.put("language_preference", session.getLanguagePreference());
                sessionMaps.add(sessionMap);
            }

            result.put("status", "success");
            result.put("sessions", sessionMaps);
            result.put("count", sessionMaps.size());
            result.put("message", "Chat sessions retrieved successfully");

            System.out.println("Retrieved " + sessionMaps.size() + " chat sessions");

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving chat sessions: " + e.getMessage());
            System.out.println("Error in getChatSessions: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/get-active-session")
    public Map<String, Object> getActiveSession(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            System.out.println("Getting active session for patient: " + patId);

            ChatSession activeSession = userRepository.getActiveSession(patId);

            result.put("status", "success");
            if (activeSession != null) {
                // Convert ChatSession to Map for JSON response
                Map<String, Object> sessionMap = new HashMap<>();
                sessionMap.put("session_id", activeSession.getSessionId());
                sessionMap.put("pat_id", activeSession.getPatId());
                sessionMap.put("session_date", activeSession.getSessionDate());
                sessionMap.put("start_time", activeSession.getStartTime());
                sessionMap.put("end_time", activeSession.getEndTime());
                sessionMap.put("duration", activeSession.getDuration());
                sessionMap.put("session_notes", activeSession.getSessionNotes());
                sessionMap.put("session_status", activeSession.getSessionStatus());
                sessionMap.put("language_preference", activeSession.getLanguagePreference());


                result.put("session", sessionMap);
                result.put("message", "Active session found");
                System.out.println("Active session found: " + activeSession.getSessionId());
            } else {
                result.put("session", null);
                result.put("message", "No active session found");
                System.out.println("No active session found for patient: " + patId);
            }

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving active session: " + e.getMessage());
            System.out.println("Error in getActiveSession: " + e.getMessage());
        }

        return result;
    }

    @PostMapping(value = "/send-chat-message", produces = "application/json;charset=UTF-8")
    public Map<String, Object> sendChatMessage(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String sessionId = req.get("session_id");
            String senderType = req.get("sender_type");
            String messageContent = req.get("message_content");
            //Ensuring proper UTF-8 encoding
            if (messageContent != null) {
                messageContent = new String(messageContent.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            }
            if (sessionId == null || sessionId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SESSION_ID");
                result.put("message", "Session ID is required");
                return result;
            }

            if (senderType == null || senderType.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SENDER_TYPE");
                result.put("message", "Sender type is required");
                return result;
            }

            if (messageContent == null || messageContent.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_MESSAGE_CONTENT");
                result.put("message", "Message content is required");
                return result;
            }

            // Validate sender type
            if (!senderType.equals("patient") && !senderType.equals("bot") && !senderType.equals("system")) {
                result.put("status", "error");
                result.put("error_code", "INVALID_SENDER_TYPE");
                result.put("message", "Sender type must be 'patient', 'bot', or 'system'");
                return result;
            }

            String messageId = userRepository.sendChatMessage(sessionId, senderType, messageContent);

            if (messageId != null) {
                result.put("status", "success");
                result.put("message_id", messageId);
                result.put("message", "Message sent successfully");

                // If this is a patient message, generate AI response
                if ("patient".equals(senderType)) {
                    // Generate AI response in a separate thread to avoid blocking
                    String finalMessageContent = messageContent;
                    String finalMessageId = messageId;
                    new Thread(() -> generateAIResponse(sessionId, finalMessageContent, finalMessageId)).start();
                }
            } else {
                result.put("status", "error");
                result.put("error_code", "MESSAGE_SEND_FAILED");
                result.put("message", "Failed to send message");
            }

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error sending message: " + e.getMessage());
        }

        return result;
    }

    // ADD this new method to handle AI response generation
    private void generateAIResponse(String sessionId, String userMessage, String currentMessageId) {
        try {
            // Small delay to make it feel more natural
            Thread.sleep(1000);
            //Ensuring proper UTF-* encoding
            String encodedUserMessage = new String(userMessage.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            // Get the most recent messages for context (chronological order)
            List<ChatMessage> recentMessages = userRepository.getRecentChatMessages(sessionId, 15);
            // Drop the message we're currently responding to. It was persisted before this
            // thread started, so it's the trailing row in history; buildPrompt appends the
            // current userMessage itself, so leaving it here would feed the model a duplicate.
            if (currentMessageId != null) {
                recentMessages.removeIf(m -> currentMessageId.equals(m.getMessageId()));
            }

            ChatSession session = userRepository.getChatSessionById(sessionId);
            String sessionLanguage = (session != null && session.getLanguagePreference() != null)
                    ? session.getLanguagePreference()
                    : "en";

            // Determine session type and delta summary based on chat_type and session history
            String patId = session != null ? session.getPatId() : null;
            String chatType = (patId != null) ? userRepository.getChatType(patId) : "original";
            String sessionType = "initial";
            String deltaSummary = null;

            // Patient name is only used to name the Ollama request-payload log file
            String patientName = null;
            if (patId != null) {
                try {
                    Object name = userRepository.getSubjectInfo(patId).get("subjectname");
                    patientName = (name != null) ? name.toString() : null;
                } catch (Exception e) {
                    System.err.println("Could not resolve patient name for logging (patId=" + patId + "): " + e.getMessage());
                }
            }

            if ("srijit".equals(chatType) && patId != null) {
                int completedSessions = userRepository.getCompletedSessionCount(patId);
                if (completedSessions >= 1) {
                    sessionType = "follow_up";
                    deltaSummary = userRepository.getLatestDeltaSummary(patId);
                }
            }

            System.out.println("DEBUG generateAIResponse: sessionId=" + sessionId
                    + " lang=" + sessionLanguage + " chatType=" + chatType
                    + " sessionType=" + sessionType + " hasDelta=" + (deltaSummary != null));

            // Generate AI response using Ollama
            String aiResponse = ollamaService.generateResponse(userMessage, recentMessages, sessionLanguage, sessionType, deltaSummary, patientName, sessionId);
            // Ensure AI response is properly encoded
            if (aiResponse != null) {
                aiResponse = new String(aiResponse.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            }

            // Send the AI response
            userRepository.sendChatMessage(sessionId, "bot", aiResponse);

            System.out.println("AI response generated for session: " + sessionId);

        } catch (Exception e) {
            System.err.println("Error generating AI response: " + e.getMessage());

            // Send a fallback message if AI fails
            try {
                String fallbackMessage = "I'm sorry, I'm having trouble processing your message right now. Please try again.";
                userRepository.sendChatMessage(sessionId, "bot", fallbackMessage);
            } catch (Exception fallbackError) {
                System.err.println("Failed to send fallback message: " + fallbackError.getMessage());
            }
        }
    }

    // ADD this new health check endpoint
    @PostMapping("/ollama-health")
    public Map<String, Object> checkOllamaHealth() {
        Map<String, Object> result = new HashMap<>();

        try {
            boolean isAvailable = ollamaService.isOllamaAvailable();
            String models = ollamaService.getAvailableModels();

            result.put("status", "success");
            result.put("ollama_available", isAvailable);
            result.put("available_models", models);
            result.put("ollama_url", ollamaService.getOllamaBaseUrl());
            result.put("current_model", ollamaService.getDefaultModel());
            result.put("message", isAvailable ? "Ollama service is running" : "Ollama service is not available");

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error checking Ollama health: " + e.getMessage());
        }

        return result;
    }


    @PostMapping("/get-chat-messages")
    public Map<String, Object> getChatMessages(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String sessionId = req.get("session_id");
            Integer limit = req.get("limit") != null ? Integer.parseInt(req.get("limit")) : null;
            Integer offset = req.get("offset") != null ? Integer.parseInt(req.get("offset")) : null;

            if (sessionId == null || sessionId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SESSION_ID");
                result.put("message", "Session ID is required");
                return result;
            }

            System.out.println("Getting chat messages for session: " + sessionId + ", limit: " + limit + ", offset: " + offset);

            List<ChatMessage> messages = userRepository.getChatMessages(sessionId, limit, offset);

            // Convert ChatMessage objects to Maps for JSON response
            List<Map<String, Object>> messageMaps = new ArrayList<>();
            for (ChatMessage message : messages) {
                Map<String, Object> messageMap = new HashMap<>();
                messageMap.put("message_id", message.getMessageId());
                messageMap.put("session_id", message.getSessionId());
                messageMap.put("message_sequence", message.getMessageSequence());
                messageMap.put("sender_type", message.getSenderType());
                messageMap.put("message_content", message.getMessageContent());
                messageMap.put("timestamp", message.getTimestamp().toString());
                messageMap.put("is_read", message.getIsRead());
                messageMaps.add(messageMap);
            }

            result.put("status", "success");
            result.put("messages", messageMaps);
            result.put("count", messageMaps.size());
            result.put("message", "Messages retrieved successfully");

            System.out.println("Retrieved " + messageMaps.size() + " messages");

        } catch (Exception e) {
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error retrieving messages: " + e.getMessage());
            System.out.println("Error in getChatMessages: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/mark-messages-read")
    public Map<String, Object> markMessagesRead(@RequestBody Map<String, Object> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String sessionId = (String) req.get("session_id");
            @SuppressWarnings("unchecked")
            List<String> messageIds = (List<String>) req.get("message_ids");

            if (sessionId == null || sessionId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SESSION_ID");
                result.put("message", "Session ID is required");
                return result;
            }

            if (messageIds == null || messageIds.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_MESSAGE_IDS");
                result.put("message", "Message IDs are required");
                return result;
            }

            boolean success = userRepository.markMessagesAsRead(sessionId, messageIds);

            if (success) {
                result.put("status", "success");
                result.put("message", "Messages marked as read successfully");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to mark messages as read");
            }

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error marking messages as read: " + e.getMessage());
        }

        return result;
    }

    @PostMapping("/get-unread-count")
    public Map<String, Object> getUnreadCount(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String patId = req.get("pat_id");

            if (patId == null || patId.isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_PATIENT_ID");
                result.put("message", "Patient ID is required");
                return result;
            }

            Integer unreadCount = userRepository.getUnreadMessageCount(patId);

            result.put("status", "success");
            result.put("unread_count", unreadCount);
            result.put("message", "Unread count retrieved successfully");

        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", "Error retrieving unread count: " + e.getMessage());
        }

        return result;
    }
    // Add this temporary debug endpoint to your UserController.java

    @PostMapping("/debug-chat-validation")
    public Map<String, Object> debugChatValidation(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();
        String patId = req.get("pat_id");

        try {
            result.put("pat_id", patId);

            // Check if patient exists
            String patientSql = "SELECT COUNT(*) FROM med WHERE pat_id = ?";
            JdbcOperations jdbcTemplate = null;
            Integer patientCount = jdbcTemplate.queryForObject(patientSql, Integer.class, patId);
            result.put("patient_exists", patientCount > 0);
            result.put("patient_count", patientCount);

            // Check if chat_sessions table exists
            try {
                String sessionSql = "SELECT COUNT(*) FROM chat_sessions WHERE pat_id = ?";
                Integer sessionCount = jdbcTemplate.queryForObject(sessionSql, Integer.class, patId);
                result.put("chat_sessions_table_exists", true);
                result.put("session_count", sessionCount);
            } catch (Exception e) {
                result.put("chat_sessions_table_exists", false);
                result.put("chat_sessions_error", e.getMessage());
            }

            // Check if chat_control table exists
            try {
                String controlSql = "SELECT COUNT(*) FROM chat_control WHERE pat_id = ?";
                Integer controlCount = jdbcTemplate.queryForObject(controlSql, Integer.class, patId);
                result.put("chat_control_table_exists", true);
                result.put("control_count", controlCount);
            } catch (Exception e) {
                result.put("chat_control_table_exists", false);
                result.put("chat_control_error", e.getMessage());
            }

            // Get sample patient IDs
            try {
                String sampleSql = "SELECT pat_id FROM med LIMIT 5";
                List<String> samplePatients = jdbcTemplate.queryForList(sampleSql, String.class);
                result.put("sample_patients", samplePatients);
            } catch (Exception e) {
                result.put("sample_patients_error", e.getMessage());
            }

            result.put("status", "success");

        } catch (Exception e) {
            result.put("status", "error");
            result.put("error", e.getMessage());
            e.printStackTrace();
        }

        return result;
    }
//############################################################################################################################################################
// Add these imports to UserController.java

    // Add this method to UserController.java class
    @PostMapping("/execute-terminal-command")
    public Map<String, Object> executeTerminalCommand(@RequestBody Map<String, String> req) {
        Map<String, Object> result = new HashMap<>();

        try {
            String command = req.get("command");
            String sessionId = req.get("session_id");

            if (command == null || command.trim().isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_COMMAND");
                result.put("message", "Command is required");
                return result;
            }

            if (sessionId == null || sessionId.trim().isEmpty()) {
                result.put("status", "error");
                result.put("error_code", "MISSING_SESSION_ID");
                result.put("message", "Session ID is required");
                return result;
            }

            // Security check - validate session exists and is active
            ChatSession activeSession = userRepository.getChatSessionById(sessionId);
            if (activeSession == null || !"active".equals(activeSession.getSessionStatus())) {
                result.put("status", "error");
                result.put("error_code", "INVALID_SESSION");
                result.put("message", "Invalid or inactive session");
                return result;
            }

            // Sanitize and validate command
            String sanitizedCommand = sanitizeCommand(command);
            if (sanitizedCommand == null) {
                result.put("status", "error");
                result.put("error_code", "FORBIDDEN_COMMAND");
                result.put("message", "Command not allowed for security reasons");
                return result;
            }

            // Execute command
            String output = executeCommand(sanitizedCommand);

            // Log the terminal interaction
            userRepository.logTerminalCommand(sessionId, command, output);

            result.put("status", "success");
            result.put("output", output);
            result.put("command", sanitizedCommand);
            result.put("message", "Command executed successfully");

        } catch (Exception e) {
            System.out.println("Error executing terminal command: " + e.getMessage());
            e.printStackTrace();
            result.put("status", "error");
            result.put("message", "Error executing command: " + e.getMessage());
        }

        return result;
    }

    private String sanitizeCommand(String command) {
        // Basic security checks - still block extremely dangerous operations
        String[] forbiddenCommands = {
                "rm -rf", "rm -r", "mkfs", "dd", "format", "fdisk",
                "shutdown", "reboot", "halt", "poweroff", "init",
                "passwd", "userdel", "useradd", "usermod", "groupdel", "groupadd",
                "chmod 777", "chown", "mount", "umount", "fstab"
        };

        String lowerCommand = command.toLowerCase();

        // Check for forbidden command patterns
        for (String forbidden : forbiddenCommands) {
            if (lowerCommand.contains(forbidden)) {
                return null; // Block extremely dangerous commands
            }
        }

        // Block commands with dangerous redirects and pipes that could cause damage
        if (lowerCommand.contains("rm") && (lowerCommand.contains(">") || lowerCommand.contains("|"))) {
            return null;
        }

        // Block sudo attempts
        if (lowerCommand.startsWith("sudo") || lowerCommand.contains("su -")) {
            return null;
        }

        // Block command chaining that could bypass security
        if (command.contains("&&") || command.contains("||") || command.contains(";")) {
            return null;
        }

        return command; // Allow most other commands
    }

    private String executeCommand(String command) throws Exception {
        ProcessBuilder processBuilder = new ProcessBuilder();

        // Set command based on OS
        if (System.getProperty("os.name").toLowerCase().contains("windows")) {
            processBuilder.command("cmd.exe", "/c", command);
        } else {
            processBuilder.command("bash", "-c", command);
        }

        processBuilder.redirectErrorStream(true);

        Process process = processBuilder.start();

        // Set timeout to prevent hanging
        boolean finished = process.waitFor(10, TimeUnit.SECONDS);

        if (!finished) {
            process.destroyForcibly();
            throw new RuntimeException("Command execution timeout");
        }

        // Read output
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }

        String result = output.toString().trim();

        // Limit output size
        if (result.length() > 2000) {
            result = result.substring(0, 2000) + "\n... (output truncated)";
        }

        return result.isEmpty() ? "Command executed successfully (no output)" : result;
    }
    @PostMapping("/get-subject-info")
    public Map<String, Object> getSubjectInfo(@RequestBody Map<String,String> req){
        String subject_id=req.get("subjectid");
        System.out.println("subject_id : "+subject_id);
        Map<String,Object> result = new HashMap<>();
        try {
            Map<String,Object> output = userRepository.getSubjectInfo(subject_id);
            result.put("status", "success");
            result.put("subject-info", output);
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not get subject");
        }

        return result;
    }


    @PostMapping("/create-new-survey")
    public Map<String, Object> createNewSurvey(@RequestBody Map<String,String> req){
        Map<String,String> data = new HashMap<String,String>();

        //Map<String, String> data= req.get("data");
        //System.out.println("subject_id : "+subject_id);
        Map<String,Object> result = new HashMap<>();
        try {

            data.put("name", req.get("name"));
            data.put("description", req.get("description"));
            data.put("template_source", req.get("template_source"));
            data.put("details_source", req.get("details_source"));
            boolean output = userRepository.createNewSurvey(data);
            result.put("status", "success");
            result.put("subject-info", output);
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create new survey");
        }

        return result;
    }


    @PostMapping("/get-allocated-zone")
    public Map<String, Object> getAllocateZone(@RequestBody Map<String,String> req){
        System.out.println("userid : "+req.get("userid"));
        Map<String,Object> result = new HashMap<>();


        try {
                List<String> output = userRepository.getAllocateZone(req.get("userid"));
                result.put("zone-id", output);
                result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find Zone id");
        }

        return result;
    }


    @PostMapping("/get-zone-info")
    public Map<String, Object> getZoneInfo(@RequestBody Map<String,String> req){
        System.out.println("zone_id : "+req.get("zone_id"));
        Map<String,Object> result = new HashMap<>();


        try {
            Map<String, Object> output = userRepository.getZoneInfo(req.get("zone_id"));
            result.put("zone-info", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find Zone info");
        }

        return result;
    }

    @PostMapping("/get-allocate-surveyor")
    public Map<String, Object> getAllocateSurveyor(@RequestBody Map<String,String> req){
        System.out.println("userid : "+req.get("userid"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<String> output = userRepository.getAllocateSurveyor(req.get("userid"));
            result.put("survey-ids", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any allocated survey info");
        }

        return result;
    }

    @PostMapping("/get-survey-info")
    public Map<String, Object> getSurveyInfo(@RequestBody Map<String,String> req){
        System.out.println("sid : "+req.get("sid"));
        Map<String,Object> result = new HashMap<>();


        try {
            Map<String, Object> output = userRepository.getSurveyInfo(req.get("sid"));
            result.put("survey-info", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find Survey info");
        }

        return result;
    }

    @PostMapping("/get-FieldProject-info")
    public Map<String, Object> getFieldProjectInfo(@RequestBody Map<String,String> req)
        {
            System.out.println("sid : "+req.get("sid"));
            Map<String,Object> result = new HashMap<>();

            List<Survey> output = userRepository.getFieldProjectInfo(req.get("sid"));
            try {
                //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));
                result.put("FieldProject-info", output);
                result.put("status", "success");

            }catch (Exception e){
                result.put("status", "error");
                result.put("message", "Could not find any FieldProject info");
            }

            return result;
        }

    @PostMapping("/create-field-entry")
    public Map<String, Object> createFieldEntry(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<String,String>();

        //Map<String, String> data= req.get("data");
        //System.out.println("subject_id : "+subject_id);
        Map<String,Object> result = new HashMap<>();
        try {

            data.put("rid", req.get("rid"));
            data.put("fid", req.get("fid"));
            data.put("value", req.get("value"));
            boolean output = userRepository.createFieldEntry(data);
            if(output==true) {
                result.put("status", "success");
            }
            else{
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create new survey");
        }

        return result;

    }

    @PostMapping("/update-field-entry")
    public Map<String, Object> updateFieldEntry(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<String,String>();

        //Map<String, String> data= req.get("data");
        //System.out.println("subject_id : "+subject_id);
        Map<String,Object> result = new HashMap<>();
        try {

            data.put("rid", req.get("rid"));
            data.put("fid", req.get("fid"));
            data.put("value", req.get("value"));
            boolean output = userRepository.updateFieldEntry(data);
            if(output==true) {
                result.put("status", "success");
            }
            else{
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create new survey");
        }

        return result;

    }

    @PostMapping("/create-record-log")
    public Map<String, Object> createRecordLog(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<String,String>();
        System.out.println("subject_id : "+req.get("subject_id"));
        System.out.println("survey_data : "+req.get("survey_data"));
        System.out.println("record_type : "+req.get("record_type"));
        System.out.println("sid : "+req.get("sid"));
        System.out.println("image : "+req.get("image"));
        System.out.println("voice : "+req.get("voice"));
        System.out.println("userid : "+req.get("userid"));
        System.out.println("username : "+req.get("username"));
        Map<String,Object> result = new HashMap<>();


        try {

            data.put("subject_id", req.get("subject_id"));
            data.put("survey_data", req.get("survey_data"));
            data.put("record_type", req.get("record_type"));
            data.put("image", req.get("image"));
            data.put("voice", req.get("voice"));
            data.put("userid", req.get("userid"));
            data.put("username", req.get("username"));

            data.put("sid", req.get("sid"));
            String output = userRepository.createRecordLog(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output.equalsIgnoreCase("error")) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
                result.put("rid", output);
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create record");
        }

        return result;
    }

    @PostMapping("/update-record-log")
    public Map<String, Object> updateSurveyDataRecordLog(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<String,String>();
        System.out.println("rid : "+req.get("rid"));
        System.out.println("survey_data : "+req.get("survey_data"));
        Map<String,Object> result = new HashMap<>();


        try {

            data.put("rid", req.get("rid"));
            data.put("survey_data", req.get("survey_data"));

            String output = userRepository.updateSurveyDataRecordLog(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output.equalsIgnoreCase("error")) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
                result.put("rid", output);
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create record");
        }

        return result;
    }


    @PostMapping("/get-RecordLog-BySid")
    public Map<String, Object> getRecordLogBySid(@RequestBody Map<String,String> req)
    {
        System.out.println("sid : "+req.get("sid"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<Record> output = userRepository.getRecordLogBySid(req.get("sid"));
            result.put("record-log", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any FieldProject info");
        }

        return result;
    }


    @PostMapping("/get-RecordLog-BySubjectId")
    public Map<String, Object> getRecordLogBySubjectId(@RequestBody Map<String,String> req)
    {
        System.out.println("subject_id : "+req.get("subject_id"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<Record> output = userRepository.getRecordLogBySubjectId(req.get("subject_id"));
            result.put("record-log", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any RecordLog info");
        }

        return result;
    }

    @PostMapping("/get-RecordLog-BySubjectId-InstanceTime")
    public Map<String, Object> getRecordLogBySubjectIdInstanceTime(@RequestBody Map<String,String> req)
    {
        System.out.println("subject_id : "+req.get("subject_id"));
        System.out.println("InstanceTime : "+req.get("InstanceTime"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<Record> output = userRepository.getRecordLogBySubjectIdInstanceTime(req.get("subject_id"),req.get("InstanceTime"));
            result.put("record-log", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any RecordLog info");
        }

        return result;
    }

    @PostMapping("/get-FieldEntries-Value")
    public Map<String, Object> getFieldEntriesValue(@RequestBody Map<String,String> req){
        System.out.println("rid : "+req.get("rid"));
        System.out.println("fid : "+req.get("fid"));
        Map<String,Object> result = new HashMap<>();


        try {
            String output = userRepository.getFieldEntriesValue(req.get("rid"),req.get("fid"));
            result.put("value", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any allocated survey info");
        }

        return result;
    }


    //public String InsertSubject(Map<String, String> data)
    @PostMapping("/create-subject-new")
    public Map<String, Object> InsertSubject(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<String,String>();
        System.out.println("subjectname : "+req.get("subjectname"));
        System.out.println("zone_id : "+req.get("zone_id"));
        System.out.println("age : "+req.get("age"));
        Map<String,Object> result = new HashMap<>();


        try {
//String subjectname, String subject_id, String age, String sex, String occupation, String zone_id, String address,String mobile,String email,
// String spousename,String childname,String maritalstatus,String village,String idtype,String idnumber,String caste,String religion,String image,String voice
            data.put("subjectname", req.get("subjectname"));
            data.put("age", req.get("age"));
            data.put("sex", req.get("sex"));
            data.put("zone_id", req.get("zone_id"));
            data.put("occupation", req.get("occupation"));
            data.put("address", req.get("address"));
            data.put("mobile", req.get("mobile"));
            data.put("email", req.get("email"));
            data.put("spousename", req.get("spousename"));
            data.put("childname", req.get("childname"));
            data.put("relatives", req.get("relatives"));
            data.put("maritalstatus", req.get("maritalstatus"));
            data.put("village", req.get("village"));
            data.put("idtype", req.get("idtype"));
            data.put("idnumber", req.get("idnumber"));
            data.put("caste", req.get("caste"));
            data.put("religion", req.get("religion"));
            data.put("image", req.get("image"));
            data.put("voice", req.get("voice"));
            data.put("subject_id", req.get("subject_id"));
            data.put("survey_data", req.get("survey_data"));
            //data.put("sid", req.get("sid"));
            String output = userRepository.InsertSubject(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output.equalsIgnoreCase("error")) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
                result.put("subject_id", output);
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create subject");
        }

        return result;
    }


    @PostMapping("/get-SubjectInfo-ByZone")
    public Map<String, Object> getSubjectInfoByZone(@RequestBody Map<String,String> req)
    {
        System.out.println("zone_id : "+req.get("zone_id"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<Subject> output = userRepository.getSubjectInfoByZone(req.get("zone_id"));
            result.put("subject-log", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find any FieldProject info");
        }

        return result;
    }


    @PostMapping("/create-service-new")
    public Map<String, Object> createService(@RequestBody Map<String,String> req)
    {

        Map<String,String> data = new HashMap<String,String>();
        System.out.println("sname : "+req.get("sname"));
        System.out.println("description : "+req.get("description"));
        System.out.println("start_date : "+req.get("start_date"));
        System.out.println("end_date : "+req.get("end_date"));
        Map<String,Object> result = new HashMap<>();


        try {

            data.put("sname", req.get("sname"));
            data.put("description", req.get("description"));
            data.put("start_date", req.get("start_date"));
            data.put("end_date", req.get("end_date"));

            String output = userRepository.createService(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output.equalsIgnoreCase("error")) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
                result.put("service_id", output);
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create service");
        }

        return result;
    }

    @PostMapping("/create-serviceEnrollment-new")
    public Map<String, Object> newServiceEnrollment(@RequestBody Map<String,String> req)
    {


        Map<String,String> data = new HashMap<String,String>();
        System.out.println("service_id : "+req.get("service_id"));
        System.out.println("subject_id : "+req.get("subject_id"));
        System.out.println("sid : "+req.get("sid"));
        System.out.println("start_date : "+req.get("start_date"));
        System.out.println("end_date : "+req.get("end_date"));
        Map<String,Object> result = new HashMap<>();


        try {

            data.put("service_id", req.get("service_id"));
            data.put("subject_id", req.get("subject_id"));
            data.put("sid", req.get("sid"));
            data.put("start_date", req.get("start_date"));
            data.put("end_date", req.get("end_date"));

            boolean output = userRepository.newServiceEnrollment(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output==false) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not enroll subject to service");
        }

        return result;
    }

    @PostMapping("/get-AllServiceEnrollment-byServiceId_andSid")
    public Map<String, Object> getAllServiceEnrollment_byServiceId_andSid(@RequestBody Map<String,String> req)
    {
        System.out.println("service_id : "+req.get("service_id"));
        System.out.println("sid : "+req.get("sid"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<String> output = userRepository.getAllServiceEnrollment_byServiceId_andSid(req.get("service_id"),req.get("sid"));
            result.put("subject-ids", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find by this Service Id and sid");
        }

        return result;
    }

    @PostMapping("/get-all-services")
    public Map<String, Object> getAllServices(@RequestBody Map<String,String> req)
    {

        Map<String,Object> result = new HashMap<>();

        try {
            List<Service> output = userRepository.getAllServices();
            result.put("service-log", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not fetch all Services");
        }

        return result;
    }

    @PostMapping("/get-AllServiceEnrollment-byServiceId")
    public Map<String, Object> getAllServiceEnrollment_byServiceId(@RequestBody Map<String,String> req)
    {
        System.out.println("service_id : "+req.get("service_id"));
        Map<String,Object> result = new HashMap<>();


        try {
            List<ServiceEnrollment> output = userRepository.getAllServiceEnrollment_byServiceId(req.get("service_id"));
            result.put("service-enrollment-logs", output);
            result.put("status", "success");

        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not find by this Service Id");
        }

        return result;
    }

    @PostMapping("/create-SurveyFields-new")
    public Map<String, Object> createNewSurveyFields(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<>();
        System.out.println("attrname : "+req.get("attrname"));
        System.out.println("attrtype : "+req.get("attrtype"));
        System.out.println("source_type : "+req.get("source_type"));
        System.out.println("sid : "+req.get("sid"));
        System.out.println("attrunit : "+req.get("attrunit"));
        System.out.println("attrreq : "+req.get("attrreq"));

        Map<String,Object> result = new HashMap<>();

        try {

            data.put("attrname", req.get("attrname"));
            data.put("attrtype", req.get("attrtype"));
            data.put("source_type", req.get("source_type"));
            data.put("sid", req.get("sid"));
            data.put("attrunit", req.get("attrunit"));
            data.put("attrreq", req.get("attrreq"));

            boolean output = userRepository.createNewSurveyFields(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output==false) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not insert survey field");
        }

        return result;
    }

    @PostMapping("/create-Allocate-Surveyor")
    public Map<String, Object> createAllocateSurveyor(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<>();

        System.out.println("userid : "+req.get("userid"));
        System.out.println("sid : "+req.get("sid"));

        Map<String,Object> result = new HashMap<>();

        try {

            data.put("userid", req.get("userid"));
            data.put("sid", req.get("sid"));

            boolean output = userRepository.createAllocateSurveyor(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output==false) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not allocate surveyor");
        }

        return result;
    }

    @PostMapping("/create-Allocate-Zone")
    public Map<String, Object> createAllocateZone(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<>();

        System.out.println("userid : "+req.get("userid"));
        System.out.println("zone_id : "+req.get("zone_id"));

        Map<String,Object> result = new HashMap<>();

        try {

            data.put("userid", req.get("userid"));
            data.put("zone_id", req.get("zone_id"));

            boolean output = userRepository.createAllocateZone(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output==false) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not allocate zone");
        }

        return result;
    }

    @PostMapping("/create-new-M-Dosthi-login")
    public Map<String, Object> createNewEdosthiLogin(@RequestBody Map<String,String> req)
    {
        Map<String,String> data = new HashMap<>();

        System.out.println("uid : "+req.get("uid"));

        Map<String,Object> result = new HashMap<>();


        //uid   | pwd                  | name                 | crtdate             | type | phone      | address | emailid | qualification | designation | dis
        //| rg_no       | center | active | sign       | doc_regno | available | referral | verified | verifemail | verifphone | consent

        try {

            data.put("uid", req.get("uid"));
            data.put("pwd", req.get("pwd"));
            data.put("name", req.get("name"));
            data.put("crtdate", req.get("crtdate"));
            data.put("center", req.get("center"));
            //data.put("userid", req.get("userid"));
            data.put("type", req.get("type"));
            data.put("active", req.get("active"));
            data.put("available", req.get("available"));
            data.put("referral", req.get("referral"));
            data.put("verified", req.get("verified"));
            data.put("verifemail", req.get("verifemail"));
            data.put("verifphone", req.get("verifphone"));
            data.put("consent", req.get("consent"));
            data.put("phone", req.get("phone"));

            boolean output = userRepository.createNewEdosthiLogin(data);
            //List<String> output = userRepository.getFieldProjectInfo(req.get("sid"));

            if(output==false) {
                result.put("status", "error");
                result.put("message", "Dependency Issue");
            }
            else{
                result.put("status", "success");
            }
        }catch (Exception e){
            result.put("status", "error");
            result.put("message", "Could not create login");
        }

        return result;
    }
    //App progress api endpoints
    @PostMapping("/save-progress")
    public Map<String, Object> saveProgress(@RequestBody Map<String, Object> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String userid = (String) req.get("userid");
            String itemId = (String) req.get("item_id");
            String itemType = (String) req.get("item_type");

            boolean success = userRepository.incrementOpenCount(userid, itemId, itemType);
            if (success) {
                result.put("status", "success");
                result.put("message", "Progress saved successfully");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to save progress");
            }
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/get-progress")
    public Map<String, Object> getProgress(@RequestBody Map<String, Object> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String userid = (String) req.get("userid");
            String itemId = (String) req.get("item_id");

            Map<String, Object> progress = userRepository.getProgress(userid, itemId);
            result.put("status", "success");
            result.put("data", progress);
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/get-all-progress")
    public Map<String, Object> getAllProgress(@RequestBody Map<String, Object> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String userid = (String) req.get("userid");

            List<Map<String, Object>> progressList = userRepository.getAllProgress(userid);
            result.put("status", "success");
            result.put("data", progressList);
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", e.getMessage());
        }
        return result;
    }
    @PostMapping("/log-time")
    public Map<String, Object> logTime(@RequestBody Map<String, Object> req) {
        Map<String, Object> result = new HashMap<>();
        try {
            String userid = (String) req.get("userid");
            // handle both integer and string for timespent
            int timespent = 0;
            if (req.get("timespent") instanceof Integer) {
                timespent = (Integer) req.get("timespent");
            } else if (req.get("timespent") instanceof String) {
                timespent = Integer.parseInt((String) req.get("timespent"));
            }

            // Get current date string in YYYY-MM-DD
            String date = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());

            boolean success = userRepository.logUserTime(userid, timespent, date);
            if (success) {
                result.put("status", "success");
            } else {
                result.put("status", "error");
                result.put("message", "Failed to log time");
            }
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/get-patient-monitoring")
    public Map<String, Object> getPatientMonitoring(@RequestBody Map<String, String> request) {
        Map<String, Object> result = new HashMap<>();
        String role = jwtFilter.getType();
        String actor = jwtFilter.getUsername();
        String patientId = request.get("patientId");

        if (role == null || (!"doc".equalsIgnoreCase(role) && !"psy".equalsIgnoreCase(role))) {
            result.put("status", "error");
            result.put("message", "Only doctors and psychologists can access patient monitoring");
            return result;
        }
        if (patientId == null || patientId.trim().isEmpty()) {
            result.put("status", "error");
            result.put("message", "Patient ID is required");
            return result;
        }

        try {
            Integer patientExists = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM med WHERE pat_id=?", Integer.class, patientId);
            if (patientExists == null || patientExists == 0) {
                result.put("status", "error");
                result.put("message", "Patient not found");
                return result;
            }
            if ("doc".equalsIgnoreCase(role)) {
                Integer assigned = jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM lpatq lp JOIN login d ON UPPER(d.rg_no)=UPPER(lp.assigneddoc) " +
                                "WHERE lp.pat_id=? AND UPPER(d.uid)=UPPER(?) AND UPPER(lp.delflag)='N'",
                        Integer.class, patientId, actor);
                if (assigned == null || assigned == 0) {
                    result.put("status", "error");
                    result.put("message", "Doctor is not assigned to this patient");
                    return result;
                }
            }

            List<Map<String, Object>> records = jdbcTemplate.queryForList(
                    "SELECT id, distress_score, screening_date, recorded_at FROM distress_thermometer " +
                        "WHERE pat_id=? ORDER BY id DESC LIMIT 1", patientId);
            result.put("status", "success");
            result.put("patientId", patientId);
            result.put("therapyHistory", Collections.emptyList());
            result.put("metastasisHistory", Collections.emptyList());
            if (records.isEmpty()) {
                result.put("distressStatus", "Not assessed");
                result.put("distressBit", false);
                result.put("distressMessage", "No distress assessment is available for this patient.");
                result.put("problemList", Collections.emptyList());
            } else {
                Map<String, Object> latest = records.get(0);
                int score = ((Number) latest.get("distress_score")).intValue();
                boolean high = score > 4;
                result.put("distressStatus", high ? "High" : "Low");
                result.put("distressBit", high);
                result.put("distressScore", score);
                result.put("distressDate", latest.get("screening_date"));
                result.put("distressMessage", "Latest Distress Thermometer score: " + score + "/10 (screening date " + latest.get("screening_date") + ").");
                List<Map<String, Object>> selectedProblems = jdbcTemplate.queryForList(
                        "SELECT category, concern FROM distress_thermometer_problem WHERE screening_id=? ORDER BY id",
                        latest.get("id"));
                Map<String, List<String>> groupedProblems = new LinkedHashMap<>();
                for (Map<String, Object> problem : selectedProblems) {
                    String category = String.valueOf(problem.get("category"));
                    groupedProblems.computeIfAbsent(category, key -> new ArrayList<>())
                            .add(String.valueOf(problem.get("concern")));
                }
                List<Map<String, Object>> problemList = new ArrayList<>();
                for (Map.Entry<String, List<String>> group : groupedProblems.entrySet()) {
                    Map<String, Object> category = new HashMap<>();
                    category.put("category", group.getKey());
                    category.put("concerns", group.getValue());
                    problemList.add(category);
                }
                result.put("problemList", problemList);
            }
        } catch (Exception exception) {
            exception.printStackTrace();
            result.put("status", "error");
            result.put("message", "Unable to load patient monitoring data");
            result.put("distressStatus", "Not available");
            result.put("distressBit", false);
            result.put("distressMessage", "Patient monitoring data could not be loaded.");
            result.put("therapyHistory", Collections.emptyList());
            result.put("metastasisHistory", Collections.emptyList());
        }
        return result;
    }



    @GetMapping("/")
    public String index() {
        return "Welcome to iMediX-API";
    }



}

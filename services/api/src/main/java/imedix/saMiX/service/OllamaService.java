//package imedix.saMiX.service;
//
//import com.fasterxml.jackson.databind.JsonNode;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import imedix.saMiX.model.ChatMessage;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.http.*;
//import org.springframework.stereotype.Service;
//import org.springframework.web.client.ResourceAccessException;
//import org.springframework.web.client.RestTemplate;
//
//import java.nio.charset.StandardCharsets;
//import java.util.ArrayList;
//import java.util.HashMap;
//import java.util.List;
//import java.util.Map;
//
//@Service
//public class OllamaService {
//
//    @Value("${ollama.base.url:http://localhost:11434}")
//    private String ollamaBaseUrl;
//
//    @Value("${ollama.model:iamhardikat11/llama-3.2-M-Dosthi-v1.0:latest}")
//    private String defaultModel;
//
//    @Value("${ollama.timeout:45000}")
//    private int timeout;
//
//    @Value("${ollama.max.tokens:200}")
//    private int maxTokens;
//
//    @Value("${ollama.temperature:0.7}")
//    private double temperature;
//
//    @Value("${ollama.top_p:0.9}")
//    private double topP;
//
//    @Value("${ollama.top_k:50}")
//    private int topK;
//
//    @Value("${ollama.repeat_penalty:1.2}")
//    private double repeatPenalty;
//
//    @Value("${ollama.num_ctx:4096}")
//    private int contextWindow;
//
//    @Value("${chat.system.prompt:}")
//    private String systemPrompt;
//
//    @Value("${chat.max.context.messages:15}")
//    private int maxContextMessages;
//
//    private final RestTemplate restTemplate;
//    private final ObjectMapper objectMapper;
//
//    public OllamaService() {
//        this.restTemplate = new RestTemplate();
//        this.objectMapper = new ObjectMapper();
//    }
//
//    /**
//     * Generate AI response using Ollama /api/chat endpoint
//     */
//    public String generateResponse(String userMessage, List<ChatMessage> recentMessages) {
//        try {
//            //ensuring prper UTF-8 encoding
//            String encodedUserMessage = new String(userMessage.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//            // Build messages array for chat API
//            List<Map<String, String>> messages = buildChatMessages(userMessage, recentMessages);
//
//            // Prepare request for Ollama chat API
//            Map<String, Object> requestBody = new HashMap<>();
//            requestBody.put("model", defaultModel);
//            requestBody.put("messages", messages);
//            requestBody.put("stream", false);
//
//            // Optional parameters matching your Modelfile
//            Map<String, Object> options = new HashMap<>();
//            options.put("temperature", temperature);
//            options.put("top_p", topP);
//            options.put("top_k", topK);
//            options.put("repeat_penalty", repeatPenalty);
//            options.put("num_ctx", contextWindow);
//            options.put("num_predict", maxTokens);
//            requestBody.put("options", options);
//
//            // Set headers
//            HttpHeaders headers = new HttpHeaders();
//            headers.setContentType(MediaType.APPLICATION_JSON);
//            headers.setAcceptCharset(List.of(StandardCharsets.UTF_8));
//            headers.set("Accept", "application/json;charset=UTF-8");
//            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
//
//            // Make request to Ollama chat API
//            String url = ollamaBaseUrl + "/api/chat";
//            ResponseEntity<String> response = restTemplate.exchange(
//                    url, HttpMethod.POST, entity, String.class
//            );
//
//            if (response.getStatusCode() == HttpStatus.OK) {
//                String responseBody = response.getBody();
//                if (responseBody!= null){
//                    //ensuring UTF-8 coding
//                    responseBody = new String(responseBody.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//                }
//                return parseOllamaChatResponse(response.getBody());
//            } else {
//                return getFallbackResponse("Server error occurred");
//            }
//
//        } catch (ResourceAccessException e) {
//            System.err.println("Ollama service unavailable: " + e.getMessage());
//            return getFallbackResponse("AI service temporarily unavailable");
//        } catch (Exception e) {
//            System.err.println("Error generating AI response: " + e.getMessage());
//            e.printStackTrace();
//            return getFallbackResponse("Sorry, I couldn't process your message right now");
//        }
//    }
//
//    /**
//     * Build messages array for Ollama chat API
//     * Note: Your model uses a custom template, so we need to be careful with system prompts
//     */
//    private List<Map<String, String>> buildChatMessages(String userMessage, List<ChatMessage> recentMessages) {
//        List<Map<String, String>> messages = new ArrayList<>();
//
//        // Add system message - this will be handled by your model's template
//        if (systemPrompt != null && !systemPrompt.trim().isEmpty()) {
//            Map<String, String> systemMessage = new HashMap<>();
//            systemMessage.put("role", "system");
//            //systemMessage.put("content", systemPrompt);
//            systemMessage.put("content", new String(systemPrompt.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8));
//            messages.add(systemMessage);
//        }
//
//        // Add recent conversation context
//        if (recentMessages != null && !recentMessages.isEmpty()) {
//            // Get recent messages in chronological order (oldest first)
//            int startIndex = Math.max(0, recentMessages.size() - maxContextMessages);
//
//            for (int i = startIndex; i < recentMessages.size(); i++) {
//                ChatMessage msg = recentMessages.get(i);
//
//                // Skip system messages as they're already added above
//                if ("system".equals(msg.getSenderType())) {
//                    continue;
//                }
//
//                Map<String, String> chatMsg = new HashMap<>();
//
//                if ("patient".equals(msg.getSenderType())) {
//                    chatMsg.put("role", "user");
//                    String content = msg.getMessageContent();
//                    if (content != null) {
//                        content = new String(content.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//                    }
//                    chatMsg.put("content", msg.getMessageContent());
//                } else if ("bot".equals(msg.getSenderType())) {
//                    chatMsg.put("role", "assistant");
//                    String content = msg.getMessageContent();
//                    if (content != null) {
//                        content = new String(content.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//                    }
//                    chatMsg.put("content", msg.getMessageContent());
//                } else {
//                    continue; // Skip unknown sender types
//                }
//
//                messages.add(chatMsg);
//            }
//        }
//
//        // Add current user message
//        Map<String, String> currentMessage = new HashMap<>();
//        currentMessage.put("role", "user");
//        currentMessage.put("content", userMessage);
//        messages.add(currentMessage);
//
//        return messages;
//    }
//
//    /**
//     * Parse Ollama's chat API JSON response
//     */
//    private String parseOllamaChatResponse(String responseBody) {
//        try {
//            JsonNode jsonNode = objectMapper.readTree(responseBody);
//
//            // For chat API, the response is in message.content
//            JsonNode messageNode = jsonNode.get("message");
//            if (messageNode != null) {
//                String response = messageNode.get("content").asText();
//                //ensuring proper utf-8
//                response = new String(response.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//                // Clean up the response
//                response = response.trim();
//
//                // Ensure it's not too long
//                if (response.length() > 500) {
//                    response = response.substring(0, 497) + "...";
//                }
//
//                return response.isEmpty() ? getFallbackResponse("No response generated") : response;
//            } else {
//                // Fallback to old format if needed
//                String response = jsonNode.get("response").asText();
//                response = new String(response.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
//                return response.trim();
//            }
//
//        } catch (Exception e) {
//            System.err.println("Error parsing Ollama chat response: " + e.getMessage());
//            return getFallbackResponse("Error processing AI response");
//        }
//    }
//
//    /**
//     * Get fallback response when AI is unavailable
//     */
//    private String getFallbackResponse(String reason) {
//        System.out.println("Using fallback response. Reason: " + reason);
//
//        // Return a helpful fallback message
//        return "I'm having trouble connecting to my AI assistant right now. " +
//                "Please try again in a moment, or contact support if the issue persists.";
//    }
//
//    /**
//     * Health check for Ollama service
//     */
//    public boolean isOllamaAvailable() {
//        try {
//            String url = ollamaBaseUrl + "/api/tags";
//            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
//            return response.getStatusCode() == HttpStatus.OK;
//        } catch (Exception e) {
//            return false;
//        }
//    }
//
//    /**
//     * Get available models from Ollama
//     */
//    public String getAvailableModels() {
//        try {
//            String url = ollamaBaseUrl + "/api/tags";
//            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
//            if (response.getStatusCode() == HttpStatus.OK) {
//                return response.getBody();
//            }
//        } catch (Exception e) {
//            System.err.println("Error getting available models: " + e.getMessage());
//        }
//        return "{}";
//    }
//
//    // Getter methods for configuration testing
//    public String getOllamaBaseUrl() {
//        return ollamaBaseUrl;
//    }
//
//    public String getDefaultModel() {
//        return defaultModel;
//    }
//}
package imedix.saMiX.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import imedix.saMiX.model.ChatMessage;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class OllamaService {

    @Value("${ollama.base.url}")
    private String ollamaBaseUrl;

    // Per-language model names
    @Value("${ollama.model.en}")
    private String modelEn;

    @Value("${ollama.model.bn}")
    private String modelBn;

    @Value("${ollama.timeout}")
    private int timeout;

    // English model parameters (Llama)
    @Value("${ollama.max.tokens.en}")
    private int maxTokensEn;

    @Value("${ollama.temperature.en}")
    private double temperatureEn;

    @Value("${ollama.top_p.en}")
    private double topPEn;

    @Value("${ollama.top_k.en}")
    private int topKEn;

    @Value("${ollama.repeat_penalty.en}")
    private double repeatPenaltyEn;

    @Value("${ollama.num_ctx.en}")
    private int contextWindowEn;

    @Value("${ollama.num_gpu.en}")
    private int numGpuEn;

    // Bengali model parameters (Gemma3)
    @Value("${ollama.max.tokens.bn}")
    private int maxTokensBn;

    @Value("${ollama.temperature.bn}")
    private double temperatureBn;

    @Value("${ollama.top_p.bn}")
    private double topPBn;

    @Value("${ollama.top_k.bn}")
    private int topKBn;

    @Value("${ollama.repeat_penalty.bn}")
    private double repeatPenaltyBn;

    @Value("${ollama.num_ctx.bn}")
    private int contextWindowBn;

    @Value("${ollama.repeat_last_n.bn}")
    private int repeatLastNBn;

    @Value("${ollama.frequency_penalty.bn}")
    private double frequencyPenaltyBn;

    @Value("${ollama.presence_penalty.bn}")
    private double presencePenaltyBn;

    @Value("${ollama.typical_p.bn}")
    private double typicalPBn;

    @Value("${ollama.num_batch.bn}")
    private int numBatchBn;

    @Value("${ollama.num_gpu.bn}")
    private int numGpuBn;

    // First session templates (used by both "original" and "srijit" session 1)
    @Value("${ollama.template.en_first_session}")
    private String templateEnFirstSession;

    @Value("${ollama.template.bn_first_session}")
    private String templateBnFirstSession;

    // Follow-up session templates (used by "srijit" session 2+, with delta summary injected)
    @Value("${ollama.template.en_follow_up}")
    private String templateEnFollowUp;

    @Value("${ollama.template.bn_follow_up}")
    private String templateBnFollowUp;

    // generate v0.2 — structural templates using Ollama's native {{ .System }} variable
    @Value("${ollama.template.v2.en}")
    private String templateV2En;

    @Value("${ollama.template.v2.bn}")
    private String templateV2Bn;

    // Stop sequences — English (comma-separated)
    @Value("${ollama.stop.en}")
    private String stopSequencesEn;

    @Value("${chat.max.context.messages}")
    private int maxContextMessages;

    // Folder that request-payload log files (one per patient/session) are written to
    @Value("${ollama.log.dir}")
    private String ollamaLogDir;

    // Whether Ollama request payloads get logged to file at all
    @Value("${ollama.log.payload.enabled:true}")
    private boolean payloadLoggingEnabled;

    // "generate" -> /api/generate + template directly; "chat" -> /api/chat + system role message
    @Value("${ollama.api.mode}")
    private String apiMode;

    // Only consulted when apiMode=generate: "v1" (system baked into template) or "v2" ({{ .System }})
    @Value("${ollama.generate.version}")
    private String generateVersion;

    // Stage-specific follow-up prompts
    @Value("${ollama.stage_specific_prompts.enabled:false}")
    private boolean stageSpecificPromptsEnabled;

    @Value("${ollama.stage.prompt.en.precontemplation}")
    private String stagePromptPathEnPrecontemplation;
    @Value("${ollama.stage.prompt.en.contemplation}")
    private String stagePromptPathEnContemplation;
    @Value("${ollama.stage.prompt.en.preparation}")
    private String stagePromptPathEnPreparation;
    @Value("${ollama.stage.prompt.en.action}")
    private String stagePromptPathEnAction;
    @Value("${ollama.stage.prompt.en.maintenance}")
    private String stagePromptPathEnMaintenance;
    @Value("${ollama.stage.prompt.en.relapse}")
    private String stagePromptPathEnRelapse;

    @Value("${ollama.stage.prompt.bn.precontemplation}")
    private String stagePromptPathBnPrecontemplation;
    @Value("${ollama.stage.prompt.bn.contemplation}")
    private String stagePromptPathBnContemplation;
    @Value("${ollama.stage.prompt.bn.preparation}")
    private String stagePromptPathBnPreparation;
    @Value("${ollama.stage.prompt.bn.action}")
    private String stagePromptPathBnAction;
    @Value("${ollama.stage.prompt.bn.maintenance}")
    private String stagePromptPathBnMaintenance;
    @Value("${ollama.stage.prompt.bn.relapse}")
    private String stagePromptPathBnRelapse;

    // The 5 Transtheoretical Model stages plus Relapse, checked longest-name-first so
    // "precontemplation" isn't mistaken for "contemplation" (a substring of it).
    private static final String[] STAGE_KEYS = {
            "precontemplation", "contemplation", "preparation", "action", "maintenance", "relapse"
    };
    private static final Pattern STAGE_LINE_PATTERN = Pattern.compile("(?im)^\\s*Stage:\\s*(.+)$");

    // Raw system prompt text per language/session-type, loaded from resources/prompts/*.md.
    // Used directly by generate v0.2 ("system" field) and chat mode (role:"system" message),
    // and as the fallback when stage-specific prompts are disabled/unmatched/blank.
    private String systemPromptEnFirstSession;
    private String systemPromptBnFirstSession;
    private String systemPromptEnFollowUp;
    private String systemPromptBnFollowUp;

    // stage key ("en_action", "bn_maintenance", ...) -> prompt text, loaded from resources/prompts/stages/*.md
    private final Map<String, String> stagePrompts = new HashMap<>();

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public OllamaService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * The system prompt for each of the 4 session types lives in its own .md file under
     * resources/prompts/, plus 12 more under resources/prompts/stages/ for the optional
     * stage-specific follow-up prompts. All loaded once at startup as raw text — v0.1's
     * templates keep their {{SYSTEM_PROMPT}} placeholder unsubstituted here (rather than
     * baked in at startup like before) because which system text applies can now vary
     * per request (stage-specific vs. generic), so the substitution moved to buildTemplate().
     */
    @PostConstruct
    private void loadSystemPrompts() {
        systemPromptEnFirstSession = readClasspathFile("prompts/en_first_session.md");
        systemPromptBnFirstSession = readClasspathFile("prompts/bn_first_session.md");
        systemPromptEnFollowUp = readClasspathFile("prompts/en_follow_up.md");
        systemPromptBnFollowUp = readClasspathFile("prompts/bn_follow_up.md");

        stagePrompts.put("en_precontemplation", readClasspathFile(stagePromptPathEnPrecontemplation));
        stagePrompts.put("en_contemplation", readClasspathFile(stagePromptPathEnContemplation));
        stagePrompts.put("en_preparation", readClasspathFile(stagePromptPathEnPreparation));
        stagePrompts.put("en_action", readClasspathFile(stagePromptPathEnAction));
        stagePrompts.put("en_maintenance", readClasspathFile(stagePromptPathEnMaintenance));
        stagePrompts.put("en_relapse", readClasspathFile(stagePromptPathEnRelapse));

        stagePrompts.put("bn_precontemplation", readClasspathFile(stagePromptPathBnPrecontemplation));
        stagePrompts.put("bn_contemplation", readClasspathFile(stagePromptPathBnContemplation));
        stagePrompts.put("bn_preparation", readClasspathFile(stagePromptPathBnPreparation));
        stagePrompts.put("bn_action", readClasspathFile(stagePromptPathBnAction));
        stagePrompts.put("bn_maintenance", readClasspathFile(stagePromptPathBnMaintenance));
        stagePrompts.put("bn_relapse", readClasspathFile(stagePromptPathBnRelapse));
    }

    private String readClasspathFile(String classpathLocation) {
        try (InputStream in = new ClassPathResource(classpathLocation).getInputStream()) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).strip();
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load system prompt: " + classpathLocation, e);
        }
    }

    // ---------------------------------------------------------------
    // Public entry point  —  languagePreference is "en" or "bn"
    // ---------------------------------------------------------------

    /**
     * Generate AI response using the model that matches the session's language and type.
     * @param userMessage        The current user message
     * @param recentMessages     Recent conversation history for context
     * @param languagePreference "en" or "bn"
     * @param sessionType        "initial" or "follow_up"
     * @param deltaSummary       Patient's latest clinical delta summary (appended for follow_up; null otherwise)
     * @param patientName        Patient's name, used only to name the request-payload log file
     * @param sessionId          Chat session id, used only to name the request-payload log file
     */
    public String generateResponse(String userMessage, List<ChatMessage> recentMessages,
                                   String languagePreference, String sessionType, String deltaSummary,
                                   String patientName, String sessionId) {
        String resolvedLang = resolveLanguage(languagePreference);

        try {
            // Ensure proper UTF-8
            String encodedUserMessage = new String(userMessage.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);

            String model = getModelForLanguage(resolvedLang);

            System.out.println("OllamaService: model=" + model + " lang=" + resolvedLang
                    + " sessionType=" + sessionType + " apiMode=" + apiMode + " generateVersion=" + generateVersion);

            if ("chat".equalsIgnoreCase(apiMode)) {
                String systemPrompt = buildEffectiveSystemPrompt(resolvedLang, sessionType, deltaSummary);
                return generateResponseViaChat(encodedUserMessage, recentMessages, model, systemPrompt, resolvedLang, patientName, sessionId);
            } else if ("v2".equalsIgnoreCase(generateVersion)) {
                String template = getTemplateForLanguage(resolvedLang, sessionType);
                String systemPrompt = buildEffectiveSystemPrompt(resolvedLang, sessionType, deltaSummary);
                return generateResponseViaGenerate(encodedUserMessage, recentMessages, model, template, systemPrompt, resolvedLang, patientName, sessionId);
            } else {
                String template = buildTemplate(resolvedLang, sessionType, deltaSummary);
                return generateResponseViaGenerate(encodedUserMessage, recentMessages, model, template, null, resolvedLang, patientName, sessionId);
            }

        } catch (ResourceAccessException e) {
            System.err.println("Ollama service unavailable: " + e.getMessage());
            return getFallbackResponse(resolvedLang, "AI service temporarily unavailable");
        } catch (Exception e) {
            System.err.println("Error generating AI response: " + e.getMessage());
            e.printStackTrace();
            return getFallbackResponse(resolvedLang, "Sorry, I couldn't process your message right now");
        }
    }

    /**
     * /api/generate — template is passed directly (substitutes {{ .Prompt }} with prompt).
     * Conversation history is embedded in prompt using the model's native token format.
     * For generate v0.2, systemPrompt is also sent as a separate "system" field, which
     * Ollama substitutes into the template's {{ .System }} variable; v0.1 leaves it null
     * since the system text is already baked into the template string.
     */
    private String generateResponseViaGenerate(String userMessage, List<ChatMessage> recentMessages,
                                                 String model, String template, String systemPrompt, String lang,
                                                 String patientName, String sessionId) {
        String prompt = buildPrompt(userMessage, recentMessages, lang);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("prompt", prompt);
        requestBody.put("stream", false);
        if (template != null) {
            requestBody.put("template", template);
        }
        if (systemPrompt != null && !systemPrompt.isBlank()) {
            requestBody.put("system", systemPrompt);
        }
        requestBody.put("options", getOptionsForLanguage(lang));

        logPayloadToFile("/api/generate", requestBody, patientName, sessionId);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, jsonHeaders());

        String url = ollamaBaseUrl + "/api/generate";
        ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

        if (response.getStatusCode() == HttpStatus.OK) {
            String responseBody = decodeUtf8(response.getBody());
            return parseOllamaGenerateResponse(responseBody, lang);
        }
        return getFallbackResponse(lang, "Server error occurred");
    }

    /**
     * /api/chat — the "template" field is not part of this endpoint's request schema, so the
     * system prompt is sent as a normal role:"system" message instead.
     */
    private String generateResponseViaChat(String userMessage, List<ChatMessage> recentMessages,
                                            String model, String systemPrompt, String lang,
                                            String patientName, String sessionId) {
        List<Map<String, String>> messages = buildChatMessages(userMessage, recentMessages, systemPrompt);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", messages);
        requestBody.put("stream", false);
        requestBody.put("options", getOptionsForLanguage(lang));

        logPayloadToFile("/api/chat", requestBody, patientName, sessionId);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, jsonHeaders());

        String url = ollamaBaseUrl + "/api/chat";
        ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

        if (response.getStatusCode() == HttpStatus.OK) {
            String responseBody = decodeUtf8(response.getBody());
            return parseOllamaChatResponse(responseBody, lang);
        }
        return getFallbackResponse(lang, "Server error occurred");
    }

    /**
     * Appends the exact JSON payload being sent to Ollama to a per-patient/session log file
     * under ollamaLogDir, e.g. logs/ollama-payloads/John_Doe_a1b2c3.log. One file accumulates
     * every request made during that session.
     */
    private void logPayloadToFile(String endpoint, Map<String, Object> requestBody, String patientName, String sessionId) {
        if (!payloadLoggingEnabled) {
            return;
        }
        try {
            Path dir = Paths.get(ollamaLogDir);
            Files.createDirectories(dir);

            String fileName = sanitizeForFilename(patientName) + "_" + sanitizeForFilename(sessionId) + ".log";
            Path file = dir.resolve(fileName);

            String entry = Instant.now() + " | " + endpoint + " -> "
                    + objectMapper.writeValueAsString(requestBody) + System.lineSeparator();

            Files.writeString(file, entry, StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (Exception e) {
            System.err.println("Failed to write Ollama request payload log: " + e.getMessage());
        }
    }

    /** Strips characters that aren't filesystem-safe so patient name/session id can be used in a file name. */
    private String sanitizeForFilename(String value) {
        if (value == null || value.isBlank()) return "unknown";
        return value.trim().replaceAll("[^a-zA-Z0-9_-]", "_");
    }

    private HttpHeaders jsonHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setAcceptCharset(List.of(StandardCharsets.UTF_8));
        headers.set("Accept", "application/json;charset=UTF-8");
        return headers;
    }

    private String decodeUtf8(String s) {
        return s == null ? null : new String(s.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
    }

    /** Backward-compatible overload — defaults to English, initial session, no delta. */
    public String generateResponse(String userMessage, List<ChatMessage> recentMessages) {
        return generateResponse(userMessage, recentMessages, "en", "initial", null, null, null);
    }

    /** Backward-compatible overload — language provided, initial session, no delta. */
    public String generateResponse(String userMessage, List<ChatMessage> recentMessages, String languagePreference) {
        return generateResponse(userMessage, recentMessages, languagePreference, "initial", null, null, null);
    }

    /** Backward-compatible overload — language + sessionType provided, no delta. */
    public String generateResponse(String userMessage, List<ChatMessage> recentMessages,
                                   String languagePreference, String sessionType) {
        return generateResponse(userMessage, recentMessages, languagePreference, sessionType, null, null, null);
    }

    /** Backward-compatible overload — language + sessionType + deltaSummary, no patient/session id for log naming. */
    public String generateResponse(String userMessage, List<ChatMessage> recentMessages,
                                   String languagePreference, String sessionType, String deltaSummary) {
        return generateResponse(userMessage, recentMessages, languagePreference, sessionType, deltaSummary, null, null);
    }

    // ---------------------------------------------------------------
    // Language resolution helpers
    // ---------------------------------------------------------------

    /**
     * Normalise whatever the caller sends into "en" or "bn".
     * Accepts: "en", "bn", "EN", "BN", null, blank → defaults to "en".
     */
    private String resolveLanguage(String languagePreference) {
        if (languagePreference == null || languagePreference.isBlank()) {
            return "en";
        }
        String lower = languagePreference.trim().toLowerCase();
        return lower.equals("bn") ? "bn" : "en";
    }

    /**
     * Return the Ollama model tag for the given language code.
     */
    private String getModelForLanguage(String lang) {
        return "bn".equals(lang) ? modelBn : modelEn;
    }

    /**
     * Return language-specific Ollama options.
     * English uses Llama parameters, Bengali uses Gemma3 parameters.
     */
    private Map<String, Object> getOptionsForLanguage(String lang) {
        Map<String, Object> options = new HashMap<>();

        if ("bn".equals(lang)) {
            // Gemma3 Bengali model parameters
            options.put("temperature", temperatureBn);
            options.put("top_p", topPBn);
            options.put("top_k", topKBn);
            options.put("repeat_penalty", repeatPenaltyBn);
            options.put("num_ctx", contextWindowBn);
            options.put("num_predict", maxTokensBn);
            options.put("repeat_last_n", repeatLastNBn);
            options.put("frequency_penalty", frequencyPenaltyBn);
            options.put("presence_penalty", presencePenaltyBn);
            options.put("typical_p", typicalPBn);
            options.put("num_batch", numBatchBn);
            options.put("num_gpu", numGpuBn);

            // Gemma3 stop sequences
            List<String> stopSequences = new ArrayList<>();
            stopSequences.add("<start_of_turn>");
            stopSequences.add("<end_of_turn>");
            options.put("stop", stopSequences);
        } else {
            // Llama English model parameters
            options.put("temperature", temperatureEn);
            options.put("top_p", topPEn);
            options.put("top_k", topKEn);
            options.put("repeat_penalty", repeatPenaltyEn);
            options.put("num_ctx", contextWindowEn);
            options.put("num_predict", maxTokensEn);
            options.put("num_gpu", numGpuEn);

            // Stop sequences from application.properties
            if (stopSequencesEn != null && !stopSequencesEn.isBlank()) {
                List<String> stops = new ArrayList<>();
                for (String s : stopSequencesEn.split(",")) {
                    stops.add(s.trim());
                }
                options.put("stop", stops);
            }
        }

        return options;
    }

    /**
     * Selects the right v0.1 template for language + sessionType, substitutes its
     * {{SYSTEM_PROMPT}} placeholder (stage-aware if enabled — see resolveSystemPromptText()),
     * then injects the delta summary directly after that system prompt block (before the
     * first user turn) when one is provided.
     *
     * Final prompt structure for follow-up with delta:
     *   1. Follow-up system prompt  (stage-specific if matched, else generic — embedded in template)
     *   2. Patient Memory from previous sessions
     *   3. {{ .Prompt }} / {{ .Response }} turns
     */
    private String buildTemplate(String lang, String sessionType, String deltaSummary) {
        String tpl = getTemplateForLanguage(lang, sessionType);
        if (tpl == null) return null;

        String systemText = resolveSystemPromptText(lang, sessionType, deltaSummary);
        tpl = tpl.replace("{{SYSTEM_PROMPT}}", systemText != null ? systemText : "");

        if (deltaSummary != null && !deltaSummary.isBlank() && "follow_up".equals(sessionType)) {
            String summaryBlock = "\n\n[Patient Memory from previous sessions]\n" + deltaSummary.trim() + "\n";

            // Both Llama and Gemma follow-up templates embed the system instruction
            // directly in the turn that precedes {{ .Prompt }}. Insert the summary
            // there so it stays inside that turn, after the system instruction.
            if (tpl.contains("{{ .Prompt }}")) {
                tpl = tpl.replace("{{ .Prompt }}", summaryBlock + "{{ .Prompt }}");
            }
        }

        return tpl;
    }

    /**
     * Returns the template for a given language and session type.
     *
     * generate v0.2 (generateVersion=v2) uses one structural template per language —
     * it carries no session-specific text, so first_session/follow_up routing doesn't
     * apply there.
     *
     * generate v0.1 routing:
     *   "initial"   → en_first_session / bn_first_session
     *                 (used by "original" always, and "srijit" session 1)
     *   "follow_up" → en_follow_up / bn_follow_up + delta injected
     *                 (used by "srijit" session 2+)
     *                 falls back to first_session template if follow_up is not configured
     */
    public String getTemplateForLanguage(String languagePreference, String sessionType) {
        String lang = resolveLanguage(languagePreference);

        if ("v2".equalsIgnoreCase(generateVersion)) {
            return "bn".equals(lang) ? templateV2Bn : templateV2En;
        }

        String tpl;
        if ("follow_up".equals(sessionType)) {
            tpl = "bn".equals(lang) ? templateBnFollowUp : templateEnFollowUp;
            if (tpl == null || tpl.isBlank()) {
                tpl = "bn".equals(lang) ? templateBnFirstSession : templateEnFirstSession;
            }
        } else {
            tpl = "bn".equals(lang) ? templateBnFirstSession : templateEnFirstSession;
        }
        return (tpl != null && !tpl.isBlank()) ? tpl : null;
    }

    /** Backward-compatible overload — defaults to initial session template. */
    public String getTemplateForLanguage(String languagePreference) {
        return getTemplateForLanguage(languagePreference, "initial");
    }

    /**
     * Returns the raw system prompt text (no wrapper tokens) for a given language and
     * session type. Used by generate v0.2 (sent as the "system" field) and chat mode
     * (sent as a role:"system" message) — both want the plain instruction text, not a
     * pre-rendered template.
     */
    private String getSystemPromptForLanguage(String languagePreference, String sessionType) {
        String lang = resolveLanguage(languagePreference);
        String prompt;
        if ("follow_up".equals(sessionType)) {
            prompt = "bn".equals(lang) ? systemPromptBnFollowUp : systemPromptEnFollowUp;
            if (prompt == null || prompt.isBlank()) {
                prompt = "bn".equals(lang) ? systemPromptBnFirstSession : systemPromptEnFirstSession;
            }
        } else {
            prompt = "bn".equals(lang) ? systemPromptBnFirstSession : systemPromptEnFirstSession;
        }
        return (prompt != null && !prompt.isBlank()) ? prompt : null;
    }

    /**
     * System prompt text (stage-aware if enabled) plus, for follow-up sessions with a
     * delta summary, the patient's memory block appended after it. Used by generate
     * v0.2 and chat mode.
     */
    private String buildEffectiveSystemPrompt(String lang, String sessionType, String deltaSummary) {
        String systemPrompt = resolveSystemPromptText(lang, sessionType, deltaSummary);
        if (systemPrompt == null) return null;

        if (deltaSummary != null && !deltaSummary.isBlank() && "follow_up".equals(sessionType)) {
            return systemPrompt + "\n\n[Patient Memory from previous sessions]\n" + deltaSummary.trim();
        }
        return systemPrompt;
    }

    /**
     * Returns the system prompt text to use for a follow-up session: the stage-specific
     * prompt if ollama.stage_specific_prompts.enabled=true AND a "Stage: <value>" line in
     * deltaSummary matches one of the 6 stages (5 Transtheoretical Model stages + Relapse)
     * AND that stage's .md file isn't blank; otherwise falls back to the generic
     * getSystemPromptForLanguage().
     */
    private String resolveSystemPromptText(String lang, String sessionType, String deltaSummary) {
        if (stageSpecificPromptsEnabled && "follow_up".equals(sessionType)) {
            String stageKey = detectStage(deltaSummary);
            if (stageKey != null) {
                String stagePrompt = stagePrompts.get(lang + "_" + stageKey);
                if (stagePrompt != null && !stagePrompt.isBlank()) {
                    return stagePrompt;
                }
            }
        }
        return getSystemPromptForLanguage(lang, sessionType);
    }

    /**
     * Parses the "Stage: <value>" line out of deltaSummary (built in UserRepositoryImpl
     * from session_deltas.readiness_after) and matches it against the 6 known stage
     * names. Checked longest-name-first so "precontemplation" isn't mistaken for
     * "contemplation", which is a substring of it.
     */
    private String detectStage(String deltaSummary) {
        if (deltaSummary == null || deltaSummary.isBlank()) return null;
        Matcher m = STAGE_LINE_PATTERN.matcher(deltaSummary);
        if (!m.find()) return null;

        String raw = m.group(1).trim().toLowerCase();
        for (String key : STAGE_KEYS) {
            if (raw.contains(key)) return key;
        }
        return null;
    }

    // ---------------------------------------------------------------
    // Prompt builder for /api/generate
    // ---------------------------------------------------------------

    /**
     * Builds the prompt string sent to Ollama /api/generate as {{ .Prompt }}.
     *
     * For the first session (no history), this is just the current user message —
     * the template provides the system block and the user-turn wrapping.
     *
     * For follow-up sessions, conversation history is embedded using the model's
     * native token format so that alternating turns are preserved correctly:
     *
     *   Llama 3:  [past_user]<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n
     *             [past_bot]<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n
     *             [current_user]
     *
     *   Gemma 3:  [past_user]<end_of_turn>\n<start_of_turn>model\n
     *             [past_bot]<end_of_turn>\n<start_of_turn>user\n
     *             [current_user]
     *
     * The <eot/end_of_turn> token in the first history entry naturally closes the
     * user-turn that the template opened, letting subsequent raw turn-headers form
     * correctly alternating exchanges.
     */
    private String buildPrompt(String userMessage, List<ChatMessage> recentMessages, String lang) {
        StringBuilder sb = new StringBuilder();

        if (recentMessages != null && !recentMessages.isEmpty()) {
            int startIndex = Math.max(0, recentMessages.size() - maxContextMessages);
            String pendingUser = null;

            for (int i = startIndex; i < recentMessages.size(); i++) {
                ChatMessage msg = recentMessages.get(i);
                if ("system".equals(msg.getSenderType())) continue;

                String content = sanitizeContent(msg.getMessageContent());

                if ("patient".equals(msg.getSenderType())) {
                    pendingUser = content;
                } else if ("bot".equals(msg.getSenderType()) && pendingUser != null) {
                    if ("bn".equals(lang)) {
                        sb.append(pendingUser).append("<end_of_turn>\n")
                          .append("<start_of_turn>model\n")
                          .append(content).append("<end_of_turn>\n")
                          .append("<start_of_turn>user\n");
                    } else {
                        sb.append(pendingUser).append("<|eot_id|>")
                          .append("<|start_header_id|>assistant<|end_header_id|>\n\n")
                          .append(content).append("<|eot_id|>")
                          .append("<|start_header_id|>user<|end_header_id|>\n\n");
                    }
                    pendingUser = null;
                }
            }

            // Orphaned user message with no bot reply yet
            if (pendingUser != null) {
                if ("bn".equals(lang)) {
                    sb.append(pendingUser).append("<end_of_turn>\n<start_of_turn>user\n");
                } else {
                    sb.append(pendingUser).append("<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n");
                }
            }
        }

        sb.append(sanitizeContent(userMessage));
        return sb.toString();
    }

    private String sanitizeContent(String content) {
        if (content == null) return "";
        return new String(content.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
    }

    // ---------------------------------------------------------------
    // Response parser
    // ---------------------------------------------------------------

    private String parseOllamaGenerateResponse(String responseBody, String lang) {
        try {
            JsonNode jsonNode = objectMapper.readTree(responseBody);

            String response = jsonNode.get("response").asText();
            response = new String(response.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            response = response.trim();

            if (response.length() > 500) {
                response = response.substring(0, 497) + "...";
            }

            return response.isEmpty() ? getFallbackResponse(lang, "No response generated") : response;

        } catch (Exception e) {
            System.err.println("Error parsing Ollama generate response: " + e.getMessage());
            return "Error processing AI response.";
        }
    }

    private String parseOllamaChatResponse(String responseBody, String lang) {
        try {
            JsonNode jsonNode = objectMapper.readTree(responseBody);

            JsonNode messageNode = jsonNode.get("message");
            String response = messageNode != null
                    ? messageNode.get("content").asText()
                    : jsonNode.get("response").asText();

            response = new String(response.getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8);
            response = response.trim();

            if (response.length() > 500) {
                response = response.substring(0, 497) + "...";
            }

            return response.isEmpty() ? getFallbackResponse(lang, "No response generated") : response;

        } catch (Exception e) {
            System.err.println("Error parsing Ollama chat response: " + e.getMessage());
            return "Error processing AI response.";
        }
    }

    // ---------------------------------------------------------------
    // /api/chat helpers — only used when ollama.api.mode=chat
    // ---------------------------------------------------------------

    /**
     * Builds the messages array for /api/chat: optional system message, then
     * conversation history (oldest first, capped at maxContextMessages), then
     * the current user message.
     */
    private List<Map<String, String>> buildChatMessages(String userMessage, List<ChatMessage> recentMessages,
                                                          String systemPrompt) {
        List<Map<String, String>> messages = new ArrayList<>();

        if (systemPrompt != null && !systemPrompt.isBlank()) {
            Map<String, String> systemMessage = new HashMap<>();
            systemMessage.put("role", "system");
            systemMessage.put("content", systemPrompt);
            messages.add(systemMessage);
        }

        if (recentMessages != null && !recentMessages.isEmpty()) {
            int startIndex = Math.max(0, recentMessages.size() - maxContextMessages);
            for (int i = startIndex; i < recentMessages.size(); i++) {
                ChatMessage msg = recentMessages.get(i);
                if ("system".equals(msg.getSenderType())) continue;

                Map<String, String> chatMsg = new HashMap<>();
                if ("patient".equals(msg.getSenderType())) {
                    chatMsg.put("role", "user");
                } else if ("bot".equals(msg.getSenderType())) {
                    chatMsg.put("role", "assistant");
                } else {
                    continue;
                }
                chatMsg.put("content", sanitizeContent(msg.getMessageContent()));
                messages.add(chatMsg);
            }
        }

        Map<String, String> currentMessage = new HashMap<>();
        currentMessage.put("role", "user");
        currentMessage.put("content", userMessage);
        messages.add(currentMessage);

        return messages;
    }

    // ---------------------------------------------------------------
    // Fallback responses  —  language-aware
    // ---------------------------------------------------------------

    /**
     * Return a human-friendly fallback in the correct language when Ollama is down.
     */
    private String getFallbackResponse(String lang, String reason) {
        System.out.println("Using fallback response. Reason: " + reason + " | Language: " + lang);

        if ("bn".equals(lang)) {
            return "আমি এই মুহূর্তে আমার AI সহকারীর সাথে সংযোগ স্থাপন করতে পারছি না। " +
                    "অনুগ্রহ করে একটু পরে আবার চেষ্টা করুন, অথবা সমস্যা অব্যাহত থাকলে সহায়তা দলের সাথে যোগাযোগ করুন।";
        }
        return "I'm having trouble connecting to my AI assistant right now. " +
                "Please try again in a moment, or contact support if the issue persists.";
    }

    // ---------------------------------------------------------------
    // Health / introspection
    // ---------------------------------------------------------------

    /**
     * Quick health-check: is Ollama reachable at all?
     */
    public boolean isOllamaAvailable() {
        try {
            String url = ollamaBaseUrl + "/api/tags";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode() == HttpStatus.OK;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Check whether a specific model is already pulled on this Ollama instance.
     * Useful to call before starting a Bengali session so you can warn the user early.
     */
    public boolean isModelAvailable(String languagePreference) {
        String targetModel = getModelForLanguage(resolveLanguage(languagePreference));
        try {
            String url = ollamaBaseUrl + "/api/tags";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode models = root.get("models");
                if (models != null && models.isArray()) {
                    for (JsonNode model : models) {
                        if (targetModel.equals(model.get("name").asText())) {
                            return true;
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error checking model availability: " + e.getMessage());
        }
        return false;
    }

    /**
     * Return raw JSON from /api/tags (list of all pulled models).
     */
    public String getAvailableModels() {
        try {
            String url = ollamaBaseUrl + "/api/tags";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            if (response.getStatusCode() == HttpStatus.OK) {
                return response.getBody();
            }
        } catch (Exception e) {
            System.err.println("Error getting available models: " + e.getMessage());
        }
        return "{}";
    }

    // ---------------------------------------------------------------
    // Getters for config / testing
    // ---------------------------------------------------------------

    public String getOllamaBaseUrl() {
        return ollamaBaseUrl;
    }

    /** Returns the English model tag. */
    public String getModelEn() {
        return modelEn;
    }

    /** Returns the Bengali model tag. */
    public String getModelBn() {
        return modelBn;
    }

    /** Returns whichever model tag matches the given language code. */
    public String getModelForLanguageCode(String languagePreference) {
        return getModelForLanguage(resolveLanguage(languagePreference));
    }

    // For backward compatibility with existing health check endpoint
    public String getDefaultModel() {
        return modelEn;
    }
}

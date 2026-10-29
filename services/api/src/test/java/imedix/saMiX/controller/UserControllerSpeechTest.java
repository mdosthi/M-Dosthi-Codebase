package imedix.saMiX.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import imedix.saMiX.dao.UserRepository;
import imedix.saMiX.model.ChatMessage;
import imedix.saMiX.model.ChatSession;
import imedix.saMiX.service.OllamaSpeechService;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class UserControllerSpeechTest {
    private static final String MESSAGE_ID = "msg_12345678-1234-1234-1234-123456789abc";

    @Mock
    private UserRepository userRepository;

    @Mock
    private OllamaSpeechService speechService;

    private UserController controller;
    private Authentication authentication;

    @BeforeEach
    void setUp() {
        controller = new UserController();
        ReflectionTestUtils.setField(controller, "userRepository", userRepository);
        ReflectionTestUtils.setField(controller, "ollamaSpeechService", speechService);
        authentication = UsernamePasswordAuthenticationToken.authenticated(
                "patient.login", null, List.of());
    }

    private void stubPatient() {
        when(userRepository.getUserInfo("patient.login"))
                .thenReturn(Map.of("uid", "PAT-1", "type", "pat"));
    }

    @Test
    void returnsAudioOnlyForAnOwnedEnglishAssistantMessage() {
        stubPatient();
        ChatMessage message = new ChatMessage(MESSAGE_ID, "chat-1", 1, "bot", "Hello.");
        ChatSession session = new ChatSession();
        session.setSessionId("chat-1");
        session.setPatId("PAT-1");
        session.setLanguagePreference("en");
        when(userRepository.getAssistantMessageForPatient(MESSAGE_ID, "PAT-1")).thenReturn(message);
        when(userRepository.getChatSessionById("chat-1")).thenReturn(session);
        when(speechService.isEnabled()).thenReturn(true);
        when(speechService.supportsLanguage("en")).thenReturn(true);
        when(speechService.synthesize("Hello.")).thenReturn(new byte[]{1, 2, 3});

        ResponseEntity<?> response = controller.generateSpeech(
                Map.of("message_id", MESSAGE_ID), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getContentType()).isEqualTo(MediaType.parseMediaType("audio/wav"));
        assertThat(response.getHeaders().getCacheControl()).contains("no-store");
        assertThat(response.getBody()).isEqualTo(new byte[]{1, 2, 3});
    }

    @Test
    void hidesMessagesNotOwnedByTheAuthenticatedPatient() {
        stubPatient();
        when(userRepository.getAssistantMessageForPatient(MESSAGE_ID, "PAT-1")).thenReturn(null);

        ResponseEntity<?> response = controller.generateSpeech(
                Map.of("message_id", MESSAGE_ID), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        verify(speechService, never()).synthesize(org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void rejectsArbitraryTextPayloads() {
        ResponseEntity<?> response = controller.generateSpeech(
                Map.of("message_id", MESSAGE_ID, "text", "not a persisted response"), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verify(userRepository, never()).getUserInfo(org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void doesNotSynthesizeBengaliSessions() {
        stubPatient();
        ChatMessage message = new ChatMessage(MESSAGE_ID, "chat-1", 1, "bot", "বাংলা");
        ChatSession session = new ChatSession();
        session.setSessionId("chat-1");
        session.setPatId("PAT-1");
        session.setLanguagePreference("bn");
        when(userRepository.getAssistantMessageForPatient(MESSAGE_ID, "PAT-1")).thenReturn(message);
        when(userRepository.getChatSessionById("chat-1")).thenReturn(session);

        ResponseEntity<?> response = controller.generateSpeech(
                Map.of("message_id", MESSAGE_ID), authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
        verify(speechService, never()).synthesize(org.mockito.ArgumentMatchers.anyString());
    }
}

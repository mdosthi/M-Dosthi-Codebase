package imedix.saMiX.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.Semaphore;

@Service
public class OllamaSpeechService {
    private static final int MAX_REQUEST_CHARACTERS = 4096;
    private static final int SAMPLE_RATE = 24_000;
    private static final Logger logger = LoggerFactory.getLogger(OllamaSpeechService.class);

    private final String model;
    private final String voice;
    private final String language;
    private final int maximumTextLength;
    private final boolean enabled;
    private final URI speechUri;
    private final Duration timeout;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final Semaphore concurrencyLimit;

    public OllamaSpeechService(
            @Value("${ollama.base.url:http://localhost:11434}") String ollamaBaseUrl,
            @Value("${ollama.speech.enabled:true}") boolean enabled,
            @Value("${ollama.speech.model:phonon}") String model,
            @Value("${ollama.speech.voice:default}") String voice,
            @Value("${ollama.speech.language:en}") String language,
            @Value("${ollama.speech.timeout:30000}") long timeoutMillis,
            @Value("${ollama.speech.max.text.length:12000}") int maximumTextLength,
            @Value("${ollama.speech.max.concurrent:2}") int maximumConcurrentRequests,
            ObjectMapper objectMapper) {
        if (model == null || model.isBlank() || voice == null || voice.isBlank()) {
            throw new IllegalArgumentException("Speech model and voice must be configured");
        }
        if (language == null || !"en".equalsIgnoreCase(language.trim())) {
            throw new IllegalArgumentException("The configured Phonon model supports English only");
        }
        if (timeoutMillis < 1 || timeoutMillis > 300_000 || maximumTextLength < 1 || maximumTextLength > 32_768
                || maximumConcurrentRequests < 1 || maximumConcurrentRequests > 16) {
            throw new IllegalArgumentException("Speech timeout and limits are outside their supported ranges");
        }

        this.enabled = enabled;
        this.model = model;
        this.voice = voice;
        this.language = language.trim().toLowerCase(Locale.ROOT);
        this.maximumTextLength = maximumTextLength;
        this.timeout = Duration.ofMillis(timeoutMillis);
        this.speechUri = URI.create(ollamaBaseUrl.replaceAll("/+$", "") + "/v1/audio/speech");
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder().connectTimeout(timeout).build();
        this.concurrencyLimit = new Semaphore(maximumConcurrentRequests, true);
    }

    public boolean isEnabled() {
        return enabled;
    }

    public boolean supportsLanguage(String requestedLanguage) {
        return language.equalsIgnoreCase(requestedLanguage);
    }

    public byte[] synthesize(String assistantResponse) {
        if (!enabled) {
            throw new SpeechUnavailableException();
        }

        String speechText = SpeechTextPreparer.prepare(assistantResponse);
        if (speechText.isBlank()) {
            throw new IllegalArgumentException("There is no readable text in this response.");
        }
        if (speechText.length() > maximumTextLength) {
            throw new SpeechTextTooLongException();
        }
        if (SpeechTextPreparer.containsUnsupportedLetters(speechText)) {
            throw new UnsupportedSpeechLanguageException();
        }
        if (!concurrencyLimit.tryAcquire()) {
            logger.warn("Speech synthesis rejected because the concurrency limit was reached");
            throw new SpeechCapacityException();
        }

        long startTime = System.nanoTime();
        int segmentCount = 0;
        boolean succeeded = false;
        try {
            ByteArrayOutputStream pcm = new ByteArrayOutputStream();
            List<String> segments = SpeechTextPreparer.splitIntoSegments(speechText, MAX_REQUEST_CHARACTERS);
            segmentCount = segments.size();
            for (String segment : segments) {
                pcm.writeBytes(requestPcm(segment));
            }
            if (pcm.size() == 0) {
                throw new SpeechUnavailableException();
            }
            byte[] audio = toWav(pcm.toByteArray());
            succeeded = true;
            return audio;
        } finally {
            concurrencyLimit.release();
            logger.info("Speech synthesis completed: success={}, segments={}, durationMs={}",
                    succeeded, segmentCount, (System.nanoTime() - startTime) / 1_000_000);
        }
    }

    private byte[] requestPcm(String text) {
        Map<String, String> payload = Map.of(
                "model", model,
                "voice", voice,
                "input", text,
                "response_format", "pcm");

        try {
            byte[] requestBody = objectMapper.writeValueAsBytes(payload);
            HttpRequest request = HttpRequest.newBuilder(speechUri)
                    .timeout(timeout)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofByteArray(requestBody))
                    .build();
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() < 200 || response.statusCode() >= 300 || response.body().length == 0) {
                throw new SpeechUnavailableException();
            }
            return response.body();
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not encode the speech request.", e);
        } catch (IOException e) {
            throw new SpeechUnavailableException();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new SpeechUnavailableException();
        }
    }

    static byte[] toWav(byte[] pcm) {
        if (pcm.length == 0 || pcm.length % 2 != 0) {
            throw new SpeechUnavailableException();
        }
        int byteRate = SAMPLE_RATE * 2;
        ByteBuffer header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN);
        header.put("RIFF".getBytes(StandardCharsets.US_ASCII));
        header.putInt(36 + pcm.length);
        header.put("WAVE".getBytes(StandardCharsets.US_ASCII));
        header.put("fmt ".getBytes(StandardCharsets.US_ASCII));
        header.putInt(16);
        header.putShort((short) 1);
        header.putShort((short) 1);
        header.putInt(SAMPLE_RATE);
        header.putInt(byteRate);
        header.putShort((short) 2);
        header.putShort((short) 16);
        header.put("data".getBytes(StandardCharsets.US_ASCII));
        header.putInt(pcm.length);

        ByteArrayOutputStream wav = new ByteArrayOutputStream(header.capacity() + pcm.length);
        wav.writeBytes(header.array());
        wav.writeBytes(pcm);
        return wav.toByteArray();
    }

    public static class SpeechUnavailableException extends RuntimeException {}

    public static class SpeechCapacityException extends RuntimeException {}

    public static class SpeechTextTooLongException extends RuntimeException {}

    public static class UnsupportedSpeechLanguageException extends RuntimeException {}
}

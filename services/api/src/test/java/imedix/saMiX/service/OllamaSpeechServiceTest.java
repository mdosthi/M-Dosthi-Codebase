package imedix.saMiX.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class OllamaSpeechServiceTest {
    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void synthesizesPcmSegmentsIntoAValidWavResponse() throws IOException {
        AtomicInteger requests = new AtomicInteger();
        startServer(exchange -> {
            requests.incrementAndGet();
            exchange.getRequestBody().readAllBytes();
            byte[] pcm = {1, 0, 2, 0};
            exchange.getResponseHeaders().set("Content-Type", "audio/pcm");
            exchange.sendResponseHeaders(200, pcm.length);
            exchange.getResponseBody().write(pcm);
            exchange.close();
        });

        OllamaSpeechService service = service(true, 5_000, 2_000);
        byte[] wav = service.synthesize("A".repeat(4_097));

        assertThat(requests).hasValue(2);
        assertThat(new String(wav, 0, 4, StandardCharsets.US_ASCII)).isEqualTo("RIFF");
        assertThat(new String(wav, 8, 4, StandardCharsets.US_ASCII)).isEqualTo("WAVE");
        assertThat(ByteBuffer.wrap(wav, 40, 4).order(ByteOrder.LITTLE_ENDIAN).getInt()).isEqualTo(8);
        assertThat(wav).hasSize(52);
    }

    @Test
    void reportsRuntimeFailureWithoutReturningAudio() throws IOException {
        startServer(exchange -> {
            exchange.getRequestBody().readAllBytes();
            exchange.sendResponseHeaders(503, -1);
            exchange.close();
        });

        assertThatThrownBy(() -> service(true, 5_000, 2_000).synthesize("Please listen."))
                .isInstanceOf(OllamaSpeechService.SpeechUnavailableException.class);
    }

    @Test
    void disabledServiceDoesNotContactOllama() throws IOException {
        startServer(exchange -> {
            exchange.sendResponseHeaders(500, -1);
            exchange.close();
        });
        assertThatThrownBy(() -> service(false, 5_000, 2_000).synthesize("Please listen."))
                .isInstanceOf(OllamaSpeechService.SpeechUnavailableException.class);
    }

    @Test
    void enforcesTextLengthAndEnglishLanguage() throws IOException {
        startServer(exchange -> {
            exchange.getRequestBody().readAllBytes();
            exchange.sendResponseHeaders(200, 0);
            exchange.close();
        });
        OllamaSpeechService service = service(true, 5, 2_000);

        assertThatThrownBy(() -> service.synthesize("This response is too long."))
                .isInstanceOf(OllamaSpeechService.SpeechTextTooLongException.class);
        assertThatThrownBy(() -> service.synthesize("বাংলা"))
                .isInstanceOf(OllamaSpeechService.UnsupportedSpeechLanguageException.class);
    }

    @Test
    void reportsSynthesisTimeout() throws IOException {
        startServer(exchange -> {
            try {
                Thread.sleep(250);
                exchange.sendResponseHeaders(200, 0);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                exchange.close();
            }
        });

        assertThatThrownBy(() -> service(true, 5_000, 25).synthesize("Please listen."))
                .isInstanceOf(OllamaSpeechService.SpeechUnavailableException.class);
    }

    @Test
    void rejectsConcurrentRequestsAboveTheConfiguredLimit() throws Exception {
        CountDownLatch requestStarted = new CountDownLatch(1);
        CountDownLatch finishRequest = new CountDownLatch(1);
        startServer(exchange -> {
            try {
                requestStarted.countDown();
                if (!finishRequest.await(2, TimeUnit.SECONDS)) {
                    throw new IOException("Timed out waiting to release test response");
                }
                byte[] pcm = {1, 0};
                exchange.sendResponseHeaders(200, pcm.length);
                exchange.getResponseBody().write(pcm);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                exchange.close();
            }
        });

        OllamaSpeechService service = service(true, 5_000, 2_000, 1);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            var firstRequest = executor.submit(() -> service.synthesize("First response."));
            assertThat(requestStarted.await(1, TimeUnit.SECONDS)).isTrue();
            assertThatThrownBy(() -> service.synthesize("Second response."))
                    .isInstanceOf(OllamaSpeechService.SpeechCapacityException.class);
            finishRequest.countDown();
            assertThat(firstRequest.get(2, TimeUnit.SECONDS)).isNotEmpty();
        } finally {
            finishRequest.countDown();
            executor.shutdownNow();
        }
    }

    @Test
    void doesNotCacheRepeatedSynthesisRequests() throws IOException {
        AtomicInteger requests = new AtomicInteger();
        startServer(exchange -> {
            requests.incrementAndGet();
            exchange.getRequestBody().readAllBytes();
            byte[] pcm = {1, 0};
            exchange.sendResponseHeaders(200, pcm.length);
            exchange.getResponseBody().write(pcm);
            exchange.close();
        });

        OllamaSpeechService service = service(true, 5_000, 2_000);
        service.synthesize("Please listen.");
        service.synthesize("Please listen.");

        assertThat(requests).hasValue(2);
    }

    private void startServer(com.sun.net.httpserver.HttpHandler handler) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/audio/speech", handler);
        server.start();
    }

    private OllamaSpeechService service(boolean enabled, int maximumLength, long timeoutMillis) {
        return service(enabled, maximumLength, timeoutMillis, 2);
    }

    private OllamaSpeechService service(
            boolean enabled, int maximumLength, long timeoutMillis, int maximumConcurrentRequests) {
        return new OllamaSpeechService(
                "http://127.0.0.1:" + server.getAddress().getPort(),
                enabled,
                "phonon",
                "default",
                "en",
                timeoutMillis,
                maximumLength,
                maximumConcurrentRequests,
                new ObjectMapper());
    }
}

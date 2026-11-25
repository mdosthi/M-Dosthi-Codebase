package imedix.saMiX.service;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class SuicideIdeationTrackerTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private WhatsAppService whatsAppService;

    private SuicideIdeationTracker tracker;

    @BeforeEach
    void setUp() {
        tracker = new SuicideIdeationTracker();
        ReflectionTestUtils.setField(tracker, "jdbcTemplate", jdbcTemplate);
        ReflectionTestUtils.setField(tracker, "whatsAppService", whatsAppService);
        ReflectionTestUtils.setField(tracker, "alertRecipient", "91XXXXXXXXXX");
    }

    @Test
    void skipsPollingWhenRequiredTablesAreMissing() {
        when(jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables " +
                        "WHERE table_schema = DATABASE() " +
                        "AND table_name IN ('signal_history', 'session_history', 'login')"))
                .thenReturn(List.of(
                        Map.of("table_name", "session_history"),
                        Map.of("table_name", "login")));

        tracker.init();
        tracker.pollSuicidalSignals();
        tracker.pollSuicidalSignals();

        verify(jdbcTemplate).queryForList(
                "SELECT table_name FROM information_schema.tables " +
                        "WHERE table_schema = DATABASE() " +
                        "AND table_name IN ('signal_history', 'session_history', 'login')");
        verifyNoInteractions(whatsAppService);
    }
}

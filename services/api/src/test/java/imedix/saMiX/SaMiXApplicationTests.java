package imedix.saMiX;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.Map;

@SpringBootTest
class SaMiXApplicationTests {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Test
	void contextLoads() {
		try {
			List<Map<String, Object>> logs = jdbcTemplate.queryForList("SELECT id, message, sent_at FROM whatsapp_logs ORDER BY id DESC LIMIT 5");
			for (Map<String, Object> log : logs) {
				System.out.println("LOG_ENTRY: " + log.get("id") + " | " + log.get("sent_at") + " | '" + log.get("message") + "'");
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

}





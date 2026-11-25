package imedix.saMiX;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SaMiXApplication {

	public static void main(String[] args) {
		SpringApplication.run(SaMiXApplication.class, args);
	}

}

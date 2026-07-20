package com.eatrush;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class EatrushApplication {

	public static void main(String[] args) {
		SpringApplication.run(EatrushApplication.class, args);
	}

}

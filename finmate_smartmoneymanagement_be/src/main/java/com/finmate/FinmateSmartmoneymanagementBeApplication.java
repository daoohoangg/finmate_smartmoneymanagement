package com.finmate;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class FinmateSmartmoneymanagementBeApplication {
// run and boost
    public static void main(String[] args) {
        SpringApplication.run(FinmateSmartmoneymanagementBeApplication.class, args);
    }

}

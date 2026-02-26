package com.akulaku.helloworld.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
import java.time.LocalDateTime;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, Object> hello() {
        return Map.of(
            "message", "Hello World from Akulaku SRE Test!",
            "author", "Arif Hidayatullah",
            "position", "Senior Site Reliability Engineer",
            "timestamp", LocalDateTime.now().toString(),
            "status", "healthy"
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of(
            "status", "UP",
            "service", "hello-world",
            "version", "1.0.0"
        );
    }

    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of(
            "app", "Spring Boot Hello World",
            "environment", System.getenv().getOrDefault("APP_ENV", "production"),
            "java_version", System.getProperty("java.version")
        );
    }
}

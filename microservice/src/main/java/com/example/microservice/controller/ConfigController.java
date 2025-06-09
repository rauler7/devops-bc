package com.example.microservice.controller;

import com.example.microservice.config.AppConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/config")
public class ConfigController {

    private final AppConfig appConfig;

    @Autowired
    public ConfigController(AppConfig appConfig) {
        this.appConfig = appConfig;
    }

    @GetMapping("/app-config")
    public Map<String, String> getAppConfig() {
        Map<String, String> response = new HashMap<>();
        response.put("app_config", appConfig.getAppConfig());
        return response;
    }

    @GetMapping("/app-secret")
    public Map<String, String> getAppSecret() {
        Map<String, String> response = new HashMap<>();
        response.put("app_secret", appConfig.getAppSecret());
        return response;
    }
} 
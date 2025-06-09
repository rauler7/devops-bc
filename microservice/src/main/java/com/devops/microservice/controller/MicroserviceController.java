package com.devops.microservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class MicroserviceController {

    @Value("${VAULT_SECRET:default-secret}")
    private String vaultSecret;

    @Value("${app.name}")
    private String appName;

    @Value("${app.version}")
    private String appVersion;

    @GetMapping("/secret")
    public String getSecret() {
        return "Vault Secret: " + vaultSecret;
    }

    @GetMapping("/config")
    public String getConfig() {
        return String.format("Application: %s (v%s)", appName, appVersion);
    }
} 
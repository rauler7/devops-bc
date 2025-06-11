package com.example.microservice.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class AppConfig {

    @Value("classpath:/vault/secrets/app-config.json")
    private Resource vaultConfigFile;

    private Map<String, String> config = new HashMap<>();

    @PostConstruct
    public void init() throws IOException {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, Object> vaultConfig = mapper.readValue(vaultConfigFile.getInputStream(), Map.class);

        // Extract values from the Vault JSON
        config.put("username", (String) vaultConfig.get("username"));
        config.put("password", (String) vaultConfig.get("password"));
    }

    public String getUsername() {
        return config.get("username");
    }

    public String getPassword() {
        return config.get("password");
    }
}

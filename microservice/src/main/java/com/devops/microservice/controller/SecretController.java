package com.devops.microservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class SecretController {

  @Value("${app.secret}")
  private String appSecret;

  @Value("${app.config.property:default-value}")
  private String configProperty;

  @GetMapping("/secret")
  public String getSecret() {
    return "Secret value: " + appSecret;
  }

  @GetMapping("/config")
  public String getConfig() {
    return "Config property: " + configProperty;
  }
}
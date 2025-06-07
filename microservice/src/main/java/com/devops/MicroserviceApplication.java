package com.devops;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class MicroserviceApplication {

  @Value("${app.secret:default-secret}")
  private String appSecret;

  @Value("${app.config.property:default-config}")
  private String configProperty;

  public static void main(String[] args) {
    SpringApplication.run(MicroserviceApplication.class, args);
  }

  @GetMapping("/secret")
  public String getSecret() {
    return "Secret value: " + appSecret;
  }

  @GetMapping("/config")
  public String getConfig() {
    return "Config property: " + configProperty;
  }

  @GetMapping("/health")
  public String health() {
    return "UP";
  }
}
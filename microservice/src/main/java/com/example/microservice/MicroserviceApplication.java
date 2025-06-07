package com.example.microservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.core.io.ClassPathResource;
import java.io.IOException;
import java.util.Properties;

@SpringBootApplication
@RestController
public class MicroserviceApplication {

  @Value("${GREETING_MESSAGE:Default Greeting}")
  private String greetingMessage;

  public static void main(String[] args) {
    SpringApplication.run(MicroserviceApplication.class, args);
  }

  @GetMapping("/env")
  public String getEnvVariable() {
    return "Environment Variable Value: " + greetingMessage;
  }

  @GetMapping("/config")
  public String getConfigProperty() {
    try {
      Properties props = new Properties();
      props.load(new ClassPathResource("app.properties").getInputStream());
      return "Config Property Value: " + props.getProperty("greeting.message");
    } catch (IOException e) {
      return "Error reading config: " + e.getMessage();
    }
  }
}
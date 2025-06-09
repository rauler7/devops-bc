FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
COPY src/main/resources/application.properties /app/config/application.properties

# Create directory for external configuration
RUN mkdir -p /app/config

# Set environment variables
ENV APP_CONFIG_PATH=/app/config/application.properties
ENV JAVA_OPTS="-Xms256m -Xmx512m"

EXPOSE 8080

# Use shell form to allow environment variable substitution
ENTRYPOINT java $JAVA_OPTS -jar app.jar 
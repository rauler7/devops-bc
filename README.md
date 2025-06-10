# DevOps Bootcamp Solution

## Project Structure

```
devops-bc/
├── terraform/
│   ├── modules/
│   │   ├── jenkins/
│   │   └── vault/
│   └── environments/
│       ├── deployment/
│       └── development/
├── microservice/
│   ├── src/
│   │   └── main/
│   │       ├── java/
│   │       └── resources/
│   ├── Dockerfile
│   └── pom.xml
├── scripts/
│   ├── setup-wsl.sh
│   └── audit-events.sh
└── docs/
    ├── architecture.md
    └── diagrams/
```

## Architecture Diagram

![DevOpsInfraestructure](https://github.com/user-attachments/assets/b3f3fd78-d7dd-4969-9af9-a7f84396f8b6)

## Overview

This project implements a complete DevOps solution with two Kubernetes clusters:

1. Deployment Cluster: Hosts Jenkins and Vault for CI/CD and secrets management
2. Development Cluster: Runs the Java microservice with proper configuration

## Components

### 1. Infrastructure (Terraform)

- **Kubernetes Module**: Provisions Kind clusters for deployment and development
- **Jenkins Module**: Sets up Jenkins with necessary plugins and configurations
- **Vault Module**: Deploys HashiCorp Vault for secrets management

### 2. CI/CD Pipeline (Jenkins)

- Multi-stage pipeline for building, testing, and deploying the microservice
- Integration with Vault for secure secret management
- Automated deployment to development and production environments
- Docker image building and pushing to container registry

### 3. Secrets Management (Vault)

- Secure storage of sensitive information
- Dynamic secrets generation
- Integration with Kubernetes service accounts
- Automated secret rotation

### 4. Microservice

- Spring Boot application with Java 17
- Containerized using Docker
- Kubernetes deployment with Helm charts
- Configurable through ConfigMaps and Secrets

## Prerequisites

- WSL2 with Ubuntu 22.04
- Docker Desktop for Windows
- Terraform v1.5.0+
- kubectl
- helm v3.12.0+
- Java 17
- Maven
- Kind (Kubernetes in Docker)

## Quick Start

1. Clone the repository
2. Run the setup script:
   ```bash
   ./scripts/setup-wsl.sh
   ```
3. Initialize Terraform:
   ```bash
   cd terraform/environments/deployment
   terraform init
   terraform apply
   ```
4. Deploy the development cluster:
   ```bash
   cd ../development
   terraform init
   terraform apply
   ```

## Detailed Setup

### 1. Infrastructure Setup

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 2. Jenkins Configuration

- Access Jenkins UI at `http://localhost:8080`
- Configure Vault credentials
- Set up Kubernetes credentials
- Configure pipeline

### 3. Vault Setup

- Initialize Vault
- Configure Kubernetes authentication
- Set up secrets engine
- Create policies and roles

### 4. Microservice Deployment

- Build the application:
  ```bash
  mvn clean package
  ```
- Build Docker image:
  ```bash
  docker build -t microservice:latest .
  ```
- Deploy using Helm:
  ```bash
  helm upgrade --install microservice ./helm
  ```

## Security Features

- Vault integration for secrets management
- Kubernetes RBAC for access control
- Network policies for pod-to-pod communication
- TLS encryption for all communications
- Regular security audits and compliance checks

## Monitoring and Logging

- Custom audit logging for security events

## Troubleshooting

### Common Issues

1. **Jenkins Pipeline Failures**

   - Check Vault connectivity
   - Verify Kubernetes credentials
   - Review pipeline logs

2. **Vault Access Issues**

   - Verify Kubernetes authentication
   - Check token validity
   - Review policies and roles

3. **Deployment Failures**
   - Check resource limits
   - Verify ConfigMap and Secret existence
   - Review pod logs

## License

MIT

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
- Configure pipeline

#### Jenkins Credentials Setup

1. **GitHub Credentials**

   - Navigate to Jenkins > Manage Jenkins > Credentials > System > Global credentials
   - Add new credentials with type "Username with password"
   - ID: `github-credentials`
   - Username: Your GitHub username
   - Password: Your GitHub personal access token
   - Description: "GitHub credentials for repository access"

2. **Vault Credentials**
   - Navigate to Jenkins > Manage Jenkins > Credentials > System > Global credentials
   - Add new credentials with type "Secret text"
   - ID: `vault-token`
   - Secret: Your Vault token
   - Description: "Vault token for secrets access"
![Jenkins creds](https://github.com/user-attachments/assets/186189da-10fd-4951-8cc2-843143ec89e8)


#### Multibranch Pipeline Configuration

1. **Pipeline Setup**

   - Create a new Multibranch Pipeline in Jenkins
   - Configure source as GitHub repository
   - Set branch source to your repository URL
   - Configure credentials using the previously created GitHub credentials
   - Set build configuration mode to "by Jenkinsfile"
   - Enable "Discover branches" and "Discover pull requests"
![mb-pipeline-conf](https://github.com/user-attachments/assets/ba7e1057-108f-4225-8a0e-69ca1b7f5ab2)
![mb-pipeline creation](https://github.com/user-attachments/assets/1db92824-0590-45f2-8a62-fbf57cfa0565)


2. **Pipeline Stages**
   ```groovy
   pipeline {
       agent any
       stages {
           stage('Build') {
               steps {
                   // Maven build steps
               }
           }
           stage('Test') {
               steps {
                   // Unit and integration tests
               }
           }
           stage('Security Scan') {
               steps {
                   // Security scanning steps
               }
           }
           stage('Deploy') {
               steps {
                   // Kubernetes deployment steps
               }
           }
       }
   }
   ```

#### Kubelet Audit Configuration

1. **Audit Policy Setup**

   - Configure audit policy in `/etc/kubernetes/audit/audit-policy.yaml`:

   ```yaml
   apiVersion: audit.k8s.io/v1
   kind: Policy
   rules:
    - level: Metadata
      namespaces: ["kube-system"]
      verbs: ["get", "list", "watch"]
    - level: RequestResponse
      resources:
       - group: ""
         resources: ["secrets", "configmaps"]
   ```

2. **Audit Logging**

   - Audit logs are stored in `/var/log/kubernetes/audit/`
   - Log format includes:
     - Timestamp
     - Request ID
     - User information
     - Resource details
     - Response status
     - Request/Response bodies for sensitive operations

3. **Log Analysis**
   - Use the audit-events.sh script to analyze audit logs:
   ```bash
   ./scripts/audit-events.sh
   ```
   - Script provides:
     - Failed authentication attempts
     - Unauthorized access attempts
     - Changes to sensitive resources
     - Pod creation/deletion events

[Screenshots to be added here]

### 3. Vault Setup

- Initialize Vault
- Configure Kubernetes authentication
- Set up secrets engine
- Create policies and roles

#### Vault Configuration Details

1. **Jenkins Policy**

   ```hcl
       path "secret/data/jenkins/*" {
          capabilities = ["read", "list"]
        }
    
        path "kubeconfig/data/*" {
          capabilities = ["read", "list"]
        }
    
        # Grant read access to the specific kubeconfig path
        path "kubeconfig/data/development/kubeconfig" {
          capabilities = ["read"]
        }
    
        # Grant read access to the microservice secrets path
        path "secret/microservice/*" {
          capabilities = ["read"]
        }
    
        # Allow listing secrets in the microservice path (optional, but helpful for debugging)
        path "secret/microservice" {
          capabilities = ["list"]
        }
   ```

2. **Deployment and microservice Secrets**
   - Create a new secret in Vault:
   - Configure Kubernetes authentication for the pipeline
   - Create a policy for jenkins service account
    ![secrets](https://github.com/user-attachments/assets/45d5666f-2a2b-47a5-b923-d76a08d6cdb6)


3. **Authentication Methods**
![auth](https://github.com/user-attachments/assets/5857e665-897d-45da-9f16-96aaf2a69a66)


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
![image](https://github.com/user-attachments/assets/e7b5c3d0-a703-4ce8-bafc-256d97089e7d)

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

# DevOps Bootcamp Solution

## Project Structure

```
devops-bc/
├── terraform/
│   ├── modules/
│   │   ├── kubernetes/
│   │   ├── jenkins/
│   │   └── vault/
│   └── environments/
│       ├── deployment/
│       └── development/
├── kubernetes/
│   ├── jenkins/
│   │   ├── values.yaml
│   │   └── jenkinsfile
│   ├── vault/
│   │   └── values.yaml
│   └── microservice/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
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

## Overview

This project implements a complete DevOps solution with two Kubernetes clusters:

1. Deployment Cluster: Hosts Jenkins and Vault for CI/CD and secrets management
2. Development Cluster: Runs the Java microservice with proper configuration

## Prerequisites

- WSL2 with Ubuntu 22.04
- Docker Desktop for Windows
- Terraform v1.5.0+
- kubectl
- helm v3.12.0+
- Java 17
- Maven

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

## Architecture

The solution implements a modern DevOps pipeline with:

- Infrastructure as Code using Terraform
- CI/CD with Jenkins
- Secrets Management with Vault
- Container Orchestration with Kubernetes
- Monitoring and Auditing with custom CronJobs

## Additional Features

- Custom Resource Definitions for microservice configuration
- Automated event auditing with CronJobs
- Secure secret management
- High availability with multiple replicas

## Documentation

Detailed documentation can be found in the `docs/` directory:

- Architecture overview
- Setup instructions
- Security considerations
- Troubleshooting guide

## License

MIT

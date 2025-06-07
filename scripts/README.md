# DevOps Environment Setup

This directory contains scripts to set up your DevOps development environment in WSL2 Ubuntu 22.04.

## Prerequisites

- WSL2 with Ubuntu 22.04 installed
- Windows 10/11 with WSL2 enabled
- Administrator access to your system

## Setup Instructions

1. Make the setup script executable:

   ```bash
   chmod +x setup_devops_env.sh
   ```

2. Run the setup script:

   ```bash
   ./setup_devops_env.sh
   ```

3. After the script completes:
   - Restart your terminal or run `source ~/.bashrc`
   - Log out and log back in for Docker group changes to take effect

## What's Installed

The script installs the following tools and dependencies:

### Core Tools

- Docker and Docker Compose
- Terraform
- kubectl
- Azure CLI
- Helm

### Development Tools

- Git
- Maven
- JDK
- Node.js and npm
- Python 3 and pip

### Kubernetes Tools

- k9s (Kubernetes CLI tool)
- kubectx and kubens
- kube-ps1 (Kubernetes prompt)

### Python Packages

- awscli
- kubernetes
- docker-compose
- pytest
- pytest-cov
- black
- pylint

## Post-Installation Steps

1. Configure Docker:

   ```bash
   # Start Docker service
   sudo service docker start

   # Verify Docker installation
   docker --version
   docker-compose --version
   ```

2. Configure kubectl:

   ```bash
   # Verify kubectl installation
   kubectl version --client
   ```

3. Configure Terraform:

   ```bash
   # Verify Terraform installation
   terraform version
   ```

4. Configure Azure CLI:
   ```bash
   # Login to Azure
   az login
   ```

## Troubleshooting

If you encounter any issues:

1. Check if all services are running:

   ```bash
   sudo service docker status
   ```

2. Verify your user is in the docker group:

   ```bash
   groups $USER
   ```

3. Check if all tools are properly installed:

   ```bash
   which docker kubectl terraform az helm
   ```

4. If you need to reinstall any component, you can run the specific section of the setup script again.

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Helm Documentation](https://helm.sh/docs/)

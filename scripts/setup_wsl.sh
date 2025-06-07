#!/bin/bash

# Exit on error
set -e

# Update system
echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    unzip \
    jq \
    python3-pip \
    python3-venv \
    make \
    build-essential

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install minikube
echo "Installing minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Install Terraform
echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install -y terraform

# Install Jenkins
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Install Vault
echo "Installing Vault..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install -y vault

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install additional useful tools
echo "Installing additional tools..."
sudo apt-get install -y \
    tree \
    htop \
    net-tools \
    dnsutils \
    iputils-ping \
    telnet \
    nmap \
    tcpdump

# Create project directories
echo "Creating project directories..."
mkdir -p ~/Projects/devops-bc/{terraform,kubernetes,scripts,microservice}

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv ~/Projects/devops-bc/venv
source ~/Projects/devops-bc/venv/bin/activate
pip install --upgrade pip
pip install \
    kubernetes \
    docker \
    requests \
    boto3 \
    azure-cli \
    terraform-local \
    pytest \
    black \
    flake8

# Add useful aliases to .bashrc
echo "Adding useful aliases..."
cat << 'EOF' >> ~/.bashrc

# DevOps aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias tf='terraform'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gc='git commit'
alias gco='git checkout'

# Project directory
export DEVOPS_BC=~/Projects/devops-bc
cd $DEVOPS_BC
EOF

# Reload .bashrc
source ~/.bashrc

echo "Setup completed successfully!"
echo "Please restart your terminal or run 'source ~/.bashrc' to apply changes." 
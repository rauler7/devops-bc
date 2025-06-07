#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[x] $1${NC}"
}

# Update system packages
print_status "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install basic requirements
print_status "Installing basic requirements..."
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
    make \
    python3-pip \
    python3-venv \
    build-essential

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Install kubectl
print_status "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Terraform
print_status "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install -y terraform

# Install Azure CLI
print_status "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Helm
print_status "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# Install k9s (Kubernetes CLI tool)
print_status "Installing k9s..."
curl -sS https://webinstall.dev/k9s | bash

# Install additional development tools
print_status "Installing additional development tools..."
sudo apt-get install -y \
    maven \
    default-jdk \
    nodejs \
    npm

# Install Python packages
print_status "Installing Python packages..."
pip3 install --user \
    awscli \
    kubernetes \
    docker-compose \
    pytest \
    pytest-cov \
    black \
    pylint

# Create necessary directories
print_status "Creating project directories..."
mkdir -p ~/.kube
mkdir -p ~/.terraform.d
mkdir -p ~/.local/bin

# Add local bin to PATH if not already present
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Install additional Kubernetes tools
print_status "Installing additional Kubernetes tools..."
# Install kubectx and kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install kube-ps1
git clone https://github.com/jonmosco/kube-ps1.git ~/.kube-ps1
echo 'source ~/.kube-ps1/kube-ps1.sh' >> ~/.bashrc
echo 'PS1="[\u@\h \W \$(kube_ps1)]\$ "' >> ~/.bashrc

print_status "Installation completed successfully!"
print_warning "Please restart your terminal or run 'source ~/.bashrc' to apply changes"
print_warning "You may need to log out and log back in for the docker group changes to take effect" 
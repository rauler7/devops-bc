terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2.1"
    }
  }
}

# Create the deployment cluster
resource "kind_cluster" "deployment" {
  name = "deployment-cluster"
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\""
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

provider "kubernetes" {
  config_path = kind_cluster.deployment.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = kind_cluster.deployment.kubeconfig_path
  }
}

# Create namespaces
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
  depends_on = [kind_cluster.deployment]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
  depends_on = [kind_cluster.deployment]
}

# Deploy Jenkins
module "jenkins" {
  source = "../../modules/jenkins"

  namespace           = kubernetes_namespace.jenkins.metadata[0].name
  jenkins_chart_version = "4.7.1"
  service_type        = "NodePort"
  ingress_enabled     = true

  depends_on = [kubernetes_namespace.jenkins]
}

# Deploy Vault
module "vault" {
  source = "../../modules/vault"

  namespace         = kubernetes_namespace.vault.metadata[0].name
  vault_chart_version = "0.27.0"
  dev_mode          = true
  standalone_mode   = true

  depends_on = [kubernetes_namespace.vault]
}

# Create Vault secret for Jenkins
resource "kubernetes_secret" "vault_token" {
  metadata {
    name      = "vault-token"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    token = "root" # In production, use a proper token from Vault
  }

  depends_on = [module.vault, module.jenkins]
}


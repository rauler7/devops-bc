terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.8.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.11.0"
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

# Deploy Jenkins with required plugins
module "jenkins" {
  source = "../../modules/jenkins"

  namespace           = kubernetes_namespace.jenkins.metadata[0].name
  service_type        = "NodePort"
  ingress_enabled     = true

  depends_on = [kubernetes_namespace.jenkins]
}

# Deploy Vault
module "vault" {
  source = "../../modules/vault"

  namespace         = kubernetes_namespace.vault.metadata[0].name
  vault_chart_version = "0.28.0"
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

# Enable userpass auth method in Vault
resource "vault_auth_backend" "userpass" {
  type = "userpass"
  path = "userpass"
}

# Create Jenkins user in Vault
resource "vault_generic_endpoint" "jenkins_user" {
  depends_on = [vault_auth_backend.userpass]
  path = "auth/userpass/users/jenkins"
  ignore_absent_fields = true

  data_json = jsonencode({
    password = "jenkins-vault-password"  # Change this to a secure password
    policies = ["jenkins"]
  })
}

# Create Vault policy for Jenkins
resource "vault_policy" "jenkins" {
  name = "jenkins"
  policy = <<EOT
path "secret/data/jenkins/*" {
  capabilities = ["read", "list"]
}

path "kubeconfig/kv/*" {
  capabilities = ["read", "list"]
}
EOT
}

# Create initial secrets for Jenkins
resource "vault_generic_secret" "jenkins_admin" {
  path      = "secret/jenkins/admin"
  data_json = jsonencode({
    username = "admin"
    password = "admin"
  })
}

resource "vault_generic_secret" "jenkins_kubeconfig" {
  path      = "kubeconfig/kv/development/kubeconfig"
  data_json = jsonencode({
    kubeconfig = file("${kind_cluster.deployment.kubeconfig_path}")
  })
}

# Update Jenkins ConfigMap to include Vault configuration
resource "kubernetes_config_map" "jenkins_config" {
  metadata {
    name      = "jenkins-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    "jenkins.yaml" = <<-EOT
      jenkins:
        systemMessage: "Jenkins configured automatically by Terraform"
        numExecutors: 2
        scmCheckoutRetryCount: 3
        mode: NORMAL
        securityRealm:
          local:
            allowsSignup: false
            users:
              - id: "admin"
                password: "admin"
        authorizationStrategy:
          roleBased:
            roles:
              global:
                - name: "admin"
                  permissions:
                    - "Overall/Administer"
                  assignments:
                    - "admin"
        clouds:
          - kubernetes:
              name: "kubernetes"
              serverUrl: "https://kubernetes.default.svc.cluster.local"
              skipTlsVerify: true
              namespace: "jenkins"
              jenkinsUrl: "http://jenkins:8080"
              jenkinsTunnel: "jenkins-agent:50000"
              containerCapStr: "10"
              maxRequestsPerHostStr: "32"
              retentionTimeout: 5
              connectTimeout: 5
              readTimeout: 15
        tool:
          git:
            installations:
              - name: "Default"
                home: "git"
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - vault:
                      id: "vault-token"
                      description: "Vault token for Jenkins"
                      path: "userpass"
                      username: "jenkins"
                      password: "jenkins-vault-password"  # Change this to match the password above
    EOT
  }

  depends_on = [module.jenkins]
}

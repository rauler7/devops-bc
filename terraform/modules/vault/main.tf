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
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = var.namespace
  version    = var.vault_chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "server.dev.enabled"
    value = var.dev_mode
  }

  set {
    name  = "server.standalone.enabled"
    value = var.standalone_mode
  }

  set {
    name  = "server.standalone.config"
    value = <<-EOT
      ui = true
      listener "tcp" {
        address = "[::]:8200"
        tls_disable = 1
      }
      storage "file" {
        path = "/vault/data"
      }
    EOT
  }
}

# Create a Kubernetes job to initialize Vault and create the microservice secret
resource "kubernetes_job" "vault_init" {
  metadata {
    name      = "vault-init"
    namespace = var.namespace
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          name  = "vault-init"
          image = "curlimages/curl:8.1.2"
          command = [
            "/bin/sh",
            "-c",
            <<-EOT
              # Wait for Vault to be ready
              until curl -s http://vault:8200/v1/sys/health; do
                echo "Waiting for Vault to be ready..."
                sleep 5
              done

              # Initialize Vault if not already initialized
              if ! curl -s http://vault:8200/v1/sys/init | grep -q "initialized"; then
                echo "Initializing Vault..."
                INIT_RESPONSE=$(curl -s -X PUT -d '{"secret_shares":1,"secret_threshold":1}' http://vault:8200/v1/sys/init)
                UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r '.keys[0]')
                ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r '.root_token')
                
                # Unseal Vault
                curl -s -X PUT -d "{\"key\":\"$UNSEAL_KEY\"}" http://vault:8200/v1/sys/unseal
                
                # Create microservice secret
                curl -s -X POST -H "X-Vault-Token: $ROOT_TOKEN" \
                  -d '{"data":{"secret":"microservice-secret-value"}}' \
                  http://vault:8200/v1/secret/data/microservice
              fi
            EOT
          ]
        }
        restart_policy = "OnFailure"
      }
    }
  }

  depends_on = [helm_release.vault]
}

# Create a service account for Jenkins to access Vault
resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = var.namespace
  }
}

# Create a role binding for the service account
resource "kubernetes_cluster_role_binding" "vault_auth" {
  metadata {
    name = "vault-auth-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = var.namespace
  }
} 
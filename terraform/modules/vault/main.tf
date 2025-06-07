terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
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

  depends_on = [kubernetes_namespace.vault]
} 
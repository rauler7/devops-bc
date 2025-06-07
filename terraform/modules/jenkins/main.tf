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

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = var.namespace
  version    = var.jenkins_chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.serviceType"
    value = var.service_type
  }

  set {
    name  = "controller.ingress.enabled"
    value = var.ingress_enabled
  }
} 
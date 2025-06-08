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
  timeout    = 900 # 15 minutes timeout
  wait       = true
  wait_for_jobs = true

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

  set {
    name  = "controller.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.installPlugins[0]"
    value = "kubernetes:1.31.3"
  }

  set {
    name  = "controller.installPlugins[1]"
    value = "workflow-aggregator:2.6"
  }

  set {
    name  = "controller.installPlugins[2]"
    value = "git:4.11.0"
  }

  set {
    name  = "controller.installPlugins[3]"
    value = "configuration-as-code:1.55"
  }

  set {
    name  = "controller.installPlugins[4]"
    value = "blueocean:1.25.3"
  }
} 
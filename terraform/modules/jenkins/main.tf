terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = var.namespace
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
    value = "kubernetes"
  }

  set {
    name  = "controller.installPlugins[1]"
    value = "workflow-aggregator"
  }

  set {
    name  = "controller.installPlugins[2]"
    value = "git"
  }

  set {
    name  = "controller.installPlugins[3]"
    value = "configuration-as-code"
  }

  set {
    name  = "controller.installPlugins[4]"
    value = "blueocean"
  }

  set {
    name  = "controller.installPlugins[5]"
    value = "hashicorp-vault-plugin"
  }

  set {
    name  = "controller.installPlugins[6]"
    value = "docker-workflow"
  }

  set {
    name  = "controller.installPlugins[7]"
    value = "pipeline-model-definition"
  }
  
  set {
    name  = "controller.installLatestSpecifiedPlugins"
    value = true
  }
} 

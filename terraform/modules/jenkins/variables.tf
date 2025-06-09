variable "namespace" {
  description = "Kubernetes namespace to deploy Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Optional chart version for Jenkins Helm release"
  type        = string
  default     = null
}

variable "service_type" {
  description = "Kubernetes service type for Jenkins"
  type        = string
  default     = "ClusterIP"
}

variable "ingress_enabled" {
  description = "Enable ingress for Jenkins"
  type        = bool
  default     = false
} 
variable "namespace" {
  description = "Kubernetes namespace to deploy Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Version of the Jenkins Helm chart"
  type        = string
  default     = "4.7.1"
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
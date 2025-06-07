variable "namespace" {
  description = "Kubernetes namespace to deploy Vault"
  type        = string
  default     = "vault"
}

variable "vault_chart_version" {
  description = "Version of the Vault Helm chart"
  type        = string
  default     = "0.27.0"
}

variable "dev_mode" {
  description = "Enable Vault dev mode"
  type        = bool
  default     = true
}

variable "standalone_mode" {
  description = "Enable Vault standalone mode"
  type        = bool
  default     = true
} 
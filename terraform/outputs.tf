output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "devops_cluster_name" {
  description = "The name of the DevOps AKS cluster"
  value       = azurerm_kubernetes_cluster.devops.name
}

output "dev_cluster_name" {
  description = "The name of the Development AKS cluster"
  value       = azurerm_kubernetes_cluster.dev.name
}

output "devops_cluster_kubeconfig" {
  description = "The kubeconfig for the DevOps cluster"
  value       = azurerm_kubernetes_cluster.devops.kube_config_raw
  sensitive   = true
}

output "dev_cluster_kubeconfig" {
  description = "The kubeconfig for the Development cluster"
  value       = azurerm_kubernetes_cluster.dev.kube_config_raw
  sensitive   = true
} 
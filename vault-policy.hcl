path "kubeconfig/data/*" {
  capabilities = ["read", "list"]
}

path "secret/data/*" {
  capabilities = ["read", "list"]
} 
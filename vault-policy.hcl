    path "secret/data/jenkins/*" {
      capabilities = ["read", "list"]
    }

    path "kubeconfig/data/*" {
      capabilities = ["read", "list"]
    }

    # Grant read access to the specific kubeconfig path
    path "kubeconfig/data/development/kubeconfig" {
      capabilities = ["read"]
    }

    # Grant read access to the microservice secrets path
    path "secret/data/microservice/*" {
      capabilities = ["read", "list"]
    }

    # Allow listing and reading secrets in the microservice path
    path "secret/data/microservice" {
      capabilities = ["read", "list"]
    }
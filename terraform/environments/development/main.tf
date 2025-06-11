terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

# Create the development cluster
resource "kind_cluster" "development" {
  name = "development-cluster"
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"",
        "kind: ClusterConfiguration\napiServer:\n  certSANs:\n  - localhost\n  - 127.0.0.1\n  - 0.0.0.0\n  - 10.96.0.1\n  - 172.18.0.4",
        "kind: KubeletConfiguration\ncgroupDriver: systemd"
      ]
      extra_port_mappings {
        container_port = 6443
        host_port      = 42675
        protocol       = "TCP"
        listen_address = "127.0.0.1"
      }
      extra_port_mappings {
        container_port = 80
        host_port      = 8081
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8444
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }

  wait_for_ready = true
}

# Configure providers to use the development cluster
provider "kubernetes" {
  host                   = "https://127.0.0.1:42675"
  config_path            = kind_cluster.development.kubeconfig_path
  insecure               = true
}

provider "helm" {
  kubernetes {
    host                   = "https://127.0.0.1:42675"
    config_path            = kind_cluster.development.kubeconfig_path
    insecure               = true
  }
}

provider "kubectl" {
  host                   = "https://127.0.0.1:42675"
  config_path            = kind_cluster.development.kubeconfig_path
  insecure               = true
}

# Create namespace for the microservice
resource "kubernetes_namespace" "microservice" {
  metadata {
    name = "microservice"
  }
  depends_on = [kind_cluster.development]
}

# Create namespace for NGINX Ingress Controller
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
  depends_on = [kind_cluster.development]
}

# Deploy NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = "4.9.0"
  timeout    = 600 # 10 minutes timeout

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.nodePorts.http"
    value = "30080"
  }

  set {
    name  = "controller.service.nodePorts.https"
    value = "30443"
  }

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  depends_on = [kind_cluster.development, kubernetes_namespace.ingress_nginx]
}

# Deploy the audit CronJob
resource "kubernetes_cron_job_v1" "kubelet_audit" {
  metadata {
    name      = "kubelet-audit"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    schedule = "*/10 * * * *"

    job_template {
      metadata {
        name = "kubelet-audit-job"
      }

      spec {
        template {
          metadata {
            name = "kubelet-audit-pod"
          }

          spec {
            container {
              name    = "audit"
              image   = "bitnami/kubectl:latest"
              command = ["/bin/bash", "-c", <<-EOT
                kubectl get events --field-selector source=kubelet --sort-by='.lastTimestamp' | \
                grep -E "Failed|Error|CrashLoopBackOff|ImagePullBackOff" > /tmp/events.log
                
                if [ -s /tmp/events.log ]; then
                  echo "Critical events detected at $(date)" >> /tmp/events.log
                fi
              EOT
              ]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "microservice1" {
  metadata {
    name      = "microservice1"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "microservice1"
      }
    }

    template {
      metadata {
        labels = {
          app = "microservice1"
        }
      }

      spec {
        container {
          image = "microservice:latest"  # This will be built by Jenkins
          name  = "microservice1"

          port {
            container_port = 8080
          }

          env {
            name  = "ENV_VARIABLE"
            value = "This is an environment variable"
          }

          env {
            name  = "CONFIG_PATH"
            value = "/app/config"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/app/config"
          }
        }

        volume {
          name = "config-volume"
          config_map {
            name = "microservice-config"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.microservice]
}

resource "kubernetes_config_map" "microservice_config" {
  metadata {
    name      = "microservice-config"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  data = {
    "config.json" = jsonencode({
      "setting1" = "value1"
      "setting2" = "value2"
    })
  }
}

resource "kubernetes_service" "microservice1" {
  metadata {
    name      = "microservice1"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    selector = {
      app = "microservice1"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.microservice1]
}

resource "kubernetes_ingress_v1" "microservice" {
  metadata {
    name      = "microservice-ingress"
    namespace = kubernetes_namespace.microservice.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.microservice1.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.microservice1, helm_release.nginx_ingress]
}

resource "local_file" "install_cloud_provider" {
  filename = "${path.module}/install-cloud-provider.sh"
  content  = <<-EOT
    #!/bin/bash
    go install sigs.k8s.io/cloud-provider-kind@latest
    cloud-provider-kind &
  EOT
}

resource "local_file" "verify_loadbalancer" {
  filename = "${path.module}/verify-loadbalancer.sh"
  content  = <<-EOT
    #!/bin/bash
    LB_IP=$$(kubectl get svc/foo-service -n microservice -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    for i in {1..5}; do
      echo "Request $i:"
      curl "$${LB_IP}:5678"
      echo -e "\\n"
      sleep 1
    done
  EOT
}

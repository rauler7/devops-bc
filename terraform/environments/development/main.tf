terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2.1"
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
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\""
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

provider "kubernetes" {
  config_path = kind_cluster.development.kubeconfig_path
}

# Create namespace for the microservice
resource "kubernetes_namespace" "microservice" {
  metadata {
    name = "microservice"
  }
  depends_on = [kind_cluster.development]
}

# Create ConfigMap for microservice configuration
resource "kubernetes_config_map" "microservice_config" {
  metadata {
    name      = "microservice-config"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  data = {
    "application.properties" = <<-EOT
      app.name=Microservice Demo
      app.version=1.0.0
      app.description=Java 17 Microservice Demo
    EOT
  }

  depends_on = [kubernetes_namespace.microservice]
}

# Create deployment for the microservice
resource "kubernetes_deployment" "microservice" {
  metadata {
    name      = "microservice"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "microservice"
      }
    }

    template {
      metadata {
        labels = {
          app = "microservice"
        }
      }

      spec {
        container {
          image = "localhost:5000/microservice:latest"
          name  = "microservice"

          port {
            container_port = 8080
          }

          env {
            name  = "APP_CONFIG_PATH"
            value = "/app/config/application.properties"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/app/config"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds       = 10
          }

          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds       = 5
          }
        }

        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.microservice_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_config_map.microservice_config]
}

# Create service for the microservice
resource "kubernetes_service" "microservice" {
  metadata {
    name      = "microservice"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    selector = {
      app = "microservice"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.microservice]
}

# Create secret for the microservice
resource "kubernetes_secret" "microservice_secret" {
  metadata {
    name      = "microservice-secret"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  data = {
    app-secret = "development-secret-value"
  }
}

# Deploy the audit CronJob
resource "kubernetes_cron_job" "kubelet_audit" {
  metadata {
    name      = "kubelet-audit"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    schedule = "*/10 * * * *"

    job_template {
      metadata {}

      spec {
        template {
          metadata {}

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

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.microservice.metadata[0].name
  version    = "4.7.1"

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

  depends_on = [kind_cluster.development]
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
          image = "nginx:latest"
          name  = "microservice1"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kind_cluster.development]
}

resource "kubernetes_deployment" "microservice2" {
  metadata {
    name      = "microservice2"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "microservice2"
      }
    }

    template {
      metadata {
        labels = {
          app = "microservice2"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "microservice2"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kind_cluster.development]
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
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.microservice1]
}

resource "kubernetes_service" "microservice2" {
  metadata {
    name      = "microservice2"
    namespace = kubernetes_namespace.microservice.metadata[0].name
  }

  spec {
    selector = {
      app = "microservice2"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.microservice2]
}

resource "kubernetes_ingress_v1" "microservices" {
  metadata {
    name      = "microservices-ingress"
    namespace = kubernetes_namespace.microservice.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "microservice1.local"
      http {
        path {
          path      = "/"
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

    rule {
      host = "microservice2.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.microservice2.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.nginx_ingress]
} 
resource "kubernetes_deployment" "registry" {
  metadata {
    name      = "registry"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "registry"
        }
      }

      spec {
        container {
          image = "registry:2"
          name  = "registry"

          port {
            container_port = 5000
          }

          volume_mount {
            name       = "registry-data"
            mount_path = "/var/lib/registry"
          }
        }

        volume {
          name = "registry-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = "registry"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "registry"
    }

    port {
      port        = 5000
      target_port = 5000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "registry" {
  metadata {
    name      = "registry-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
} 
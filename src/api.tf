resource "kubernetes_deployment" "api" {
  metadata {
    name = "api"
    labels = {
      test = "api"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "api"
      }
    }

    template {
      metadata {
        labels = {
          test = "api"
        }
      }

      spec {
        container {
          image = "lnwu/todo-api-go"
          name  = "api"
          env {
            name  = "DB_PASSWORD"
            value = "password"
          }
          env {
            name  = "DB_HOST"
            value = "${kubernetes_service.db.spec.0.cluster_ip}:5432"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name = "api"
  }
  spec {
    selector = "${kubernetes_deployment.api.metadata.0.labels}"
    port {
      port        = 80
      target_port = 8080
    }
  }
}

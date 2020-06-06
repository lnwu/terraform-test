resource "kubernetes_deployment" "db" {
  metadata {
    name = "db"
    labels = {
      test = "db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "db"
      }
    }

    template {
      metadata {
        labels = {
          test = "db"
        }
      }

      spec {
        container {
          image = "postgres:latest"
          name  = "db"
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "db" {
  metadata {
    name = "db"
  }
  spec {
    selector = "${kubernetes_deployment.db.metadata.0.labels}"
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

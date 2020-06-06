resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      test = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          test = "nginx"
        }
      }

      spec {
        volume {
          name = "nginx-conf"
          config_map {
            name = "nginx-config"
          }
        }

        container {
          image = "nginx:latest"
          name  = "nginx"

          env {
            name  = "API_HOST"
            value = "${kubernetes_service.api.spec.0.cluster_ip}"
          }

          volume_mount {
            name       = "nginx-conf"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
            read_only  = true
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "test-app" {
  metadata {
    name = "test-app"
  }
  spec {
    selector = "${kubernetes_deployment.nginx.metadata.0.labels}"
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_config_map" "nginx-config" {
  metadata {
    name = "nginx-config"
  }

  data = {
    "nginx.conf" = "${file("${path.module}/nginx.conf")}"
  }
}


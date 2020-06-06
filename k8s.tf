provider "tencentcloud" {}


variable "availability_zone" {
  default = "ap-guangzhou-3"
}

resource "tencentcloud_vpc" "test-vpc" {
  name       = "测试VPC"
  cidr_block = "10.0.0.0/16"
}

resource "tencentcloud_subnet" "test-vpv-subnet" {
  name              = "测试VPC子网"
  availability_zone = "${var.availability_zone}"
  vpc_id            = "${tencentcloud_vpc.test-vpc.id}"
  cidr_block        = "10.0.0.0/28"
}

resource "tencentcloud_kubernetes_cluster" "test_cluster" {
  cluster_name            = "测试集群"
  vpc_id                  = "${tencentcloud_vpc.test-vpc.id}"
  cluster_cidr            = "192.168.0.0/16"
  cluster_max_pod_num     = 32
  cluster_max_service_num = 128
  cluster_deploy_type     = "MANAGED_CLUSTER"
  cluster_internet        = true

  worker_config {
    count                      = 1
    availability_zone          = "${var.availability_zone}"
    instance_type              = "SA2.SMALL1"
    system_disk_type           = "CLOUD_SSD"
    system_disk_size           = 50
    internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
    internet_max_bandwidth_out = 1
    public_ip_assigned         = true
    subnet_id                  = "${tencentcloud_subnet.test-vpv-subnet.id}"
    password                   = "test123123"
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = "${tencentcloud_kubernetes_cluster.test_cluster.cluster_external_endpoint}"
  username               = "${tencentcloud_kubernetes_cluster.test_cluster.user_name}"
  password               = "${tencentcloud_kubernetes_cluster.test_cluster.password}"
  cluster_ca_certificate = "${tencentcloud_kubernetes_cluster.test_cluster.certification_authority}"
}

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

output "lb_id" {
  value = "${kubernetes_service.test-app.load_balancer_ingress.0.ip}"
}

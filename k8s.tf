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
        container {
          image = "nginx:latest"
          name  = "nginx"
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

output "lb_id" {
  value = "${kubernetes_service.test-app.load_balancer_ingress.0.ip}"
}

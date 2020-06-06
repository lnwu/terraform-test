provider "tencentcloud" {}

variable "availability_zone" {
  default = "ap-guangzhou-3"
}

resource "tencentcloud_vpc" "biancheng101-vpc" {
  name       = "测试VPC"
  cidr_block = "10.0.0.0/16"
}

resource "tencentcloud_subnet" "biancheng101-vpv-subnet" {
  name              = "测试VPC子网"
  availability_zone = var.availability_zone
  vpc_id            = tencentcloud_vpc.biancheng101-vpc.id
  cidr_block        = "10.0.0.0/28"
}

resource "tencentcloud_kubernetes_cluster" "biancheng101_cluster" {
  cluster_name            = "测试集群"
  vpc_id                  = tencentcloud_vpc.biancheng101-vpc.id
  cluster_cidr            = "192.168.0.0/16"
  cluster_max_pod_num     = 32
  cluster_max_service_num = 128
  cluster_deploy_type     = "MANAGED_CLUSTER"
  worker_config {
    count                      = 1
    availability_zone          = var.availability_zone
    instance_type              = "SA2.SMALL1"
    system_disk_type           = "CLOUD_SSD"
    system_disk_size           = 50
    internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
    internet_max_bandwidth_out = 1
    public_ip_assigned         = true
    subnet_id                  = tencentcloud_subnet.biancheng101-vpv-subnet.id
    use_data                   = "dGVzdA=="
    password                   = "test123"
  }
}

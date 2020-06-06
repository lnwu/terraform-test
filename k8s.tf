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

resource "tencentcloud_key_pair" "ssh" {
  key_name   = "biancheng101"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZYS+Slmx/pp04Abbk4BtHzULeuQQbhbj+tnlNQ2EWat+yJpF1s/LlRupl0hmHV/N2e9dYqzH/AM08sRSI/U+mBCZ9ieBZRwO7IvIBwTjFDkeQLKlwwH2NY4je0YENIDbZYVV7gkaz5zmQYjtx5EGEMWPIZalxJgyjBbXTRNAY5j8JgntnPkmZwnKb75UxmUd+USl0fdXVObPZFY8ZjGv14hVjP+IFrWUWONv9AlA5Lxs1f90s0VI3vGYmMfbEbvNkZvG+nSfpYYyrTBRdSiSxM85g7fGa5FGp47NpMYhVJuYRyZbUGuSOCPPKtsHHbaOpDgG0PsEnwS06FD6MSSoUtFnBpEnS1wSLcf2bdxd2Y99Sk+82P3rpAf1pk78LqPyrAZC4D5FRxoOPo01Gd2Zx3Dc2GV0QZG3tFUX04oubbNXQZS6fMrZ8m1kfXkgKZoZFO3n36q78DVwtWkzDl/5b0nAx8w4vfGJUYxNClkwDnmo/gVENc+Rt+KeEaqWUdcnFRU1q9BoeyvWKskDj0zTABF5eZ4LWtunJ32PE9oDeLrQ4QBjGpGWFdJv1UXGGwoylxOLctdKuJEJtDFjHvKab99C6lgZ/I/bT1otF+mel2jale9ZoaH+jHwxXY2nhbIFjxX93rx4WW3zkvn9ldfaPYro8chbRE1b0ljSttorOxQ== windows@email.com"
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
    key_ids                    = [tencentcloud_key_pair.ssh.id]
  }
}

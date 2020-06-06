# provider "docker" {}


# variable "db_password" {
#   default = "password"
# }

# resource "docker_container" "pg" {
#   image = "${docker_image.pg.latest}"
#   name  = "pg"
#   env   = ["POSTGRES_PASSWORD=${var.db_password}"]
#   ports {
#     internal = 5432
#     external = 5432
#   }
# }
# resource "docker_image" "pg" {
#   name = "postgres:latest"
# }

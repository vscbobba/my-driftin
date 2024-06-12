variable "region" {}

variable "key_infra" {}

variable "bucket" {}

variable "key_platform" {}

variable "jump_type" {}

variable "jenkins_type" {}

variable "jump_ami" {}

variable "ci_type" {}

variable "jenkins_dns" {}

variable "prometheus_dns" {}

variable "zone_id" {}

variable "amazon_linux_2023" {}

variable "project_name" {
  default = "firelens"
}

variable "service" {
  default = "ecs-service"
}
variable "env" {
  default = "dev"
}
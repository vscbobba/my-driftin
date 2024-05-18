provider "aws" {
  region = "ap-south-1"
}

terraform{
 backend "s3"{
 }
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    region = var.region
    bucket = var.bucket
    key    = var.key_infra
    encrypt = true
  }
}
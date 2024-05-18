provider "aws" {
  region = "ap-south-1"
}

terraform{
 backend "s3"{
 }
}
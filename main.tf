terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.23.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
  }
}

locals {
  namespace = join("-", split(" ", lower(var.basename)))
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###########
# General #
###########

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#######
# AWS #
#######

provider "aws" {
  region  = var.aws_region
  profile = "sandbox"
  default_tags {
    tags = {
      project = "wiz-interview"
    }
  }
}

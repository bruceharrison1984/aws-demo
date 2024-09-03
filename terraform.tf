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
  region = "us-east-1"

  default_tags {
    tags = {
      project = "wiz-interview"
    }
  }
}

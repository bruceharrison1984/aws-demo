###########
# General #
###########

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#######
# AWS #
#######

provider "aws" {
  region = var.aws_region
}

module "aws" {
  source = "./modules/aws"

  additional_subnet_types = var.additional_subnet_types
  s3_buckets              = var.s3_buckets
  ssm-role-suffix         = var.ssm-role-suffix
  aws_region              = var.aws_region
}

// Upload the license file so it's available to be ingested by TFE installations you provision within the account

resource "aws_s3_object" "license" {
  bucket         = module.aws.s3_buckets[var.license_bucket]
  key            = "hashicorp-support.rli"
  content_base64 = filebase64("./assets/hashicorp-internal---support.rli")
}

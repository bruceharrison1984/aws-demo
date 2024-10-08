data "aws_default_tags" "current" {}

resource "random_string" "main" {
  length  = 4
  special = false
  numeric = false
  upper   = false
}

locals {
  base_name = "wiz-demo-${random_string.main.result}"
}

module "vpc" {
  source = "./modules/vpc"

  name      = local.base_name
  root_cidr = "10.1.0.0/16"
}

module "eks" {
  source = "./modules/eks"

  name                    = local.base_name
  vpc_id                  = module.vpc.vpc_id
  subnets                 = module.vpc.private_subnets
  mongo_connection_string = "mongodb://${random_string.username.result}:${random_string.password.result}@${aws_route53_record.mongo.name}/go-mongodb"
}

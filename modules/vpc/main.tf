data "aws_default_tags" "current" {}

####### 
# VPC #  
#######

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  // This is an easy way to make sure that we have all of the required subnet types, but allow for adding more options
  // via the `additional_subnet_types` variable.
  subnet_types = ["public", "private", "db"]

  // This creates a list of the first three AZs that are found to be available in the region that is configured to be deployed into. If there are less than 3 AZs available, all of the available AZs will be selected by default
  first_three_azs = slice(data.aws_availability_zones.available.names, 0, min(2, length(data.aws_availability_zones.available.names)))

  // This allows us to create an exhaustive list of combinations of availability zones to subnet types so that we can
  // create a subnet of each type in each availability zone.
  subnets = [for subnet in setproduct(local.first_three_azs, local.subnet_types) : join("_", subnet)]
}

module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = var.root_cidr
  networks = [for subnet in local.subnets : {
    name     = subnet
    new_bits = 8 # this will give us /20s as the root cidr is a /16
  }]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "${var.name}-vpc"
  cidr = var.root_cidr

  azs              = local.first_three_azs
  public_subnets   = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "public"]
  private_subnets  = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "private"]
  database_subnets = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "db"]

  public_subnet_tags   = { Type = "public", "kubernetes.io/role/elb" = 1 }
  private_subnet_tags  = { Type = "private", "kubernetes.io/role/internal-elb" = 1 }
  database_subnet_tags = { Type = "db" }

  create_database_subnet_group = true
  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_nat_gateway           = true
}

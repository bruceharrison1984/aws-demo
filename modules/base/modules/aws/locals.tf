data "aws_default_tags" "current" {}



locals {

  // This is an easy way to make sure that we have all of the required subnet types, but allow for adding more options
  // via the `additional_subnet_types` variable.
  subnet_types = concat(var.additional_subnet_types, ["public", "private", "db"])

  // This creates a list of the first three AZs that are found to be available in the region that is configured to be deployed into. If there are less than 3 AZs available, all of the available AZs will be selected by default
  first_three_azs = slice(data.aws_availability_zones.available.names, 0, min(3, length(data.aws_availability_zones.available.names)))

  // This allows us to create an exhaustive list of combinations of availability zones to subnet types so that we can
  // create a subnet of each type in each availability zone.
  subnets = [for subnet in setproduct(local.first_three_azs, local.subnet_types) : join("_", subnet)]

  // Each of these blocks allows us to tag resources as private, public, etc.
  public_tags = merge({
    Type = "public"
    },
    local.common_tags
  )

  private_tags = merge({
    Type = "private"
    },
    local.common_tags
  )

  database_tags = merge({
    Usage = "database"
    },
    local.common_tags
  )

  elasticache_tags = merge({
    Usage = "elasticache"
    },
    local.common_tags
  )

  // This allows us to tag all resources with a common set of tags. There are three tags by default, but more may be
  // passed via the `common_tags` variable.
  common_tags = merge({
    Terraform  = true
    Department = "rts"
    Purpose    = "tfe-base-infrastructure"
    },
    var.common_tags
  )

  // At this time, all infra should be under the default domain of your individual sandbox account in AWS, so we create a subdomain of this
  // using the `local.user_name` variable.
  dns_zone = "${local.user_name}.sbx.hashidemos.io"

}

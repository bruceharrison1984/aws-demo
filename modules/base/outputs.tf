#######
# AWS #
#######

output "iam_instance_profile_role_name" {
  description = "The SSM-configured instance profile role name."
  value       = module.aws.ssm.iam_role.name
}

output "vpc" {
  description = "The entire output of the VPC module from the base infrastructure module."
  value       = module.aws.vpc
}

output "aws_region" {
  description = "The region that was configured to be deployed into."
  value       = var.aws_region
}

output "zone_name" {
  description = "The DNS zone name that was created in the base infrastructure."
  value       = module.aws.zone_name
}

output "route53_zone_nameservers" {
  description = "The nameservers for the DNS zone that was created."
  value       = module.aws.route53_zone_ns
}

output "airgap_packages_bucket" {
  description = "The bucket where airgap packages are stored."
  value       = module.aws.s3_buckets[var.airgap_packages]
}

output "license_file" {
  description = "Direct link where the license file is stored in S3."
  value       = "s3://${aws_s3_object.license.bucket}/${aws_s3_object.license.id}"
}

output "tfe_bootstrap_bucket" {
  description = "The information about where the license file is stored in S3."
  value = {
    bucket      = aws_s3_object.license.bucket
    license_key = aws_s3_object.license.id
  }
}

output "acm_wildcard_arn" {
  description = "The ARN for the ACM wildcard certificate that is created."
  value       = module.aws.acm_wildcard_arn
}

// This was intended to make it easier to reference the things we needed, but I've not gotten around to actually
// implementing it in any of our examples or anything like that. Might be worth exploring.
output "tfe_settings" {
  description = "A map of all of the values needed to use the TFE module with no additional configuration"
  value = {
    license_file                   = "s3://${aws_s3_object.license.bucket}/${aws_s3_object.license.id}"
    airgap_packages_bucket         = module.aws.s3_buckets[var.airgap_packages]
    iam_instance_profile_role_name = module.aws.ssm.iam_role.name
    zone_name                      = module.aws.zone_name
    vpc_id                         = module.aws.vpc.vpc_id
    private_subnets                = module.aws.vpc.private_subnets
    private_subnets_cidr_blocks    = module.aws.vpc.private_subnets_cidr_blocks
    public_subnets                 = module.aws.vpc.public_subnets
    public_subnets_cidr_blocks     = module.aws.vpc.public_subnets_cidr_blocks
    database_subnet_group          = module.aws.vpc.database_subnet_group
    elasticache_subnet_group       = module.aws.vpc.elasticache_subnet_group
  }
}

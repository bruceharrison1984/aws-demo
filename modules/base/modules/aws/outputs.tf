output "vpc" {
  value = module.vpc
}

output "ssm" {
  value = {
    iam_instance_profile = aws_iam_instance_profile.ssm
    iam_role             = aws_iam_role.ssm
    security_group       = aws_security_group.ssm
  }
}

output "rds" {
  value = module.rds
}

output "s3_buckets" {
  value = { for b in var.s3_buckets : b => aws_s3_bucket.main[b].id }
}

# Placeholder for when we manage DNS via Terraform

output "zone_name" {
  value = local.dns_zone
}

output "route53_zone_ns" {
  value = data.aws_route53_zone.dns_zone.name_servers
}

output "acm_wildcard_arn" {
  description = "The ARN for the ACM wildcard certificate."
  value = module.acm_wildcard.acm_certificate_arn
}

output "user_name" {
  value = local.user_name
}

output "user_email" {
  value = local.user_email
}

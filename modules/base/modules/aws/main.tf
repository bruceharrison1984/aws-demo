########
# Tags # 
########

variable "tags" {
  description = "(Optional) Any custom tags that should be added to all of the resources."
  type        = map(string)
  default     = {}
}

// get the current user information so that we may tag the resources with the user's email, and utilize the value to the left of @ for using the default dns zone that 
//exists within our sandbox accounts
data "aws_caller_identity" "user" {}

locals {

  // user_email is the users email address as gathered from the aws_caller_identity data source
  // the email is prefixed with a string of text followed by a semicolon, so we want to strip that away
  // we also want to convert an dots found within a user's username to dashes so that it can be used as a name for other resources
  user_name_raw = regex(":(.*?)@", data.aws_caller_identity.user.user_id)
  user_name = replace(local.user_name_raw[0],".", "-")
  user_email = replace(data.aws_caller_identity.user.user_id, "/^.*:/", "")

  tags = merge({
    Name    = local.user_name
    OwnedBy = local.user_email
  }, var.tags)
}

#######
# DNS #
#######

data "aws_route53_zone" "dns_zone" {
  name = local.dns_zone
}

module "acm_wildcard" {
  source  = "terraform-aws-modules/acm/aws"
  version = "3.0.0"

  domain_name         = local.dns_zone
  zone_id             = data.aws_route53_zone.dns_zone.zone_id
  wait_for_validation = false # until we swing over the main registrar for this zone, this will not pass
  tags                = local.common_tags

  subject_alternative_names = [
    "*.${local.dns_zone}"
  ]
}

resource "aws_acm_certificate" "acm_wildcard_no_san" {
  domain_name       = "*.${local.dns_zone}"
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_wildcard_no_san" {
  allow_overwrite = true
  name            = [for value in aws_acm_certificate.acm_wildcard_no_san.domain_validation_options[*].resource_record_name : value][0]
  records         = [[for value in aws_acm_certificate.acm_wildcard_no_san.domain_validation_options[*].resource_record_value : value][0]]
  ttl             = 60
  type            = [for value in aws_acm_certificate.acm_wildcard_no_san.domain_validation_options[*].resource_record_type : value][0]
  zone_id         = data.aws_route53_zone.dns_zone.zone_id
}

#######
# IAM #
#######

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ssm" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "${local.user_name}-ssm-${var.aws_region}"
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm.name
}

resource "aws_iam_role_policy_attachment" "cloud_watch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ssm.name
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.user_name}-ssm-${var.aws_region}"
  role = aws_iam_role.ssm.name
}

#######
# RDS #
#######

module "rds" {
  source      = "terraform-aws-modules/rds/aws//modules/db_subnet_group"
  version     = "2.34.0"
  description = "Database subnet group for ${local.user_name}"
  name        = local.user_name
  subnet_ids  = module.vpc.database_subnets
  tags        = merge(local.common_tags, tomap({ "Usage" = "rds" }))
}

######
# S3 #
######

# We'll need the curren accound ID to make sure the root user can do things
# to the KMS key
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description = "This key is used to encrypt bucket objects"
  policy      = data.aws_iam_policy_document.kms.json
  tags        = local.common_tags
}

data "aws_iam_policy_document" "kms" {
  policy_id = "AllowDecryptionFromSSMRole"

  statement {
    sid = "EnableIAMUserPermissions"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
    }
  }

  statement {
    sid = "AllowDecryptionFromSSMRole"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ssm.arn]
    }
  }
}

# TODO: Make sure bucket objects cannot be public
resource "aws_s3_bucket" "main" {
  for_each = toset(var.s3_buckets)
  bucket   = "${local.user_name}-${each.key}-${var.aws_region}"
  tags     = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.main[each.key].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "main" {
  for_each  = toset(var.s3_buckets)
  policy_id = "AllowOnlyFromVPCE"
  statement {
    sid = "VPCEAllow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.main[each.key].arn,
      "${aws_s3_bucket.main[each.key].arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = [
        module.vpc.vpc_endpoint_s3_id
      ]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.main[each.key].id
  policy   = data.aws_iam_policy_document.main[each.key].json
}

#######
# VPC #
#######

data "aws_availability_zones" "available" {
    state = "available"
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
  version = "2.78.0"

  name = "${local.user_name}-tfe-vpc"
  cidr = var.root_cidr
  tags = local.common_tags

  azs                     = local.first_three_azs
  public_subnets          = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "public"]
  private_subnets         = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "private"]
  database_subnets        = [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "db"]
  elasticache_subnets     = contains(var.additional_subnet_types, "elasticache") ? [for network in module.subnet_addrs.networks : network["cidr_block"] if split("_", network["name"])[1] == "elasticache"] : []
  public_subnet_tags      = local.public_tags
  private_subnet_tags     = local.private_tags
  database_subnet_tags    = local.database_tags
  elasticache_subnet_tags = local.elasticache_tags

  create_database_subnet_group            = true
  enable_dns_hostnames                    = true
  enable_dns_support                      = true
  enable_ec2messages_endpoint             = true
  enable_nat_gateway                      = true
  enable_s3_endpoint                      = true
  enable_ssm_endpoint                     = true
  enable_ssmmessages_endpoint             = true
  ssm_endpoint_private_dns_enabled        = true
  ec2messages_endpoint_security_group_ids = [aws_security_group.ssm.id]
  ssm_endpoint_security_group_ids         = [aws_security_group.ssm.id]
  ssmmessages_endpoint_security_group_ids = [aws_security_group.ssm.id]
}

resource "aws_security_group" "ssm" {
  description = "The security group of Systems Manager."
  name        = "${local.user_name}-ssm"
  tags        = local.common_tags
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    protocol  = "tcp"
    to_port   = 443

    cidr_blocks = concat(module.vpc.private_subnets_cidr_blocks, module.vpc.public_subnets_cidr_blocks)
    description = "Allow the ingress of HTTPS traffic from all private subnets."
  }
}

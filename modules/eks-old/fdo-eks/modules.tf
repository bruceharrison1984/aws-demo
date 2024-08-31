module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.16.0"

  cluster_name    = "${random_pet.name.id}-cluster"
  cluster_version = var.kubernetes_version
  cluster_addons = {
    amazon-cloudwatch-observability = {
      addon_version = "v1.7.0-eksbuild.1"
      ## custom config to split TFE logs into well-named streams in Cloudwatch
      configuration_values = file("${path.module}/fluent-bit-config.yaml")
    }
  }

  authentication_mode = "API_AND_CONFIG_MAP"

  ## NOTE: 
  ##  This module is moving towards granular `access_entries` for permissions
  ##  The current method of using `enable_cluster_creator_admin_permissions` may not work in future versions
  enable_cluster_creator_admin_permissions = true

  vpc_id                         = local.base-infra.vpc.vpc_id
  subnet_ids                     = local.base-infra.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name           = "${random_pet.name.id}"
      instance_types = var.instance_type
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_count
      iam_role_additional_policies = {
        ## Allow nodes to write to cloudwatch via the amazon-cloudwatch-observability addon
        ## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
    }
  }

  tags = local.tags
}

module "object_storage" {
  source = "./modules/object_storage"

  tags          = local.tags
  iam_role_name = aws_iam_role.tfe_service_account.name
  prefix        = random_pet.name.id
}

module "postgresql" {
  source                = "./modules/postgresql"
  engine_version        = var.postgresql_version
  db_instance_size      = var.db_instance_size
  db_port               = var.db_port
  prefix                = random_pet.name.id
  tags                  = local.tags
  vpc_id                = local.base-infra.vpc.vpc_id
  database_subnet_group = local.base-infra.vpc.database_subnet_group
  cidr_blocks           = local.base-infra.vpc.private_subnets_cidr_blocks
}

module "redis" {
  source                  = "./modules/redis"
  prefix                  = random_pet.name.id
  subnet_group_name       = local.base-infra.vpc.elasticache_subnet_group
  redis_use_password_auth = var.redis_use_password_auth
  redis_port              = var.redis_port
  vpc_id                  = local.base-infra.vpc.vpc_id
  security_groups         = [module.eks.node_security_group_id]
  tags                    = local.tags
}

module "tfe-fdo-kubernetes" {
  source                   = "./modules/tfe-fdo-kubernetes"
  docker_registry          = var.docker_registry
  docker_registry_username = var.docker_registry_username
  tag                      = var.tag
  image                    = var.image
  helm_chart_version       = var.helm_chart_version
  db_hostname              = module.postgresql.db_hostname
  db_name                  = module.postgresql.db_name
  db_password              = module.postgresql.db_password
  db_port                  = var.db_port
  db_user                  = module.postgresql.db_user
  kms_key_id               = module.object_storage.kms_key_id
  node_count               = var.node_count
  redis_host               = module.redis.redis_host
  redis_password           = module.redis.redis_password
  redis_port               = var.redis_port
  redis_use_auth           = var.redis_use_password_auth
  redis_use_tls            = var.redis_use_tls
  s3_bucket                = module.object_storage.s3_bucket
  s3_region                = var.region

  service_annotations = {
    "service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"         = data.aws_acm_certificate.zone.arn
    "service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol" = "ssl"
  }

  service_account_annotations = {
    ## assign IAM role to TFE service principal for S3 access
    "eks\\.amazonaws\\.com/role-arn" = aws_iam_role.tfe_service_account.arn
  }

  tfe_hostname = "${random_pet.name.id}.${var.zone_name}"
  tfe_license  = var.tfe_license
  tls_cert     = base64encode(tls_self_signed_cert.tfe.cert_pem)
  tls_ca_cert  = base64encode(tls_self_signed_cert.tfe.cert_pem)
  tls_cert_key = base64encode(tls_self_signed_cert.tfe.private_key_pem)
}

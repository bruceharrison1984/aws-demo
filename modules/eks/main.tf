
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.16.0"

  cluster_name    = "${var.name}-cluster"
  cluster_version = "1.29"
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

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name           = "${var.name}-group"
      instance_types = ["t3a.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      iam_role_additional_policies = {
        ## Allow nodes to write to cloudwatch via the amazon-cloudwatch-observability addon
        ## https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Observability-EKS-addon.html
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
    }
  }
}

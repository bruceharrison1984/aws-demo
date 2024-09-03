
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.16.0"

  cluster_name    = var.name
  cluster_version = "1.29"
  cluster_addons = {
    amazon-cloudwatch-observability = {
      addon_version = "v1.7.0-eksbuild.1"
    }
    coredns = {
      addon_version = "v1.11.1-eksbuild.11"
    }
    kube-proxy = {
      addon_version = "v1.29.7-eksbuild.2"
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      addon_version  = "v1.18.3-eksbuild.2"
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
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
      instance_types = ["t3a.medium"]
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

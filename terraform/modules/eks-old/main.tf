
# Pulls in data from the base-infra workspace

data "terraform_remote_state" "base-infra" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = var.base_infra_workspace_name
    }
  }
}


# Sets locals from base-infra                         

locals {
  base-infra = data.terraform_remote_state.base-infra.outputs
}

provider "aws" {
  region = local.base-infra.aws_region
}


# TFE AWS EKS FDO Module                              

module "terraform-enterprise-fdo" {
  source                    = "./fdo-eks"
  zone_name                 = local.base-infra.zone_name
  region                    = local.base-infra.aws_region
  tag                       = var.tfe_version
  tfc_organization          = var.tfc_organization
  base_infra_workspace_name = var.base_infra_workspace_name
}


# Outputs                                             

output "step_1_create_cred_file" {
  description = "Command used to set local AWS cred file that `kubectl` requires for permissions."
  value       = "doormat aws cred-file add-profile --set-default -a <AWS_ACCOUNT_NAME>"
}

output "step_2_update_kubectl" {
  description = "Command to use to set access to kubectl on local machine. This assumes [default] aws profile credentials are being used, otherwise append --profile <name_of_profile>."
  value       = "aws eks --region ${local.base-infra.aws_region} update-kubeconfig --name ${module.terraform-enterprise-fdo.cluster_name}"
}

output "step_3_get_pods" {
  description = "Command to get the pod name to use ."
  value       = "export POD=$(kubectl get pods -n terraform-enterprise -o jsonpath='{.items[*].metadata.name}')"
}

output "step_4_app_url_initial_admin_user" {
  description = "Command to create initial admin user token."
  value       = "export IACT=$(kubectl exec -t -n terraform-enterprise $POD -- bash -c \"/usr/local/bin/tfectl admin token\") && echo \"https://${module.terraform-enterprise-fdo.random_pet}.${local.base-infra.zone_name}/admin/account/new?token=$IACT\""
}

output "step_5_app_url" {
  description = "TFE app URL."
  value       = "https://${module.terraform-enterprise-fdo.random_pet}.${local.base-infra.zone_name}"
}

variable "tfe_version" {
  description = "The version of FDO to install. https://developer.hashicorp.com/terraform/enterprise/releases Example: v202309-1"
}

variable "base_infra_workspace_name" {
  description = "The name of the workspace that you deployed your base infrastructure resources through"
  type        = string

}

variable "tfc_organization" {
  description = "The name of the organization in TFC where the base infrastructure was deployed"
  type        = string
  default     = "team-rts"
}
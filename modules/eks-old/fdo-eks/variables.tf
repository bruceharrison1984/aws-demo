# General

variable "tags" {
  description = "Any custom tags that should be added to all of the resources."
  type        = map(string)
  default     = {}
}

variable "zone_name" {
  description = "The existing AWS Route53 zone to use. If using the base infrastructure, the value can be accessed via the `zone_name` output."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy the resources in."
  type        = string

}

variable "namespace" {
  type    = string
  default = "terraform-enterprise"
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


# EKS    

variable "instance_type" {
  description = "Instance type for the EKS managed node group"
  type        = list(string)
  default     = ["t3a.2xlarge"]
}

variable "kubernetes_version" {
  type = string
  # renovate: datasource=endoflife-date depName=amazon-eks versioning=loose
  default = "1.29"
}

variable "helm_chart_version" {
  type = string
  # renovate: helm: registryUrl=https://helm.releases.hashicorp.com depName=terraform-enterprise
  default = "1.1.1"
}


# Postgres

variable "postgresql_version" {
  type = string
  # renovate: datasource=endoflife-date depName=amazon-rds-postgresql versioning=loose
  default = "15.5"
}

variable "db_instance_size" {
  type    = string
  default = "db.t3.small"
}

variable "db_port" {
  type    = string
  default = "5432"
}


# Redis  

variable "redis_use_password_auth" {
  description = "(Optional) Whether or not to use password authentication when connecting to Redis."
  type        = bool
  default     = true
}

variable "redis_use_tls" {
  description = "(Optional) Whether or not to use TLS when connecting to Redis."
  type        = bool
  default     = true
}

variable "redis_port" {
  type    = string
  default = "6379"
}


# TFE Settings   

variable "node_count" {
  description = "(Optional) The number of pods when using active-active."
  type        = number
  default     = 1
}

variable "encryption_password" {
  type    = string
  default = "SUPERSECRET"
}


# Docker Registry  

variable "docker_registry" {
  type        = string
  default     = "images.releases.hashicorp.com"
  description = "Appending of /hashicorp needed to registry URL for Docker to succesfully pull image via Terraform."
}

variable "image" {
  type    = string
  default = "hashicorp/terraform-enterprise"
}

variable "tag" {
  type        = string
  description = "Currently no latest tag available and must be manually set on workspace creation."
  # renovate: datasource=docker depName=images.releases.hashicorp.com/hashicorp/terraform-enterprise registryUrl=https://images.releases.hashicorp.com versioning=loose
  default = "v202312-1"
}

variable "docker_registry_username" {
  type    = string
  default = "terraform"
}

variable "tfe_license" {
  type        = string
  default     = "02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVVE2MSZPJWGQTL2KF2FUR2FGRGUGMLIJZ5GQ2SMKRDGWTSHJF2E4VCGNVNEIUJRJZLVM3CZPJDGUSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJEZVU2SONRGTETJVJV4TA52ONJRTGTCXKJUFU3KFORNGUTTJJZBTANC2K5KTEWL2MRWVUR2ZGRNEIRLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SNORGUI23UJVCFUVKNKRRTMTLKIU3E2RCNOVGUIZZVJ5KE2NCNNJCXSV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPJGFIQJVJRKECMSWIRAXOT3KIF3U62SBO5LWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKKV2E2RCFORGUIRSVJVCECNSNIRATMTKEIJQUS2LXNFSEOVTZMJLWY5KZLBJHAYRSGVTGIR3MORNFGSJWJFVES52NNJKXITKEIV2E2RCGKVGUIQJWJVCECNSNIRBGCSLJO5UWGSCKOZNEQVTKMRBUSNSJNZJGYY3OJJUFU3JZPFRFGSLTJFWVU42ZK5SHUSLKOA3WMWBQHUXC63ZZNBYU2NBTFNTXK6DHMNEEOT2ZFNZUSSTIO4ZTQNLGJMYGE4TVOFCXORCZF52VK53UNNLDOMZWJVSEUMJPKZLG4MS2PA3XANTMGJ3TAQSXMNGVE5SHNIZCWS3QPJUEQNKJMZATKMLEIFVWGYJUMRLDAMZTHBIHO3KWNRQXMSSQGRYEU6CJJE4UINSVIZGFKYKWKBVGWV2KORRUINTQMFWDM32PMZDW4SZSPJIEWSSSNVDUQVRTMVNHO4KGMUVW6N3LF5ZSWQKUJZUFAWTHKMXUWVSZM4XUWK3MI5IHOTBXNJBHQSJXI5HWC2ZWKVQWSYKIN5SWWMCSKRXTOMSEKE6T2"
  description = "License URL https://license.hashicorp.services/customers/7f3e3c93-0677-dafa-f3b4-8ee6c7fdf8d1"
}

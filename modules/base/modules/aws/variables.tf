############
# Optional #
############

variable "common_tags" {
  type        = map(any)
  description = "The tags to apply to all resources."
  default     = {}
}

variable "s3_buckets" {
  type        = list(string)
  description = "A list of buckets to be created. Buckets wil be created with the naming scheme of `[username_of_@hashicorp_email]-[bucket_name]` where bucket_name is what is provided as the value for this variable."
  default     = ["license", "airgap-packages"]
}

variable "additional_subnet_types" {
  type        = list(string)
  description = "List of types of subnets to create, for each subnet type, a subnet will be created in each availability zone defined in `availability_zones`. The public, private, and db subnets are created by default and are not modified by this variable."
  default     = ["elasticache"]
}

variable "root_cidr" {
  type        = string
  description = "CIDR block to use for the vpc"
  default     = "10.0.0.0/16"
}

variable "ssm-role-suffix" {
  type        = string
  default     = ""
  description = "Value to append to the SSM role name, useful for deploying base infrastructure in another region where IAM names still conflict."
}

variable "aws_region" {
  type        = string
  description = "The region to deploy to."
  
}
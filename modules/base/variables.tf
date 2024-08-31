############
# Required #
############

variable "aws_region" {
  type        = string
  description = "The AWS region to create the resources within. Examples: `us-west-1`,`us-east-1"
}

############
# Optional #
############

variable "additional_subnet_types" {
  type        = set(string)
  description = "The additional subnet types to create, for each subnet type, a subnet will be created in each availability zone defined in `availability_zones`. The public, private, and db subnets are created by default and are not modified by this variable."
  default     = ["elasticache"]
}

variable "s3_buckets" {
  type        = set(string)
  description = "A list of buckets to be created. A default value of [\"license\", \"airgap-packages\"] is used if nothing is provided. Buckets wil be created with the naming scheme of `[username_of_@hashicorp_email]-[bucket_name]` where bucket_name is what is provided as the value for this variable."
  default     = ["license", "airgap-packages"]
}

variable "license_bucket" {
  type        = string
  description = "Which of the s3 buckets that will be created to use for storing the license file. The default value is `license`"
  default     = "license"
}

variable "airgap_packages" {
  type        = string
  description = "Which of the s3 buckets that will be created to use for storing airgap packages. The default value is `airgap-packages`"
  default     = "airgap-packages"
}

variable "ssm-role-suffix" {
  type        = string
  default     = ""
  description = "Value to append to the SSM role name, useful for deploying base infrastructure in another region where IAM names still conflict."
}
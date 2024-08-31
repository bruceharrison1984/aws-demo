variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "iam_role_name" {
  description = "Role that will be provided access to the S3 Bucket"
  type        = string
}

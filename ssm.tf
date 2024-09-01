resource "random_string" "username" {
  length  = 16
  special = false
  numeric = true
  upper   = true
}

resource "aws_ssm_parameter" "username" {
  name  = "/mongodb/username"
  type  = "SecureString"
  value = random_string.username.result
}

resource "random_string" "password" {
  length  = 16
  special = false
  numeric = true
  upper   = true
}

resource "aws_ssm_parameter" "password" {
  name  = "/mongodb/password"
  type  = "SecureString"
  value = random_string.password.result
}

resource "aws_ssm_parameter" "connectionstring" {
  name  = "/mongodb/connection-string"
  type  = "SecureString"
  value = "need-data"
}

resource "aws_ssm_parameter" "mongo_backup_s3" {
  name  = "/mongodb/backup-s3-bucket"
  type  = "String"
  value = "s3://${aws_s3_bucket.main.bucket}"
}

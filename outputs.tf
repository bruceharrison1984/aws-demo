# output "file" {
#   value = templatefile("userdata/start.sh", {
#     SSM_USERNAME_PATH = aws_ssm_parameter.username.id
#     SSM_PASSWORD_PATH = aws_ssm_parameter.password.id
#   })
# }

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "MongoDB-Instance-Profile"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

## Per requirements
resource "aws_iam_role_policy_attachment" "aws_admin" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "MongoDB-Instance-Profile"
  role = aws_iam_role.role.name
}

resource "aws_instance" "mongo" {
  ami                    = "ami-04695503af0cb3cb1" //bitnami-mongodb-6.0.7-1-r01-linux-debian-11-x86_64-hvm-ebs-nami
  instance_type          = "t3.small"
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2.id
  key_name               = "mongo" //created ahead of time
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  user_data = templatefile("userdata/start.sh", {
    SSM_USERNAME_PATH = aws_ssm_parameter.username.id
    SSM_PASSWORD_PATH = aws_ssm_parameter.password.id
    S3_PATH           = aws_ssm_parameter.mongo_backup_s3.id
  })
  tags = {
    Name = "MongoDB"
  }
}

resource "aws_security_group" "allow_ssh" {
  name   = "Allow SSH"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "Allow SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

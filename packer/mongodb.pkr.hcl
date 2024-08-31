packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  profile = "sandbox"
  region  = "us-east-1"

  ami_name      = "wiz-mongo"
  instance_type = "t2.micro"

  source_ami_filter {
    filters = {
      name                = "bitnami-mongodb-6.0.7-1-r01-linux-debian-11-x86_64-hvm-ebs-nami"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["979382823631"]
  }
  ssh_username = "root"
}

build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
}
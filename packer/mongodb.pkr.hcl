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

  ami_name      = "wiz-mongo-${formatdate("YY_MM_DD_hh_mm", timestamp())}"
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
  ssh_username = "bitnami"
}

build {
  name    = "wiz-mongo"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "file" {
    source      = "mongo-init.sh"
    destination = "/home/bitnami/mongo-init.sh"
  }

  provisioner "file" {
    source      = "setup-mongo.js"
    destination = "/home/bitnami/setup-mongo.js"
  }


  provisioner "shell" {
    inline = [
      "chmod +x /home/bitnami/mongo-init.sh",
      "/home/bitnami/mongo-init.sh",
      "echo 'cleanup init files'",
      "rm /home/bitnami/mongo-init.sh /home/bitnami/setup-mongo.js",
    ]
  }

}
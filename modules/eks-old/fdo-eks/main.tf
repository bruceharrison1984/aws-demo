locals {
  # user_email is the users email address as gathered from the aws_caller_identity data source
  # the email is prefixed with a string of text followed by a semicolon, so we want to strip that away
  user_email   = replace(data.aws_caller_identity.current.user_id, "/^.*:/", "")
  base-infra   = data.terraform_remote_state.base-infra.outputs
  tfe_hostname = "${random_pet.name.id}.${var.zone_name}"

  tags = merge({
    OwnedBy = local.user_email
  }, var.tags)
}

resource "random_pet" "name" {
  length = 2
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.tfe_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.kubernetes_service.tfe.status.0.load_balancer.0.ingress.0.hostname]
}

resource "tls_private_key" "tfe" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "tfe" {
  private_key_pem = tls_private_key.tfe.private_key_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [local.tfe_hostname]

  subject {
    common_name  = local.tfe_hostname
    organization = "HashiCorp Inc."
  }
}

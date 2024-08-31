resource "aws_iam_role" "tfe_service_account" {
  name               = "${random_pet.name.id}-tfe-service-account"
  description        = "IAM Role assumed by the EKS TFE ServiceAccount"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

/** this allows EKS to assume this role to interact with AWS */
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"

      ## NOTE: 
      ## This relies on the tfe-fdo-kubernetes module not changing the namespace or service account name of the TFE Helm templates
      ## We simply infer the defaults so everything lines up correctly
      values = ["system:serviceaccount:terraform-enterprise:terraform-enterprise"]
    }
  }
}


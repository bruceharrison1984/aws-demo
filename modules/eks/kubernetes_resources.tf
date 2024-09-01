/** this allows EKS to assume this role to interact with AWS */
data "aws_iam_policy_document" "alb_controller_assume" {
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

      values = ["system:serviceaccount:default:load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "alb_controller" {
  name        = "eks-alb-policy"
  path        = "/"
  description = "Allow EKS to manage ALBs"
  policy      = file("${path.module}/alb-controller.iam.json")
}

resource "aws_iam_role" "alb_controller" {
  name               = "ALB-Controller"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume.json
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = "load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

resource "null_resource" "cluster" {
  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command     = "./init-alb-controller.sh ${module.eks.cluster_name} ${kubernetes_service_account.service_account.metadata.name}"
    interpreter = ["bash"]
  }
}

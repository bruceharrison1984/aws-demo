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

## Give the cluster time to complete initialization before running manifests
resource "time_sleep" "wait_5_minutes" {
  depends_on      = [aws_iam_role_policy_attachment.alb_controller]
  create_duration = "300s"
}

resource "kubectl_manifest" "alb_controller_prereqs" {
  depends_on = [time_sleep.wait_5_minutes]
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.alb_controller.arn}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: IngressClassParams
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: alb
---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: alb
spec:
  controller: ingress.k8s.aws/alb
  parameters:
    apiGroup: elbv2.k8s.aws
    kind: IngressClassParams
    name: alb
YAML
}

resource "helm_release" "alb_controller" {
  name       = "terraform-enterprise"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  timeout    = "660"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "load-balancer-controller"
  }

  depends_on = [kubectl_manifest.alb_controller_prereqs]
}

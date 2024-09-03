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

      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
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
resource "time_sleep" "wait_3_minutes" {
  depends_on      = [aws_iam_role_policy_attachment.alb_controller]
  create_duration = "180s"
}

resource "kubectl_manifest" "alb_service_account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.alb_controller.arn}
YAML
}

resource "kubectl_manifest" "ingress_class_params" {
  yaml_body = <<YAML
apiVersion: elbv2.k8s.aws/v1beta1
kind: IngressClassParams
metadata:
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
  name: alb
YAML
}

resource "kubectl_manifest" "ingress_class" {
  depends_on = [kubectl_manifest.ingress_class_params]
  yaml_body  = <<YAML
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
    value = "aws-load-balancer-controller"
  }

  depends_on = [kubectl_manifest.alb_controller_prereqs]
}

## Give the alb controller to complete initialization before loading app
resource "time_sleep" "wait_30_seconds" {
  depends_on      = [helm_release.alb_controller]
  create_duration = "30s"
}

resource "kubectl_manifest" "tasky_namespace" {
  depends_on = [time_sleep.wait_30_seconds]
  yaml_body  = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: tasky
YAML
}

resource "kubectl_manifest" "tasky_deployment" {
  depends_on = [kubectl_manifest.tasky_namespace]
  yaml_body  = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: tasky
  name: task-deployment
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: tasky-app
  replicas: 2
  template:
    metadata:
      labels:
        app.kubernetes.io/name: tasky-app
    spec:
      containers:
      - image: leeharrison1984/tasky:latest
        imagePullPolicy: Always
        name: tasky-app
        ports:
        - containerPort: 8080
        env:
        - name: MONGODB_URI
          value: ${var.mongo_connection_string}
        - name: SECRET_KEY
          value: secret123
YAML
}

resource "kubectl_manifest" "tasky_service" {
  depends_on = [kubectl_manifest.tasky_deployment]
  yaml_body  = <<YAML
apiVersion: v1
kind: Service
metadata:
  namespace: tasky
  name: tasky-service
spec:
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: tasky-app
YAML
}

resource "kubectl_manifest" "tasky_networking" {
  depends_on = [kubectl_manifest.tasky_service]
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: tasky
  name: tasky-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: tasky-service
              port:
                number: 80
YAML
}

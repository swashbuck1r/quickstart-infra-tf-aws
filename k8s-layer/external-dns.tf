
data "aws_region" "current" {}

resource "aws_iam_policy" "external_dns" {
  name        = "external_dns"
  description = "IAM policy for management by external-dns"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource": [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  }
EOF
}

data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns-controller"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.main.arn]
      type        = "Federated"
    }
  }
}


resource "aws_iam_role" "external_dns" {
  name               = "external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "kubernetes_service_account" "external-dns-controller" {
  automount_service_account_token = true
  metadata {
    name      = "external-dns-controller"
    namespace = kubernetes_namespace.external_dns.id
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}


resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

# NOTE: this sometimes fails during initial setup (probably because the ALB webhooks are not available yet)
# TODO: see if we can add a more robust retry here
resource "helm_release" "external_dns" {
  depends_on = [kubernetes_namespace.external_dns, aws_iam_role_policy_attachment.external_dns_attach]

  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = kubernetes_namespace.external_dns.id
  version    = "6.20.4"

  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external-dns-controller.metadata.0.name
  }

  set {
    name = "serviceAccount.create"
    value = false
  }

  set {
    name = "policy"
    value = "sync"
  }
}
resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.5"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.target.id
  }

  set {
    name  = "serviceAccount.name"
    value = aws_iam_role.aws_load_balancer_controller.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name = "serviceAccount.create"
    value = false
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.default.id
  }
}


data "aws_vpc" "default" {
  id = var.vpc_id
}
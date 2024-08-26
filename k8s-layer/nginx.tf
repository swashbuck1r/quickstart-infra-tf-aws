resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  namespace  = "kube-system" # must be the same namespace as the alb-controller

  # Set "nginx" as the default ingress class name
  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  # Using NodePort type allows the ALB ingress to delegate to the nginx controller
  # for in-cluster ingress routing
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
}

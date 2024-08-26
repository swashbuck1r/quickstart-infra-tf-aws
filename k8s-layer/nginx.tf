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

  set {
    name  = "controller.publishService.enabled"
    value = "false"
  }

  # Forcefully sets the LB hostname used this ingress to the
  # primary cluster ALB. Ideally, the ingress could discover
  # the LB hostname by using a controller.publishIngress setting, but
  # alas, it only supports grabbing this value from a k8s-service, but
  # the AWS alb-controller only provides this through its ingress.
  set {
    name  = "controller.extraArgs.publish-status-address"
    value = kubernetes_ingress_v1.alb_ingress_connect_nginx.status.0.load_balancer.0.ingress.0.hostname
  }
}

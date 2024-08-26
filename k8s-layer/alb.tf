resource "kubernetes_ingress_v1" "alb_ingress_connect_nginx" {
  metadata {
    name      = "alb-ingress-connect-nginx"
    namespace = "kube-system"

    annotations = {
      # Ingress Core Settings
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" : "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" : "traffic-port"
      "alb.ingress.kubernetes.io/healthcheck-path" : "/healthz" # Put the path of readiness probe over here
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" : "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" : "5"
      "alb.ingress.kubernetes.io/success-codes" : "200"
      "alb.ingress.kubernetes.io/healthy-threshold-count" : "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" : "2"
      ## SSL Settings
      "alb.ingress.kubernetes.io/listen-ports" : "[{ \"HTTPS\" : 443 }, { \"HTTP\" : 80 }]"
      "alb.ingress.kubernetes.io/certificate-arn" : var.ingress_alb_certificate_arn
      "external-dns.alpha.kubernetes.io/hostname" : var.ingress_alb_hostname
      # redirect all HTTP to HTTPS
      "alb.ingress.kubernetes.io/actions.ssl-redirect" : "{ \"Type\" : \"redirect\", \"RedirectConfig\" : { \"Protocol\" : \"HTTPS\", \"Port\" : \"443\", \"StatusCode\" : \"HTTP_301\" } }"
    }
  }



  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "ssl-redirect"
              port {
                name = "use-annotation"
              }
            }
          }
        }

        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "ingress-nginx-controller"
              port {
                number = "80"
              }
            }
          }
        }
      }
    }
  }
  wait_for_load_balancer = true
}

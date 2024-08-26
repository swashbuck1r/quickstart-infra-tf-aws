# Defines the Amazon Load Balancer used for external routing into the EKS cluster
# Requests for deployed apps will pass through the ALB ingress to a cluster-local
# nginx (NodePort) ingress. 
resource "kubectl_manifest" "alb_ingress" {
  yaml_body = <<YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: alb-ingress-connect-nginx
      namespace: kube-system
      annotations:
        # Ingress Core Settings
        alb.ingress.kubernetes.io/scheme: internet-facing
        # Health Check Settings
        alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
        alb.ingress.kubernetes.io/healthcheck-port: traffic-port
        alb.ingress.kubernetes.io/healthcheck-path: /healthz # Put the path of readiness probe over here
        alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
        alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
        alb.ingress.kubernetes.io/success-codes: '200'
        alb.ingress.kubernetes.io/healthy-threshold-count: '2'
        alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
        ## SSL Settings
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
        alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:189768267137:certificate/99bc14a9-bc03-4d4a-92ca-88842ca76f39
        external-dns.alpha.kubernetes.io/hostname: '*.arch.beescloud.com'
        #alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-1-2017-01 #Optional (Picks default if not used)
        # redirect all HTTP to HTTPS
        alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    spec:
      ingressClassName: alb
      rules:
      - http:
          paths:
            - path: /*
              pathType: ImplementationSpecific
              backend:
                service:
                  name: ssl-redirect
                  port:
                    name: use-annotation
            - path: /*
              pathType: ImplementationSpecific
              backend:
                service:
                  name: ingress-nginx-controller # Make sure you name the service correctly by checking the name of it nginx ingress controller service nothing else
                  port:
                    number: 80
YAML
}
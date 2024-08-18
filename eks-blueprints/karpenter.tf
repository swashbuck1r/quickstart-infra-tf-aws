################################################################################
# Karpenter
################################################################################

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

resource "kubectl_manifest" "karpenter_default_ec2_node_class" {
  yaml_body = <<YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
      annotations:
        kubernetes.io/description: "General purpose EC2NodeClass for running Amazon Linux 2 nodes"
    spec:
      amiFamily: AL2 # Amazon Linux 2
      role: "karpenter-${var.cluster_name}" # replace with your cluster name
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}" # replace with your cluster name
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}" # replace with your cluster name
YAML
  depends_on = [
    module.eks_blueprints_addons.karpenter,
  ]
}


resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: general-purpose
      annotations:
        kubernetes.io/description: "General purpose NodePool for generic workloads"
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["t"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["t3"]
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["small"]
            
          nodeClassRef:
            apiVersion: karpenter.k8s.aws/v1beta1
            kind: EC2NodeClass
            name: default
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h
  YAML
  depends_on = [
    module.eks_blueprints_addons.karpenter,
  ]
}

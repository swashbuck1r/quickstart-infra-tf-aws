terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.5"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }

  required_version = "~> 1.5"
}

## THIS TO AUTHENTICATE TO ECR, DON'T CHANGE IT
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      TerraformSource = "infra"
    }
  }
}

data "aws_eks_cluster" "target" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.target.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.target.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.target.name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.target.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.target.name]
    command     = "aws"
  }
}

variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "ebs_csi_driver_irsa_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.3"

  cluster_name      = data.aws_eks_cluster.target.name
  cluster_endpoint  = data.aws_eks_cluster.target.endpoint
  cluster_version   = data.aws_eks_cluster.target.version
  oidc_provider_arn = var.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = var.ebs_csi_driver_irsa_role_arn
    }
  }

  enable_aws_load_balancer_controller = true

  # Enable external-dns and certificate mgmt for all zones managed by the AWS account
  # This allows app ingresses to use any hostname that is part of a zone managed by this account
  enable_external_dns = true
  external_dns_route53_zone_arns = [
    "arn:aws:route53:::hostedzone/*"
  ]
  external_dns = {
    set = [
      {
        name  = "policy"
        value = "sync"
        type  = "string"
      }
    ]
  }
  enable_cert_manager                   = true
  cert_manager_route53_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]

  enable_karpenter = true
  # from https://github.com/aws-samples/karpenter-blueprints/blob/main/cluster/terraform/main.tf#L160C3-L169C4
  karpenter = {
    chart_version       = "0.37.0"
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }
  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter_node = {
    iam_role_use_name_prefix = false
  }


  tags = {}
}

resource "aws_eks_access_entry" "eks_access_entry" {
  cluster_name  = data.aws_eks_cluster.target.name
  principal_arn = module.eks_blueprints_addons.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"
}



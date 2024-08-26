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

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}


locals {
  cluster_identity_oidc_issuer = data.aws_eks_cluster.target.identity[0]["oidc"][0]["issuer"]
}


data "aws_iam_openid_connect_provider" "main" {
  url = local.cluster_identity_oidc_issuer
}

# output "cluster_identity_oidc_issuer" {
#   value = local.cluster_identity_oidc_issuer
# }

# output "aws_iam_openid_connect_provider" {
#   value = data.aws_iam_openid_connect_provider.main
# }
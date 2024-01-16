terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.5"
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

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name                   = "cloudbees-quickstart-cluster"
  cluster_version                = "1.28"
  cluster_endpoint_public_access = true


  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    core_node_group = {
      instance_types = ["m5.large"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  manage_aws_auth_configmap = false
}

output "cluster_name" {
  value = module.this.cluster_name
}

output "oidc_provider_arn" {
  value = module.this.oidc_provider_arn
}

output "node_group_iam_role_arns" {
  value = [for _,ng in module.this.eks_managed_node_groups : ng.iam_role_arn]
}
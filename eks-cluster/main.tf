terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.62"
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.eks_cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  authentication_mode = "API_AND_CONFIG_MAP"


  cluster_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs

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
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }
}

# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"

#   cluster_name = module.eks.cluster_name

#   # Attach additional IAM policies to the Karpenter node IAM role
#   node_iam_role_additional_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_group_iam_role_arns" {
  value = [for _, ng in module.eks.eks_managed_node_groups : ng.iam_role_arn]
}

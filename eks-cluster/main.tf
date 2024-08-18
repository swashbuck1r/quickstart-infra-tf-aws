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
  region = var.region
  default_tags {
    tags = {
      TerraformSource = "infra"
    }
  }
}

locals {
  name = var.eks_cluster_name
  cluster_version = "1.30"

  tags = {
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8.3"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true


  cluster_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs

  cluster_addons = {
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }

    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  create_cloudwatch_log_group              = false
  create_cluster_security_group            = false
  create_node_security_group               = false
  authentication_mode                      = "API_AND_CONFIG_MAP"
  # enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      # instance_types  = ["m4.large", "m5.large", "m5a.large", "m5ad.large", "m5d.large", "t2.large", "t3.large", "t3a.large"]
      instance_types  = ["t3.small"]

      create_security_group = false

      subnet_ids   = var.private_subnet_ids
      max_size     = 2
      desired_size = 2
      min_size     = 0

      # Launch template configuration
      create_launch_template = true              # false will use the default launch template
      launch_template_os     = "amazonlinux2eks" # amazonlinux2eks or bottlerocket

      labels = {
        intent = "control-apps"
      }
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })
}

# TODO: move this CSI stuff into the EKS cluster recipe
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.37.1"

  role_name_prefix = "${local.name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {}
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "node_group_iam_role_arns" {
  value = [for _, ng in module.eks.eks_managed_node_groups : ng.iam_role_arn]
}

output "ebs_csi_driver_irsa_role_arn" {
  value = module.ebs_csi_driver_irsa.iam_role_arn
}
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

variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "node_group_iam_role_arns" {
  type = list(string)
}

# TODO: remove this from the quickstart -- this is not a generic role 
variable "admin_role_name" {
  type    = string
  default = "AWSReservedSSO_infra-admin_19ffd3b99ad3940b"
}

data "aws_iam_role" "admin" {
  name = var.admin_role_name
}

variable "deployer_role_name" {
  type    = string
  default = "cloudbees-eks-deployer"
}

data "aws_iam_role" "deployer" {
  name = var.deployer_role_name
}

variable "infra_mgmt_role_name" {
  type    = string
  default = "cloudbees-infra-mgmt"
}

data "aws_iam_role" "infra_mgmt" {
  name = var.infra_mgmt_role_name
}

locals {
  iam_access_entries = [
    {
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      principal_arn = data.aws_iam_role.admin.arn
    },
    {
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      principal_arn = data.aws_iam_role.deployer.arn
    },
    {
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      principal_arn = data.aws_iam_role.infra_mgmt.arn
    }
  ]

  # this is how we map AWS roles into Kubernetes users
  # aws_auth_data = {
  #   "mapRoles" = jsonencode(concat([
  #     for arn in var.node_group_iam_role_arns : {
  #       groups = [
  #         "system:bootstrappers",
  #         "system:nodes"
  #       ]
  #       rolearn  = arn
  #       username = "system:node:{{EC2PrivateDNSName}}"
  #     }], [
  #     {
  #       groups = [
  #         "system:masters",
  #       ]
  #       rolearn  = data.aws_iam_role.admin.arn
  #       username = data.aws_iam_role.admin.name
  #     },
  #     # Set permissions for the cloudbees-eks-deployer AWS role
  #     # TODO: define a automation:deployer group with more limited permissions (see deployer_role_binding in arch-infra)
  #     {
  #       groups = [
  #         "system:masters",
  #       ]
  #       rolearn  = data.aws_iam_role.deployer.arn
  #       username = data.aws_iam_role.deployer.name
  #     },
  #     # Set permissions for the cloudbees-infra-mgmt AWS role
  #     {
  #       groups = [
  #         "system:masters",
  #       ]
  #       rolearn  = data.aws_iam_role.infra_mgmt.arn
  #       username = data.aws_iam_role.infra_mgmt.name
  #     },
  #   ]))
  # }
}

# resource "kubernetes_config_map_v1_data" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = local.aws_auth_data

#   force = true
# }

resource "aws_eks_access_entry" "eks_access_entry" {
  for_each      = { for entry in local.iam_access_entries : entry.principal_arn => entry }
  cluster_name  = data.aws_eks_cluster.target.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_policy_association" {
  for_each      = { for entry in local.iam_access_entries : entry.principal_arn => entry }
  cluster_name  = data.aws_eks_cluster.target.name
  policy_arn    = each.value.policy_arn
  principal_arn = each.value.principal_arn

  access_scope {
    type = "cluster"
  }
}

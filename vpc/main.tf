// Inspired by https://rtfm.co.ua/en/terraform-building-eks-part-1-vpc-subnets-and-endpoints/
// TODO: maybe add the entpoints from the article?

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
  region = local.region
  default_tags {
    tags = {
      TerraformSource = "infra"
    }
  }
}

module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  version         = "1.0.0"
  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = "public-1"
      new_bits = 4
    },
    {
      name     = "public-2"
      new_bits = 4
    },
    {
      name     = "private-1"
      new_bits = 4
    },
    {
      name     = "private-2"
      new_bits = 4
    },
    {
      name     = "intra-1"
      new_bits = 8
    },
    {
      name     = "intra-2"
      new_bits = 8
    },
  ]
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name   = var.eks_cluster_name
  region = var.region
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "cloudbees-quickstart-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = [module.subnet_addrs.network_cidr_blocks["private-1"], module.subnet_addrs.network_cidr_blocks["private-2"]]
  public_subnets  = [module.subnet_addrs.network_cidr_blocks["public-1"], module.subnet_addrs.network_cidr_blocks["public-2"]]

  create_igw         = true # Expose public subnetworks to the Internet
  enable_nat_gateway = true # Hide private subnetworks behind NAT Gateway

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
    "karpenter.sh/discovery"              = local.name
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 9.0"

#   name               = "cloudbees-quickstart-alb"
#   load_balancer_type = "application"
#   security_groups    = [module.vpc.default_security_group_id]
#   subnets            = module.vpc.public_subnets
#   vpc_id             = module.vpc.vpc_id


#   # For example only
#   enable_deletion_protection = false

#   # Security Group
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = -1
#       to_port     = -1
#       ip_protocol = -1
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }

#   security_group_egress_rules = {
#     all_http = {
#       from_port   = -1
#       to_port     = -1
#       ip_protocol = -1
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }

#   listeners = {}

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }


# Enables spot instances for this AWS account
resource "aws_iam_service_linked_role" "spot_instances" {
  aws_service_name = "spot.amazonaws.com"
}
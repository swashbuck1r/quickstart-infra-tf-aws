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

variable "aws-user-name" {
  description = "An AWS user in the AWS account"
  type        = string
}

# leverage an existing service account user to assume created roles
data "aws_iam_user" "aws-user" {
  user_name = var.aws-user-name
}

# Store the aws-user details as an output var
output "aws-user" {
  value = data.aws_iam_user.aws-user
}
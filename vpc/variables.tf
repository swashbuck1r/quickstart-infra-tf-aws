variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR range for our VPC"
  default     = "10.0.0.0/16"
}

variable "region" {
  type        = string
  description = "AWS region to deploy resources"
}
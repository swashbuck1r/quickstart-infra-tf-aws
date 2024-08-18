variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "cb-quickstart"
}

variable "region" {
  type        = string
  description = "AWS region to deploy resources"
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

variable "eks_endpoint_public_access_cidrs" {
  type = list(string)
  default     = ["0.0.0.0/0"]
}
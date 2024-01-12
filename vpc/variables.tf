variable "vpc_cidr" {
  type        = string
  description = "The CIDR range for our VPC"
  default     = "10.0.0.0/16"
}
output "vpc_id" {
  description = "List of IDs of public subnets"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "public_subnet_cidrs" {
  value = [module.subnet_addrs.network_cidr_blocks["public-1"], module.subnet_addrs.network_cidr_blocks["public-2"]]
}
output "private_subnets_cidrs" {
  value = [module.subnet_addrs.network_cidr_blocks["private-1"], module.subnet_addrs.network_cidr_blocks["private-2"]]
}
output "intra_subnets_cidrs" {
  value = [module.subnet_addrs.network_cidr_blocks["intra-1"], module.subnet_addrs.network_cidr_blocks["intra-2"]]
}

output "alb_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = module.alb.security_group_arn
}

output "alb_security_group_id" {
  description = "ID of the security group"
  value       = module.alb.security_group_id
}

output "alb_target_groups" {
  description = "alb target targets"
  value       = module.alb.target_groups
}

output "alb_arn" {
  description = "alb lister ARN"
  value = module.alb.arn
}
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of the public subnet IDs"
  value       = module.vpc.public_subnet_ids_list
}

output "private_subnet_ids" {
  description = "List of the private subnet IDs"
  value       = module.vpc.private_subnet_ids_list
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "bastion_host" {
  description = "Bastion host public IP"
  value       = module.bastion.bastion_public_ip
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

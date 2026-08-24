output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  value       = aws_security_group.bastion.id
}

output "app_sg_id" {
  description = "Security group ID for app instances"
  value       = aws_security_group.app.id
}

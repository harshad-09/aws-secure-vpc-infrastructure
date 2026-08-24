output "bastion_public_ip" {
  description = "Public (Elastic) IP of the bastion host, if enabled"
  value       = var.enable_bastion ? aws_eip.this[0].public_ip : null
}

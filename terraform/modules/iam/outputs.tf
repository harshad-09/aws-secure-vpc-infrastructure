output "app_instance_profile_name" {
  description = "Instance profile name for app instances"
  value       = aws_iam_instance_profile.app_instance_profile.name
}

output "bastion_instance_profile_name" {
  description = "Instance profile name for the bastion host"
  value       = aws_iam_instance_profile.bastion_instance_profile.name
}

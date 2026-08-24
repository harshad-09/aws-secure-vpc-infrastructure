output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Map of AZ => public subnet ID"
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids" {
  description = "Map of AZ => private subnet ID"
  value       = { for az, s in aws_subnet.private : az => s.id }
}

output "public_subnet_ids_list" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids_list" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

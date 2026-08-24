variable "project_name" {
  description = "Name prefix used for tagging resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security groups belong to"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the bastion"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
}

variable "project_name" {
  description = "Name prefix used for tagging resources"
  type        = string
}

variable "enable_bastion" {
  description = "Whether to create the bastion host"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID for the bastion instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the bastion"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch the bastion into"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID to attach to the bastion"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to the bastion"
  type        = string
}

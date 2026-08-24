variable "project_name" {
  description = "Name prefix used for tagging/naming resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for app instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for app instances"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "user_data_base64" {
  description = "Base64-encoded user_data script"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to app instances"
  type        = string
}

variable "app_sg_id" {
  description = "Security group ID to attach to app instances"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs the ASG will launch instances into"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN to attach the ASG to"
  type        = string
}

variable "asg_desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "asg_min" {
  description = "Minimum number of instances"
  type        = number
}

variable "asg_max" {
  description = "Maximum number of instances"
  type        = number
}

variable "health_check_grace_period" {
  description = "Seconds to wait before ELB health checks affect ASG decisions"
  type        = number
  default     = 300
}

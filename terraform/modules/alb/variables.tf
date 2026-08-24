variable "project_name" {
  description = "Name prefix used for tagging/naming resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB will be placed in"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID to attach to the ALB"
  type        = string
}

variable "app_port" {
  description = "Port the target group forwards traffic to"
  type        = number
}

variable "health_check_path" {
  description = "Path used for the target group health check"
  type        = string
  default     = "/health"
}

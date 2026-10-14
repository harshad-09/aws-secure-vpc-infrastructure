variable "project_name" {
  description = "Name of the project, used as a prefix for resource names"
  type        = string
  default     = "Vpc-Project"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet" {
  description = "Public subnet CIDRs by AZ"
  type        = map(string)
  default = {
    "ap-south-1a" = "10.0.1.0/24"
    "ap-south-1b" = "10.0.2.0/24"
  }
}

variable "private_subnet" {
  description = "Private subnet CIDRs by AZ"
  type        = map(string)
  default = {
    "ap-south-1a" = "10.0.11.0/24"
    "ap-south-1b" = "10.0.12.0/24"
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway instead of one per AZ (lower cost, reduced HA)"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID (must be Ubuntu/Debian-based to match user_data.sh, which uses apt-get)"
  type        = string
  default     = "ami-01a00762f46d584a1"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
  default     = "vpc-infra-key"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the bastion host (lock to your IP, e.g. 1.2.3.4/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_bastion" {
  description = "Whether to create the bastion host"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path used for the ALB target group health check"
  type        = string
  default     = "/health"
}

variable "health_check_grace_period" {
  description = "Seconds to wait before ELB health checks affect ASG scaling decisions"
  type        = number
  default     = 300
}

variable "asg_desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "asg_min" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

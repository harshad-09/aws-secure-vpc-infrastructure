variable "project_name" {
  description = "Name prefix used for tagging resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet CIDRs keyed by availability zone"
  type        = map(string)
}

variable "private_subnet" {
  description = "Private subnet CIDRs keyed by availability zone"
  type        = map(string)
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

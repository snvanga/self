variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Public SSH CIDR block, for example 203.0.113.45/32"
  type        = string
}

variable "allowed_grafana_cidr" {
  description = "Public Grafana CIDR block, for example 203.0.113.45/32"
  type        = string
}
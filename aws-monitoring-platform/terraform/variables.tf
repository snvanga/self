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

variable "ssh_user" {
  description = "SSH user to connect to the instance for service checks"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key used to connect to the instance (used by local health checks)"
  type        = string
  default     = "~/.ssh/siva-test.pem"
}

variable "enable_ssh_health_check" {
  description = "When true, run an SSH-based service status check from the machine running Terraform. Disable in CI or on machines without Python/SSH access."
  type        = bool
  default     = false
}

variable "enable_grafana_health_check" {
  description = "When true, run Grafana HTTP health checks as part of Terraform. Disable in CI or when Grafana is not yet reachable from the runner."
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr" {
  description = "Public SSH CIDR block, for example 203.0.113.45/32"
  type        = string
}

variable "allowed_grafana_cidr" {
  description = "Public Grafana CIDR block, for example 203.0.113.45/32"
  type        = string
}
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "environment_name" {
  description = "Name of the environment"
  type        = string
  default     = "ecs-fullstack"

  validation {
    condition     = length(var.environment_name) > 0 && length(var.environment_name) < 23
    error_message = "environment_name must not be empty and must be less than 23 characters."
  }
}

variable "port_app_server" {
  description = "Port used by the backend/server application"
  type        = number
  default     = 3001
}

variable "port_app_client" {
  description = "Port used by the frontend/client application"
  type        = number
  default     = 80
}

variable "container_name" {
  description = "Container names for ECS services"
  type        = map(string)

  default = {
    server = "Container-server"
    client = "Container-client"
  }
}

variable "iam_role_name" {
  description = "IAM role names used by ECS and CodeDeploy"
  type        = map(string)

  default = {
    ecs           = "ECS-task-excecution-Role"
    ecs_task_role = "ECS-task-Role"
    codedeploy    = "CodeDeploy-Role"
  }
}
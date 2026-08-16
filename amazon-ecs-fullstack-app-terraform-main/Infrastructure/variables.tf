# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


# ============================================================
# AWS REGION
# ============================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"

  type = string
}


# ============================================================
# ENVIRONMENT NAME
# ============================================================

variable "environment_name" {
  description = "Name of the environment"

  type = string

  validation {
    condition = length(var.environment_name) < 23

    error_message = "environment_name must be less than 23 characters."
  }
}


# ============================================================
# SERVER APPLICATION PORT
# ============================================================

variable "port_app_server" {
  description = "Port used by the backend/server application"

  type    = number
  default = 3001
}


# ============================================================
# CLIENT APPLICATION PORT
# ============================================================

variable "port_app_client" {
  description = "Port used by the frontend/client application"

  type    = number
  default = 80
}


# ============================================================
# ECS CONTAINER NAMES
# ============================================================

variable "container_name" {
  description = "Container names for ECS services"

  type = map(string)

  default = {
    server = "Container-server"
    client = "Container-client"
  }
}


# ============================================================
# IAM ROLE NAMES
# ============================================================

variable "iam_role_name" {
  description = "IAM role names used by ECS and CodeDeploy"

  type = map(string)

  default = {
    ecs           = "ECS-task-excecution-Role"
    ecs_task_role = "ECS-task-Role"
    codedeploy    = "CodeDeploy-Role"
  }
}
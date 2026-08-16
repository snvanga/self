# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0


# ============================================================
# FRONTEND APPLICATION URL
# ============================================================

output "application_url" {
  description = "Frontend application URL"

  value = "http://${module.alb_client.dns_alb}"
}


# ============================================================
# BACKEND SWAGGER URL
# ============================================================

output "swagger_endpoint" {
  description = "Backend Swagger documentation URL"

  value = "http://${module.alb_server.dns_alb}/api/docs"
}


# ============================================================
# FRONTEND ALB DNS
# ============================================================

output "frontend_alb_dns" {
  description = "Frontend Application Load Balancer DNS name"

  value = module.alb_client.dns_alb
}


# ============================================================
# BACKEND ALB DNS
# ============================================================

output "backend_alb_dns" {
  description = "Backend Application Load Balancer DNS name"

  value = module.alb_server.dns_alb
}


# ============================================================
# ECS CLUSTER
# ============================================================

output "ecs_cluster_name" {
  description = "ECS cluster name"

  value = module.ecs_cluster.ecs_cluster_name
}


# ============================================================
# ECS SERVER SERVICE
# ============================================================

output "ecs_server_service_name" {
  description = "Backend ECS service name"

  value = module.ecs_service_server.ecs_service_name
}


# ============================================================
# ECS CLIENT SERVICE
# ============================================================

output "ecs_client_service_name" {
  description = "Frontend ECS service name"

  value = module.ecs_service_client.ecs_service_name
}


# ============================================================
# SERVER ECR REPOSITORY
# ============================================================

output "server_ecr_repository_url" {
  description = "Backend ECR repository URL"

  value = module.ecr_server.ecr_repository_url
}


# ============================================================
# CLIENT ECR REPOSITORY
# ============================================================

output "client_ecr_repository_url" {
  description = "Frontend ECR repository URL"

  value = module.ecr_client.ecr_repository_url
}


# ============================================================
# SERVER CODEDEPLOY APPLICATION
# ============================================================

output "server_codedeploy_application" {
  description = "Backend CodeDeploy application name"

  value = module.codedeploy_server.application_name
}


# ============================================================
# CLIENT CODEDEPLOY APPLICATION
# ============================================================

output "client_codedeploy_application" {
  description = "Frontend CodeDeploy application name"

  value = module.codedeploy_client.application_name
}
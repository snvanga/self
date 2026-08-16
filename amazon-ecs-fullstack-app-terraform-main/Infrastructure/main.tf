# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

/*===========================
          Root file
============================*/


# ============================================================
# AWS PROVIDER
# ============================================================

provider "aws" {
  region = var.aws_region
}


# ============================================================
# RANDOM ID
# ============================================================

resource "random_id" "RANDOM_ID" {
  byte_length = 2
}


# ============================================================
# AWS ACCOUNT ID
# ============================================================

data "aws_caller_identity" "id_current_account" {}


# ============================================================
# NETWORKING
# ============================================================

module "networking" {
  source = "./Modules/Networking"

  cidr = [
    "10.120.0.0/16"
  ]

  name = var.environment_name
}


# ============================================================
# SERVER TARGET GROUP - BLUE
# ============================================================

module "target_group_server_blue" {
  source = "./Modules/ALB"

  create_target_group = true
  create_alb          = false

  name = "tg-${var.environment_name}-s-b"

  port     = 80
  protocol = "HTTP"

  vpc     = module.networking.aws_vpc
  tg_type = "ip"

  health_check_path = "/status"
  health_check_port = var.port_app_server

  depends_on = [
    module.networking
  ]
}


# ============================================================
# SERVER TARGET GROUP - GREEN
# ============================================================

module "target_group_server_green" {
  source = "./Modules/ALB"

  create_target_group = true
  create_alb          = false

  name = "tg-${var.environment_name}-s-g"

  port     = 80
  protocol = "HTTP"

  vpc     = module.networking.aws_vpc
  tg_type = "ip"

  health_check_path = "/status"
  health_check_port = var.port_app_server

  depends_on = [
    module.networking
  ]
}


# ============================================================
# CLIENT TARGET GROUP - BLUE
# ============================================================

module "target_group_client_blue" {
  source = "./Modules/ALB"

  create_target_group = true
  create_alb          = false

  name = "tg-${var.environment_name}-c-b"

  port     = 80
  protocol = "HTTP"

  vpc     = module.networking.aws_vpc
  tg_type = "ip"

  health_check_path = "/"
  health_check_port = var.port_app_client

  depends_on = [
    module.networking
  ]
}


# ============================================================
# CLIENT TARGET GROUP - GREEN
# ============================================================

module "target_group_client_green" {
  source = "./Modules/ALB"

  create_target_group = true
  create_alb          = false

  name = "tg-${var.environment_name}-c-g"

  port     = 80
  protocol = "HTTP"

  vpc     = module.networking.aws_vpc
  tg_type = "ip"

  health_check_path = "/"
  health_check_port = var.port_app_client

  depends_on = [
    module.networking
  ]
}


# ============================================================
# SERVER ALB SECURITY GROUP
# ============================================================

module "security_group_alb_server" {
  source = "./Modules/SecurityGroup"

  name        = "alb-${var.environment_name}-server"
  description = "Controls access to the server ALB"

  vpc_id = module.networking.aws_vpc

  cidr_blocks_ingress = [
    "0.0.0.0/0"
  ]

  ingress_port = 80

  depends_on = [
    module.networking
  ]
}


# ============================================================
# CLIENT ALB SECURITY GROUP
# ============================================================

module "security_group_alb_client" {
  source = "./Modules/SecurityGroup"

  name        = "alb-${var.environment_name}-client"
  description = "Controls access to the client ALB"

  vpc_id = module.networking.aws_vpc

  cidr_blocks_ingress = [
    "0.0.0.0/0"
  ]

  ingress_port = 80

  depends_on = [
    module.networking
  ]
}


# ============================================================
# SERVER APPLICATION ALB
# ==============================================================

module "alb_server" {
  source = "./Modules/ALB"

  create_alb          = true
  create_target_group = false

  name = "${var.environment_name}-ser"

  subnets = [
    module.networking.public_subnets[0],
    module.networking.public_subnets[1]
  ]

  security_group = module.security_group_alb_server.sg_id

  target_group = module.target_group_server_blue.arn_tg

  depends_on = [
    module.target_group_server_blue,
    module.security_group_alb_server
  ]
}


# ============================================================
# CLIENT APPLICATION ALB
# ============================================================

module "alb_client" {
  source = "./Modules/ALB"

  create_alb          = true
  create_target_group = false

  name = "${var.environment_name}-cli"

  subnets = [
    module.networking.public_subnets[0],
    module.networking.public_subnets[1]
  ]

  security_group = module.security_group_alb_client.sg_id

  target_group = module.target_group_client_blue.arn_tg

  depends_on = [
    module.target_group_client_blue,
    module.security_group_alb_client
  ]
}


# ============================================================
# ECS IAM ROLE
# ============================================================

module "ecs_role" {
  source = "./Modules/IAM"

  create_ecs_role = true

  name = var.iam_role_name["ecs"]

  name_ecs_task_role = var.iam_role_name["ecs_task_role"]

  dynamodb_table = [
    module.dynamodb_table.dynamodb_table_arn
  ]

  depends_on = [
    module.dynamodb_table
  ]
}


# ============================================================
# ECS IAM POLICY
# ============================================================

module "ecs_role_policy" {
  source = "./Modules/IAM"

  name = "ecs-ecr-${var.environment_name}"

  create_policy = true

  attach_to = module.ecs_role.name_role

  depends_on = [
    module.ecs_role
  ]
}


# ============================================================
# SERVER ECR
# ============================================================

module "ecr_server" {
  source = "./Modules/ECR"

  name = "repo-server"
}


# ============================================================
# CLIENT ECR
# ============================================================

module "ecr_client" {
  source = "./Modules/ECR"

  name = "repo-client"
}


# ============================================================
# SERVER ECS TASK DEFINITION
# ============================================================

module "ecs_taks_definition_server" {
  source = "./Modules/ECS/TaskDefinition"

  name = "${var.environment_name}-server"

  container_name = var.container_name["server"]

  execution_role_arn = module.ecs_role.arn_role

  task_role_arn = module.ecs_role.arn_role_ecs_task_role

  cpu    = 256
  memory = "512"

  docker_repo = module.ecr_server.ecr_repository_url

  region = var.aws_region

  container_port = var.port_app_server

  depends_on = [
    module.ecs_role,
    module.ecr_server
  ]
}


# ============================================================
# CLIENT ECS TASK DEFINITION
# ============================================================

module "ecs_taks_definition_client" {
  source = "./Modules/ECS/TaskDefinition"

  name = "${var.environment_name}-client"

  container_name = var.container_name["client"]

  execution_role_arn = module.ecs_role.arn_role

  task_role_arn = module.ecs_role.arn_role_ecs_task_role

  cpu    = 256
  memory = "512"

  docker_repo = module.ecr_client.ecr_repository_url

  region = var.aws_region

  container_port = var.port_app_client

  depends_on = [
    module.ecs_role,
    module.ecr_client
  ]
}


# ============================================================
# SERVER ECS TASK SECURITY GROUP
# ============================================================

module "security_group_ecs_task_server" {
  source = "./Modules/SecurityGroup"

  name = "ecs-task-${var.environment_name}-server"

  description = "Controls access to the server ECS task"

  vpc_id = module.networking.aws_vpc

  ingress_port = var.port_app_server

  security_groups = [
    module.security_group_alb_server.sg_id
  ]

  depends_on = [
    module.security_group_alb_server
  ]
}


# ============================================================
# CLIENT ECS TASK SECURITY GROUP
# ============================================================

module "security_group_ecs_task_client" {
  source = "./Modules/SecurityGroup"

  name = "ecs-task-${var.environment_name}-client"

  description = "Controls access to the client ECS task"

  vpc_id = module.networking.aws_vpc

  ingress_port = var.port_app_client

  security_groups = [
    module.security_group_alb_client.sg_id
  ]

  depends_on = [
    module.security_group_alb_client
  ]
}


# ============================================================
# ECS CLUSTER
# ============================================================

module "ecs_cluster" {
  source = "./Modules/ECS/Cluster"

  name = var.environment_name
}


# ============================================================
# SERVER ECS SERVICE
# ============================================================

module "ecs_service_server" {
  source = "./Modules/ECS/Service"

  name = "${var.environment_name}-server"

  desired_tasks = 1

  arn_security_group = module.security_group_ecs_task_server.sg_id

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id

  arn_target_group = module.target_group_server_blue.arn_tg

  arn_task_definition = module.ecs_taks_definition_server.arn_task_definition

  subnets_id = [
    module.networking.private_subnets_server[0],
    module.networking.private_subnets_server[1]
  ]

  container_port = var.port_app_server

  container_name = var.container_name["server"]

  depends_on = [
    module.alb_server,
    module.target_group_server_blue,
    module.ecs_taks_definition_server
  ]
}


# ============================================================
# CLIENT ECS SERVICE
# ============================================================

module "ecs_service_client" {
  source = "./Modules/ECS/Service"

  name = "${var.environment_name}-client"

  desired_tasks = 1

  arn_security_group = module.security_group_ecs_task_client.sg_id

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id

  arn_target_group = module.target_group_client_blue.arn_tg

  arn_task_definition = module.ecs_taks_definition_client.arn_task_definition

  subnets_id = [
    module.networking.private_subnets_client[0],
    module.networking.private_subnets_client[1]
  ]

  container_port = var.port_app_client

  container_name = var.container_name["client"]

  depends_on = [
    module.alb_client,
    module.target_group_client_blue,
    module.ecs_taks_definition_client
  ]
}


# ============================================================
# SERVER ECS AUTOSCALING
# ============================================================

module "ecs_autoscaling_server" {
  source = "./Modules/ECS/Autoscaling"

  name = "${var.environment_name}-server"

  cluster_name = module.ecs_cluster.ecs_cluster_name

  min_capacity = 1

  max_capacity = 4

  depends_on = [
    module.ecs_service_server
  ]
}


# ============================================================
# CLIENT ECS AUTOSCALING
# ============================================================

module "ecs_autoscaling_client" {
  source = "./Modules/ECS/Autoscaling"

  name = "${var.environment_name}-client"

  cluster_name = module.ecs_cluster.ecs_cluster_name

  min_capacity = 1

  max_capacity = 4

  depends_on = [
    module.ecs_service_client
  ]
}


# ============================================================
# CODEDEPLOY IAM ROLE
# ============================================================

module "codedeploy_role" {
  source = "./Modules/IAM"

  create_codedeploy_role = true

  name = var.iam_role_name["codedeploy"]
}


# ============================================================
# SNS
# ============================================================

module "sns" {
  source = "./Modules/SNS"

  sns_name = "sns-${var.environment_name}"
}


# ============================================================
# SERVER CODEDEPLOY
# ============================================================

module "codedeploy_server" {
  source = "./Modules/CodeDeploy"

  name = "Deploy-${var.environment_name}-server"

  ecs_cluster = module.ecs_cluster.ecs_cluster_name

  ecs_service = module.ecs_service_server.ecs_service_name

  alb_listener = module.alb_server.arn_listener

  tg_blue = module.target_group_server_blue.tg_name

  tg_green = module.target_group_server_green.tg_name

  sns_topic_arn = module.sns.sns_arn

  codedeploy_role = module.codedeploy_role.arn_role_codedeploy

  depends_on = [
    module.ecs_service_server,
    module.target_group_server_green,
    module.alb_server
  ]
}


# ============================================================
# CLIENT CODEDEPLOY
# ============================================================

module "codedeploy_client" {
  source = "./Modules/CodeDeploy"

  name = "Deploy-${var.environment_name}-client"

  ecs_cluster = module.ecs_cluster.ecs_cluster_name

  ecs_service = module.ecs_service_client.ecs_service_name

  alb_listener = module.alb_client.arn_listener

  tg_blue = module.target_group_client_blue.tg_name

  tg_green = module.target_group_client_green.tg_name

  sns_topic_arn = module.sns.sns_arn

  codedeploy_role = module.codedeploy_role.arn_role_codedeploy

  depends_on = [
    module.ecs_service_client,
    module.target_group_client_green,
    module.alb_client
  ]
}


# ============================================================
# S3 BUCKET
# ============================================================

module "s3_assets" {
  source = "./Modules/S3"

  bucket_name = "assets-${var.aws_region}-${random_id.RANDOM_ID.hex}"
}


# ============================================================
# DYNAMODB
# ============================================================

module "dynamodb_table" {
  source = "./Modules/Dynamodb"

  name = "assets-table-${var.environment_name}"
}
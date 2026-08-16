# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

/*==============================================================
      AWS Application Load Balancer + Target Groups + Listeners
===============================================================*/


# ==============================================================
# APPLICATION LOAD BALANCER
# ==============================================================

resource "aws_alb" "alb" {
  count = var.create_alb ? 1 : 0

  name               = "alb-${var.name}"
  subnets            = [var.subnets[0], var.subnets[1]]
  security_groups    = [var.security_group]
  load_balancer_type = "application"

  internal    = false
  enable_http2 = true
  idle_timeout = 30

  tags = {
    Name = "alb-${var.name}"
  }
}


# ==============================================================
# TARGET GROUP
# ==============================================================

resource "aws_alb_target_group" "target_group" {
  count = var.create_target_group ? 1 : 0

  name                 = var.name
  port                 = var.port
  protocol             = var.protocol
  vpc_id               = var.vpc
  target_type          = var.tg_type
  deregistration_delay = 5

  health_check {
    enabled             = true
    interval            = 15
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.protocol

    timeout             = 10

    healthy_threshold   = 2
    unhealthy_threshold = 3

    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.name
  }
}


# ==============================================================
# HTTP LISTENER
# ==============================================================

resource "aws_alb_listener" "http_listener" {
  count = var.create_alb ? 1 : 0

  load_balancer_arn = aws_alb.alb[0].arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = var.target_group
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }

  depends_on = [
    aws_alb.alb
  ]
}


# ==============================================================
# HTTPS LISTENER
# ==============================================================

resource "aws_alb_listener" "https_listener" {
  count = var.create_alb && var.enable_https ? 1 : 0

  load_balancer_arn = aws_alb.alb[0].arn

  port     = 443
  protocol = "HTTPS"

  default_action {
    type = "forward"

    target_group_arn = var.target_group
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }

  depends_on = [
    aws_alb.alb
  ]
}
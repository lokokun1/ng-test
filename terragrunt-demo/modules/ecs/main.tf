terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ECS IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "demo" {
  name = "${var.project}-${var.environment}-${var.cluster_name}"
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project}-${var.environment}-${var.cluster_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_ecs_task_definition" "demo_task" {
  family                   = "${var.project}-${var.environment}-${var.cluster_name}-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "demo-container"
    image     = var.container_image
    essential = true
    environment = [
      {
        name  = "BUCKET_NAME"
        value = var.bucket_name
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = var.tags
}

resource "aws_ecs_service" "demo_service" {
  name            = "${var.project}-${var.environment}-${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.demo.id
  task_definition = aws_ecs_task_definition.demo_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = var.assign_public_ip
    subnets          = var.subnets
  }

  depends_on = [
    aws_ecs_task_definition.demo_task,
    aws_cloudwatch_log_group.ecs_logs
  ]

  tags = var.tags
}

# --------------------------------------------------------------
# Outputs
# --------------------------------------------------------------
output "ecs_cluster_name" {
  value = aws_ecs_cluster.demo.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.demo_task.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.demo_service.name
}

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------
variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "region" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "assign_public_ip" {
  type    = bool
  default = true
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

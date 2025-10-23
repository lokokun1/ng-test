# ==============================================================
# modules/ecs/main.tf
# Purpose:
#   Creates an ECS Fargate cluster, task definition, and service.
#   Integrates with an S3 bucket passed from another module.
# ==============================================================

terraform {
  backend "s3" {}  # Required so Terragrunt can inject backend config

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

# --------------------------------------------------------------
# IAM Role for ECS Task Execution
# --------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecs-task-role"

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

  tags = {
    Name        = "${var.cluster_name}-ecs-task-role"
    Environment = var.environment
    ManagedBy   = "Terraform/Terragrunt"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------------------------------------------------------------
# ECS Cluster
# --------------------------------------------------------------
resource "aws_ecs_cluster" "demo" {
  name = var.cluster_name

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    ManagedBy   = "Terraform/Terragrunt"
  }
}

# --------------------------------------------------------------
# ECS Task Definition
# --------------------------------------------------------------
resource "aws_ecs_task_definition" "demo_task" {
  family                   = "${var.cluster_name}-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "demo-container"
      image     = "amazonlinux:latest"
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
          awslogs-group         = "/ecs/${var.cluster_name}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.cluster_name}-task"
    Environment = var.environment
    ManagedBy   = "Terraform/Terragrunt"
  }
}

# --------------------------------------------------------------
# ECS Service
# --------------------------------------------------------------
resource "aws_ecs_service" "demo_service" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.demo.id
  task_definition = aws_ecs_task_definition.demo_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets          = var.subnets
  }

  depends_on = [aws_ecs_task_definition.demo_task]

  tags = {
    Name        = "${var.cluster_name}-service"
    Environment = var.environment
    ManagedBy   = "Terraform/Terragrunt"
  }
}

# --------------------------------------------------------------
# Outputs
# --------------------------------------------------------------
output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.demo.name
}

output "task_definition_arn" {
  description = "The ARN of the ECS task definition"
  value       = aws_ecs_task_definition.demo_task.arn
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.demo_service.name
}

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to inject into container environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for Fargate networking"
  type        = list(string)
}

variable "environment" {
  description = "Environment label (e.g., dev, stage, prod)"
  type        = string
  default     = "dev"
}

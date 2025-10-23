# ==============================================================
# modules/ecs/main.tf
# Purpose:
#   Creates an ECS Fargate cluster, task definition, and service.
#   Integrates with an S3 bucket passed from another module.
# ==============================================================

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

# --------------------------------------------------------------
# IAM Role for ECS Task Execution
# --------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_prefix}-${var.environment}-${var.cluster_name}-task-role"

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
    Name        = "${var.project_prefix}-${var.environment}-${var.cluster_name}-task-role"
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "Terragrunt"
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
  name = "${var.project_prefix}-${var.environment}-${var.cluster_name}"

  tags = {
    Name        = "${var.project_prefix}-${var.environment}-${var.cluster_name}"
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "Terragrunt"
  }
}

# --------------------------------------------------------------
# CloudWatch Log Group for ECS Logs
# --------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_prefix}-${var.environment}-${var.cluster_name}"
  retention_in_days = 7

  tags = {
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "Terragrunt"
  }
}

# --------------------------------------------------------------
# ECS Task Definition
# --------------------------------------------------------------
resource "aws_ecs_task_definition" "demo_task" {
  family                   = "${var.project_prefix}-${var.environment}-${var.cluster_name}-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
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
    }
  ])

  tags = {
    Name        = "${var.project_prefix}-${var.environment}-${var.cluster_name}-task"
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "Terragrunt"
  }
}

# --------------------------------------------------------------
# ECS Service
# --------------------------------------------------------------
resource "aws_ecs_service" "demo_service" {
  name            = "${var.project_prefix}-${var.environment}-${var.cluster_name}-service"
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

  tags = {
    Name        = "${var.project_prefix}-${var.environment}-${var.cluster_name}-service"
    Project     = var.project_prefix
    Environment = var.environment
    ManagedBy   = "Terragrunt"
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
variable "project_prefix" {
  description = "Prefix used for naming and tagging resources"
  type        = string
}

variable "cluster_name" {
  description = "Base name of the ECS cluster"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to inject into container environment"
  type        = string
}

variable "container_image" {
  description = "Full container image (ECR or public repo)"
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

variable "desired_count" {
  description = "Number of desired ECS service tasks"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Whether to assign public IP to ECS tasks"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment label (e.g., dev, stage, prod)"
  type        = string
}

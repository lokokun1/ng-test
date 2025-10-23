terraform {
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

# -----------------------------
# IAM Role for ECS Task Execution
# -----------------------------
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
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------
# ECS Cluster
# -----------------------------
resource "aws_ecs_cluster" "demo" {
  name = var.cluster_name
}

# -----------------------------
# ECS Task Definition
# -----------------------------
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
    }
  ])
}

# -----------------------------
# ECS Service (Optional)
# -----------------------------
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
}

# -----------------------------
# Outputs
# -----------------------------
output "ecs_cluster_name" {
  value = aws_ecs_cluster.demo.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.demo_task.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.demo_service.name
}

# -----------------------------
# Variables
# -----------------------------
variable "cluster_name" {}
variable "bucket_name" {}
variable "region" {}
variable "subnets" {
  type = list(string)
}

# ==============================================================
# modules/s3/main.tf
# Purpose:
#   Creates an S3 bucket for application use.
#   This bucket is independent from the Terraform state bucket.
# ==============================================================

terraform {
  # Required for Terragrunt to inject remote state backend config
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
# S3 bucket definition
# --------------------------------------------------------------
resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.bucket_name
  force_destroy = false   # Prevent accidental deletion if non-empty

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform/Terragrunt"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "app_bucket_block" {
  bucket                  = aws_s3_bucket.app_bucket.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------------------------------------
# Outputs
# --------------------------------------------------------------
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.app_bucket.bucket
}

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------
variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "region" {
  description = "AWS region in which to create the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment label (e.g., dev, stage, prod)"
  type        = string
  default     = "dev"
}

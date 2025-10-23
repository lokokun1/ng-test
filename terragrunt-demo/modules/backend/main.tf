# ==============================================================
# modules/backend/main.tf
# Purpose:
#   Creates the S3 bucket and DynamoDB table used for
#   Terraform remote state and state locking.
# ==============================================================

terraform {
  # Required for Terragrunt to inject the remote_state backend.
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
# S3 bucket for Terraform remote state
# --------------------------------------------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket        = var.state_bucket_name
  force_destroy = false  # Prevent accidental deletions of state bucket
}

# Enable versioning (keeps history of state files)
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default AES-256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access for safety
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# --------------------------------------------------------------
# DynamoDB table for Terraform state locking
# --------------------------------------------------------------
resource "aws_dynamodb_table" "tf_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Purpose = "TerraformStateLock"
  }
}

# --------------------------------------------------------------
# Outputs
# --------------------------------------------------------------
output "state_bucket_name" {
  description = "The name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  description = "The name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tf_locks.name
}

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------
variable "region" {
  description = "AWS region where resources are created"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket to store Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

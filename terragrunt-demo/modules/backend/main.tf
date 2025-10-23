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
# S3 bucket for Terraform remote state
# --------------------------------------------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = merge(var.tags, {
    Name        = var.bucket_name
    Environment = var.environment
    Purpose     = "TerraformState"
  })
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Purpose = "TerraformStateLock"
  })
}

# --------------------------------------------------------------
# Outputs
# --------------------------------------------------------------
output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_locks.name
}

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------
variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "dynamodb_table" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

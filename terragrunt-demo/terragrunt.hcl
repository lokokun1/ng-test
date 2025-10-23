# ==============================================================
# terragrunt.hcl
# Shared Terragrunt configuration for all modules (dev/stage/prod)
#
# Responsibilities:
#   - Defines a remote S3 backend for Terraform state storage
#   - Enables DynamoDB table for state locking
#   - Provides default AWS region and reusable locals
# ==============================================================

locals {
  # Centralized AWS region (used for all environments)
  aws_region = "us-east-1"

  # Project or organization prefix used in naming
  project_prefix = "terragrunt-demo"
}

# --------------------------------------------------------------
# Remote state configuration (S3 backend + DynamoDB lock table)
# --------------------------------------------------------------
remote_state {
  backend = "s3"

  config = {
    # S3 bucket to store Terraform state files
    bucket = "${local.project_prefix}-bucket-s3"

    # Unique key for each module, based on folder path
    key = "${path_relative_to_include()}/terraform.tfstate"

    # Region where the S3 bucket and DynamoDB table exist
    region = local.aws_region

    # Encryption and state locking
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# --------------------------------------------------------------
# Default inputs inherited by all child modules
# --------------------------------------------------------------
inputs = {
  region         = local.aws_region
  project_prefix = local.project_prefix
}

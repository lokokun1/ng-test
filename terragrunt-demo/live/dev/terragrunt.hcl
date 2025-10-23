# ==============================================================
# root.hcl
# Shared Terragrunt configuration for all modules (dev/stage/prod)
#
# Responsibilities:
#   - Defines a remote S3 backend for Terraform state storage
#   - Enables DynamoDB table for state locking
#   - Provides default AWS region and reusable locals
# ==============================================================

locals {
  # Centralize AWS region here for reuse in modules and state backend
  aws_region = "us-east-1"

  # Optional prefix for environment-based naming (future-proofing)
  project_prefix = "terragrunt-demo"
}

remote_state {
  backend = "s3"

  config = {
    # ✅ S3 bucket that stores the Terraform state
    bucket         = "${local.project_prefix}-bucket-s3"

    # ✅ Unique key (path) per module
    key            = "${path_relative_to_include()}/terraform.tfstate"

    # ✅ Region where the S3 bucket & DynamoDB table exist
    region         = local.aws_region

    # ✅ Encryption and locking
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# ==============================================================
# Default variables inherited by all child modules
# ==============================================================

inputs = {
  region         = local.aws_region
  project_prefix = local.project_prefix
}

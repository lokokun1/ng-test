# ==============================================================
# live/dev/backend/terragrunt.hcl
# Purpose:
#   Creates the S3 bucket and DynamoDB table used for
#   Terraform remote state and locking.
# ==============================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/backend"
}

# --------------------------------------------------------------
# Inputs for Backend Module
# --------------------------------------------------------------
inputs = {
  # Environment for tagging and naming
  environment = "dev"

  # Bucket & DynamoDB names derived from root.hcl's project_prefix
  bucket_name     = "${local.project_prefix}-bucket-s3"
  dynamodb_table  = "terraform-locks"

  # Optional tags for management
  tags = {
    Project     = local.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

# ==============================================================
# live/dev/backend/terragrunt.hcl
# Purpose:
#   Creates the S3 bucket and DynamoDB table used for
#   Terraform remote state and locking.
# ==============================================================

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../modules/backend"
}

inputs = {
  environment    = "dev"
  bucket_name    = "${include.root.locals.project_prefix}-bucket-s3"
  dynamodb_table = "terraform-locks"

  tags = {
    Project     = include.root.locals.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

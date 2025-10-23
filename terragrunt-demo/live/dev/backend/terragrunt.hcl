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
  environment = "dev"

  # ✅ Correctly reference inherited locals via include.root.locals
  bucket_name     = "${include.root.locals.project_prefix}-bucket-s3"
  dynamodb_table  = "terraform-locks"

  # ✅ Tags fixed too
  tags = {
    Project     = include.root.locals.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

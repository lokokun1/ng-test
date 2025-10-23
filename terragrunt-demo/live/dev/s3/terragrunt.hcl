# ==============================================================
# live/dev/s3/terragrunt.hcl
# Purpose:
#   Creates an S3 bucket for application data (not for Terraform state)
# ==============================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  environment = "dev"
  bucket_name = "${include.root.locals.project_prefix}-app-bucket"

  tags = {
    Project     = include.root.locals.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

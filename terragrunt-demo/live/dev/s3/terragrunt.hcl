# ==============================================================
# live/dev/s3/terragrunt.hcl
# Purpose:
#   Deploys an example S3 bucket for application use.
# ==============================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  # ✅ Correct module path
  source = "../../../modules/s3"
}

# --------------------------------------------------------------
# Inputs for S3 module
# --------------------------------------------------------------
inputs = {
  # Logical environment
  environment = "dev"

  # Application/data bucket name (can use project prefix from root)
  bucket_name = "terragrunt-demo-dev-data-bucket"

  # Optional settings (depends on your module implementation)
  versioning = true

  # Standard tags
  tags = {
    Project     = "terragrunt-demo"
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

# ==============================================================
# live/dev/s3/terragrunt.hcl
# Purpose:
#   Creates an S3 bucket for application data (not state)
# ==============================================================

include "root" {
  path = "${get_repo_root()}/terragrunt-demo/terragrunt.hcl"
}

terraform {
  source = "../../../modules/s3"
}

# ✅ Terragrunt passes variables down to the module
inputs = {
  environment = "dev"
  bucket_name = "${include.root.locals.project_prefix}-app-bucket"

  tags = {
    Project     = include.root.locals.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

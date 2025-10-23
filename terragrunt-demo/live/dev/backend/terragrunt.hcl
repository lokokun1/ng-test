# ==============================================================
# live/dev/backend/terragrunt.hcl
# Purpose:
#   Creates the S3 bucket and DynamoDB table used for
#   Terraform remote state and locking.
# ==============================================================

include "root" {
  path   = "${get_repo_root()}/terragrunt-demo/terragrunt.hcl"
  expose = true
}

terraform {
  source = "../../../modules/backend"
}

locals {
  # Read locals from the root file
  project_prefix = include.root.locals.project_prefix
  aws_region     = include.root.locals.aws_region
}

inputs = {
  region            = local.aws_region
  state_bucket_name = "${local.project_prefix}-bucket-s3"
  lock_table_name   = "terraform-locks"

  tags = {
    Project     = local.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

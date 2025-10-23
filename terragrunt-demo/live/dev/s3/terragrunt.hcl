# ==============================================================
# live/dev/s3/terragrunt.hcl
# Purpose:
#   Deploys an example S3 bucket for application use.
# ==============================================================

include "root" {
  path   = "${get_repo_root()}/terragrunt-demo/terragrunt.hcl"
  expose = true
}

terraform {
  source = "../../../modules/s3"
}

locals {
  project_prefix = include.root.locals.project_prefix
  aws_region     = include.root.locals.aws_region
}

dependency "backend" {
  config_path = "../backend"
}

inputs = {
  region      = local.aws_region
  bucket_name = "${local.project_prefix}-data-${local.aws_region}-dev"

  tags = {
    Project     = local.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

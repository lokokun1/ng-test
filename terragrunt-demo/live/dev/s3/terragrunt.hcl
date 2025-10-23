# ==============================================================
# live/dev/s3/terragrunt.hcl
# Purpose:
#   Deploys an example S3 bucket for application use.
#   Depends on the backend (S3 + DynamoDB) being created first.
# ==============================================================

include {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  # Path to the Terraform module for the S3 bucket
  source = "../../../modules/s3"
}

# --------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------
# Make sure backend (state bucket + DynamoDB) is created first
dependency "backend" {
  config_path = "../backend"
}

# --------------------------------------------------------------
# Inputs passed to the S3 module
# --------------------------------------------------------------
inputs = {
  # AWS region (inherited from root.hcl)
  region      = "us-east-1"

  # Name of the application/data bucket
  bucket_name = "my-demo-bucket-dev"
}

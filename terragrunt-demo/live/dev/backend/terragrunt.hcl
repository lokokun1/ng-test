# ==============================================================
# live/dev/backend/terragrunt.hcl
# Purpose:
#   Creates the S3 bucket and DynamoDB table used for
#   Terraform remote state and locking.
# ==============================================================

include {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  # Source module that defines the S3 + DynamoDB resources
  source = "../../../modules/backend"
}

# --------------------------------------------------------------
# Inputs for backend module
# --------------------------------------------------------------
inputs = {
  region            = "us-east-1"

  # Name of the S3 bucket for remote Terraform state
  state_bucket_name = "my-terragrunt-demo-bucket-s3"

  # Name of the DynamoDB table for Terraform locks
  lock_table_name   = "terraform-locks"
}

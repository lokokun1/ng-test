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

inputs = {
  region            = "us-east-1"
  state_bucket_name = "my-terragrunt-demo-bucket-s3"
  lock_table_name   = "terraform-locks"
}
# ==============================================================
# root.hcl
# Shared Terragrunt configuration for all modules (dev/stage/prod)
# This defines:
#   - Remote S3 backend for Terraform state
#   - DynamoDB for state locking
#   - Default AWS region
# ==============================================================

remote_state {
  backend = "s3"
  config = {
    # S3 bucket that stores the Terraform state
    bucket         = "my-terragrunt-demo-bucket-s3"

    # Unique state file per module, based on folder path
    key            = "${path_relative_to_include()}/terraform.tfstate"

    # Must match the AWS region where your bucket + DynamoDB exist
    region         = "us-east-1"

    # Always encrypt state files
    encrypt        = true

    # DynamoDB table used for Terraform state locking
    dynamodb_table = "terraform-locks"
  }
}

# ==============================================================
# Default variables inherited by all modules
# ==============================================================

inputs = {
  region = "us-east-1"
}

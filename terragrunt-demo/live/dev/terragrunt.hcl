# ============================================================
# Root Terragrunt configuration for environment: DEV
# This file defines:
#   1. Remote state backend (S3 bucket + DynamoDB)
#   2. Common AWS provider region
#   3. Environment-wide inputs
# ============================================================

# Define where and how Terragrunt will store Terraform state
remote_state {
  backend = "s3"

  # These values configure Terraform's backend "s3" block dynamically
  config = {
    # The S3 bucket where all terraform.tfstate files are stored
    bucket         = "my-terraform-state-bucket"

    # Each folder (e.g., dev/s3, dev/ecs) gets a unique key path inside the bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"

    # The AWS region where the state bucket and DynamoDB table exist
    region         = "us-east-1"

    # Always encrypt the state file
    encrypt        = true

    # Enable DynamoDB for state locking
    dynamodb_table = "terraform-locks"
  }
}

# Define inputs or variables that will be inherited by child terragrunt.hcl files
inputs = {
  region = "us-east-1"
}

# Optional: You can add extra Terragrunt configurations like include or dependency here

# ========================================================================
# Root Terragrunt configuration
# Defines the remote backend for all environments
# ========================================================================

remote_state {
  backend = "s3"

  config = {
    bucket         = "terragrunt-demo-bucket-s3"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# No locals here — environment-specific values come from live/dev/env.hcl

# ==============================================================
# live/dev/ecs/terragrunt.hcl
# Purpose:
#   Deploys an ECS cluster and service.
#   Depends on the S3 module for shared resources.
# ==============================================================

include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  # Path to the Terraform ECS module
  source = "../../../modules/ecs"
}

# --------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------
dependency "s3" {
  config_path = "../s3"

  # Terragrunt will wait for the S3 module to finish before ECS applies
  # and automatically read its outputs.
  mock_outputs = {
    bucket_name = "placeholder-bucket"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# --------------------------------------------------------------
# Inputs for ECS module
# --------------------------------------------------------------
inputs = {
  region       = "us-east-1"

  # ECS cluster name
  cluster_name = "demo-ecs-cluster"

  # Inject S3 bucket name from dependency output
  bucket_name  = dependency.s3.outputs.bucket_name

  # Replace with your actual subnet IDs from your VPC
  subnets = [
    "subnet-0123456789abcdef0",
    "subnet-abcdef0123456789"
  ]

  # Optional tags for clarity
  environment = "dev"
}

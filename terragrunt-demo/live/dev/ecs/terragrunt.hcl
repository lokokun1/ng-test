# ==============================================================
# live/dev/ecs/terragrunt.hcl
# Purpose:
#   Deploys an ECS cluster and service.
#   Depends on the S3 module for shared resources.
# ==============================================================

include "root" {
  path = "${get_repo_root()}/terragrunt-demo/terragrunt.hcl"
}


terraform {
  # ✅ Corrected: points to ECS module (not backend)
  source = "../../../modules/ecs"
}

# --------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------
dependency "s3" {
  config_path = "../s3"

  # Terragrunt waits for S3 before applying ECS, and reads its outputs
  skip_outputs = false

  mock_outputs = {
    bucket_name = "placeholder-bucket"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# --------------------------------------------------------------
# Inputs for ECS module
# --------------------------------------------------------------
inputs = {
  # Environment info
  environment = "dev"

  # ECS cluster settings
  cluster_name    = "demo-ecs-cluster"
  desired_count   = 2

  # Inject S3 bucket name from dependency output
  bucket_name     = dependency.s3.outputs.bucket_name

  # Replace with your actual subnet IDs from your VPC
  subnets = [
    "subnet-0123456789abcdef0",
    "subnet-abcdef0123456789"
  ]

  # Example container image from your ECR
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/demo-ecs:latest"

  # Standard tags (always good practice)
  tags = {
    Project     = "terragrunt-demo"
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

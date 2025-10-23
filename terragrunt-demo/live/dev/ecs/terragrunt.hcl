# ==============================================================
# live/dev/ecs/terragrunt.hcl
# Purpose:
#   Deploys an ECS cluster and service.
# ==============================================================

include "root" {
  path   = "${get_repo_root()}/terragrunt-demo/terragrunt.hcl"
  expose = true
}

terraform {
  source = "../../../modules/ecs"
}

locals {
  project_prefix = include.root.locals.project_prefix
  aws_region     = include.root.locals.aws_region
}

dependency "s3" {
  config_path = "../s3"

  mock_outputs = {
    bucket_name = "placeholder-bucket"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  region       = local.aws_region
  cluster_name = "${local.project_prefix}-dev-ecs-cluster"
  bucket_name  = dependency.s3.outputs.bucket_name
  subnets      = [
    "subnet-0123456789abcdef0",
    "subnet-abcdef0123456789"
  ]

  tags = {
    Project     = local.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

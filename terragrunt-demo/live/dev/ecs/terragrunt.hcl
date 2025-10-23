include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecs"
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  common_tags = read_terragrunt_config(find_in_parent_folders("common_tags.hcl")).locals

  env     = local.env_vars.env
  project = local.env_vars.project_name
  region  = local.env_vars.region

  tags = merge(local.common_tags.common_tags, {
    Environment = local.env
    Project     = local.project
  })
}

inputs = {
  environment     = local.env
  region          = local.region
  project         = local.project
  cluster_name    = "ecs-${local.env}"
  bucket_name     = "${local.project}-app-bucket"
  container_image = "nginx:latest" # ✅ example placeholder
  subnets         = ["subnet-xxxxxxxxxxxxx", "subnet-yyyyyyyyyyyy"] # ✅ replace with your actual subnets
  desired_count   = 1
  assign_public_ip = true
  tags            = local.tags
}

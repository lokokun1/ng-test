# ========================================================================
# ECS Terragrunt configuration
# Reads environment, tags, and VPC subnet info from shared .hcl files
# ========================================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecs"
}

locals {
  # --------------------------------------------------------------
  # Load shared configuration files
  # --------------------------------------------------------------
  env_vars    = (read_terragrunt_config(find_in_parent_folders("env.hcl"))).locals
  common_tags = (read_terragrunt_config(find_in_parent_folders("common_tags.hcl"))).locals
  vpc_vars    = (read_terragrunt_config(find_in_parent_folders("vpc.hcl"))).locals

  # --------------------------------------------------------------
  # Derived locals
  # --------------------------------------------------------------
  env      = local.env_vars.env
  project  = local.env_vars.project_name
  region   = local.env_vars.region
  subnets  = local.vpc_vars.subnets

  tags = merge(local.common_tags.common_tags, {
    Environment = local.env
    Project     = local.project
  })
}

# --------------------------------------------------------------
# ECS module inputs
# --------------------------------------------------------------
inputs = {
  environment    = local.env
  cluster_name   = "ecs-${local.env}"
  region         = local.region
  subnets        = local.subnets
  tags           = local.tags

  # --- Required ECS variables ---
  project         = local.project
  bucket_name     = "${local.project}-app-bucket"
  container_image = "nginx:2026"

  # Optional
  desired_count    = 1
  assign_public_ip = true
}

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecs"
}

locals {
  env_vars    = (read_terragrunt_config(find_in_parent_folders("env.hcl"))).locals
  common_tags = (read_terragrunt_config(find_in_parent_folders("common_tags.hcl"))).locals

  env     = local.env_vars.env
  project = local.env_vars.project_name
  region  = local.env_vars.region

  tags = merge(local.common_tags.common_tags, {
    Environment = local.env
    Project     = local.project
  })
}

inputs = {
  environment = local.env
  cluster_name = "ecs-${local.env}"
  region       = local.region
  tags         = local.tags
}

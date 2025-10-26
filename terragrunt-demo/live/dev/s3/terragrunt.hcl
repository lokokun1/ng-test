include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

locals {
  env_vars    = (read_terragrunt_config(find_in_parent_folders("env.hcl"))).locals
  common_tags = (read_terragrunt_config(find_in_parent_folders("common_tags.hcl"))).locals
  vpc_vars    = (read_terragrunt_config(find_in_parent_folders("vpc.hcl"))).locals

  env     = local.env_vars.env
  project = local.env_vars.project_name
  region  = local.env_vars.region
  subnets = local.vpc_vars.subnets

  tags = merge(local.common_tags.common_tags, {
    Environment = local.env
    Project     = local.project
  })
}


inputs = {
  environment = local.env
  bucket_name = "${local.project}-app-bucket"
  region      = local.region
  subnets       = local.subnets
  tags        = local.tags
}

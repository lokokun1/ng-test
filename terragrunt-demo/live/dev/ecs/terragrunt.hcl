include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecs"
}

inputs = {
  environment   = "dev"
  cluster_name  = "${include.root.locals.project_prefix}-dev-cluster"

  tags = {
    Project     = include.root.locals.project_prefix
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

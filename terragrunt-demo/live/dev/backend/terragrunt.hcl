include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/backend"
}

inputs = {
  environment    = "dev"
  dynamodb_table = "terraform-locks"
  }

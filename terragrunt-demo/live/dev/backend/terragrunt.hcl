include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/backend"
}

inputs = {
  environment    = "dev"
  bucket_name    = "${include.root.locals.project_prefix}-bucket-s3"
  dynamodb_table = "terraform-locks"
  }

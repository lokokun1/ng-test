terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name = "my-terragrunt-demo-bucket-${basename(get_terragrunt_dir())}"
  region      = "us-east-1"
}

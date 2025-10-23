remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terragrunt-demo-bucket-s3"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}


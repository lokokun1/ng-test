remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terragrunt-demo-bucket-s3"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # Temporarily comment out the lock table until it's created
    # dynamodb_table = "terraform-locks"
  }
}

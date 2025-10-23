include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecs"
}

# Declare dependency on the S3 bucket
dependency "s3" {
  config_path = "../s3"
}

inputs = {
  region       = "us-east-1"
  cluster_name = "demo-ecs-cluster"
  bucket_name  = dependency.s3.outputs.bucket_name

  # replace with your actual subnet IDs in your VPC
  subnets = [
    "subnet-0123456789abcdef0",
    "subnet-abcdef0123456789"
  ]
}

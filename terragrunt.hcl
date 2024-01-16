remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "cloudbees-infra-tf-state"

    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cloudbees-infra-tf-state-lock"
  }
}

inputs = {
  aws-user-name = "infra-guide-rails"
}
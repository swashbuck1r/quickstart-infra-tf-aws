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
  region = "us-east-1"
  eks_cluster_name = "cloudbees-quickstart"
  
  eks_endpoint_public_access_cidrs = [
    "100.21.184.186/32", # CB Platform US-WEST
    "54.236.193.143/32", # CB Platform US-EAST
    "52.86.39.231/32",   # AWS OpenVPN external
    "34.200.9.247/32",   # AWS OpenVPN external
    "34.73.99.37/32",    # GCP OpenVPN external primary
    "34.73.18.111/32"    # GCP OpenVPN external secondary
  ]

  admin_role_name = "AWSReservedSSO_infra-admin_19ffd3b99ad3940b"
}
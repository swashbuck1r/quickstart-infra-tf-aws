include "root" {
  path = find_in_parent_folders()
}

dependency "eks_cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_name             = "dummy_cluster_name"
    oidc_provider_arn        = "dummy_oidc_provider_arn"
    node_group_iam_role_arns = ["dummy_node_group_iam_role_arn"]
  }
}

inputs = {
  cluster_name             = dependency.eks_cluster.outputs.cluster_name
  oidc_provider_arn        = dependency.eks_cluster.outputs.oidc_provider_arn
  node_group_iam_role_arns = dependency.eks_cluster.outputs.node_group_iam_role_arns
}
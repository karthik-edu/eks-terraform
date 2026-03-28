output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "EKS cluster IAM role name"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "EKS node group IAM role ARN"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "EKS node group IAM role name"
  value       = aws_iam_role.node_group.name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "service_account_assume_role_policy" {
  description = "Assume role policy for service account (for IRSA)"
  value       = data.aws_iam_policy_document.service_account_assume_role.json
}

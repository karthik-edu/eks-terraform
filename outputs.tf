################################################################################
# VPC Outputs
################################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

################################################################################
# Security Group Outputs
################################################################################
output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.security.cluster_security_group_id
}

output "node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.security.node_security_group_id
}

################################################################################
# EKS Cluster Outputs
################################################################################
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks_cluster.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks_cluster.cluster_platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.eks_cluster.cluster_status
}

################################################################################
# Node Group Outputs
################################################################################
output "node_group_id" {
  description = "EKS node group ID"
  value       = module.node_group.node_group_id
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = module.node_group.node_group_arn
}

output "node_group_status" {
  description = "EKS node group status"
  value       = module.node_group.node_group_status
}

################################################################################
# Kubeconfig Configuration
################################################################################
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_cluster.cluster_name}"
}

output "kubeconfig" {
  description = "Kubeconfig for kubectl"
  value = {
    apiVersion = "client.authentication.k8s.io/v1beta1"
    kind       = "ExecConfig"
    command    = "aws"
    args       = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name, "--region", var.aws_region]
  }
  sensitive = true
}

################################################################################
# EKS Cluster
################################################################################
resource "aws_eks_cluster" "main" {
  name    = var.cluster_name
  role_arn    = var.cluster_iam_role_arn
  version     = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  # Enable control plane logging
  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(
    var.base_tags,
    {
      Name = "${var.cluster_name_prefix}-eks-cluster"
    }
  )

  depends_on = [var.cluster_iam_role_arn]
}

################################################################################
# CloudWatch Log Group for EKS Cluster Logs
################################################################################
resource "aws_cloudwatch_log_group" "cluster" {
  count             = length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${aws_eks_cluster.main.name}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.base_tags,
    {
      Name = "${var.cluster_name_prefix}-eks-logs"
    }
  )
}

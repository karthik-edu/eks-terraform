################################################################################
# EKS Cluster IAM Role
################################################################################
resource "aws_iam_role" "cluster" {
  name_prefix = "${var.name_prefix}-cluster-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-cluster-role"
    }
  )
}

# Attach EKS cluster policy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach EKS VPC resource controller policy
resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

################################################################################
# EKS Node Group IAM Role
################################################################################
resource "aws_iam_role" "node_group" {
  name_prefix = "${var.name_prefix}-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-node-role"
    }
  )
}

# Attach EKS worker node policy
resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach EKS CNI policy
resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach ECR container registry policy
resource "aws_iam_role_policy_attachment" "node_group_ecr_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach EC2 SSM policy (for Systems Manager access)
resource "aws_iam_role_policy_attachment" "node_group_ssm_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach EBS CSI policy (for persistent volumes)
resource "aws_iam_role_policy_attachment" "node_group_ebs_csi_policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

################################################################################
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
################################################################################
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_provider_thumbprint]
  url             = var.cluster_oidc_issuer_url

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-irsa-provider"
    }
  )
}

################################################################################
# Service Account Assume Role Policy Document (for IRSA)
################################################################################
# This can be used by Kubernetes service accounts to assume IAM roles
data "aws_iam_policy_document" "service_account_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

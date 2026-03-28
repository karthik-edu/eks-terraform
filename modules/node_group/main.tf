################################################################################
# EKS Node Group
################################################################################
resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name_prefix}-node-group"
  node_role_arn   = var.node_group_iam_role_arn
  subnet_ids      = var.private_subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Update strategy
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # Capacity type (ON_DEMAND or SPOT)
  capacity_type = var.capacity_type

  # Instance types
  instance_types = var.instance_types

  # Disk size in GB
  disk_size = var.disk_size

  # Remote access configuration
  dynamic "remote_access" {
    for_each = var.enable_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.ec2_ssh_key_name
      source_security_group_ids = var.source_security_group_ids
    }
  }

  # Labels
  labels = var.labels

  # Taints
  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.base_tags,
    {
      Name = "${var.cluster_name_prefix}-node-group"
    }
  )

  # Ensure proper order of operations
  depends_on = [
    var.node_group_iam_role_arn
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

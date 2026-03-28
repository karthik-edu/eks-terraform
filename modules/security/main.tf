################################################################################
# EKS Cluster Security Group
################################################################################
resource "aws_security_group" "cluster" {
  name_prefix = "${var.name_prefix}-cluster-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster"

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-cluster-sg"
    }
  )
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "cluster_all_outbound" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "all-outbound"
  }
}

################################################################################
# EKS Node Security Group
################################################################################
resource "aws_security_group" "node" {
  name_prefix = "${var.name_prefix}-node-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS nodes"

  tags = merge(
    var.base_tags,
    {
      Name = "${var.name_prefix}-node-sg"
    }
  )
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "node_all_outbound" {
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "all-outbound"
  }
}

################################################################################
# Node to Cluster Communication
################################################################################
# Allow nodes to communicate with cluster API
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow nodes to communicate with cluster API"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.node.id

  tags = {
    Name = "node-to-cluster"
  }
}

################################################################################
# Cluster to Node Communication
################################################################################
# Allow cluster to node kubelet API
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster" {
  security_group_id = aws_security_group.node.id
  description       = "Allow cluster to nodes for kubelet API"
  from_port         = 10250
  to_port           = 10250
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id

  tags = {
    Name = "cluster-to-node"
  }
}

################################################################################
# Node to Node Communication
################################################################################
# Allow nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "node_from_node" {
  security_group_id = aws_security_group.node.id
  description       = "Allow node-to-node communication"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.node.id

  tags = {
    Name = "node-to-node"
  }
}

################################################################################
# Pod to Pod Communication (CNI)
################################################################################
# Allow pods to communicate via CNI plugin
resource "aws_vpc_security_group_ingress_rule" "node_from_pod" {
  security_group_id = aws_security_group.node.id
  description       = "Allow pod-to-pod communication via CNI"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "-1"
  referenced_security_group_id = aws_security_group.node.id

  tags = {
    Name = "pod-to-pod"
  }
}

################################################################################
# Optional: SSH Access to Nodes
################################################################################
resource "aws_vpc_security_group_ingress_rule" "node_ssh" {
  count             = var.enable_ssh_access ? 1 : 0
  security_group_id = aws_security_group.node.id
  description       = "Allow SSH access to nodes"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.ssh_cidr_block

  tags = {
    Name = "ssh"
  }
}

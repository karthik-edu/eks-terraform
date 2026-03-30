################################################################################
# VPC Module
################################################################################
module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  base_tags            = local.base_tags
  vpc_cidr_block       = var.vpc_cidr_block
  private_subnet_count = var.private_subnet_count
  public_subnet_count  = var.public_subnet_count
  availability_zones   = local.availability_zones
}

################################################################################
# Security Group Module
################################################################################
module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  base_tags         = local.base_tags
  vpc_id            = module.vpc.vpc_id
  enable_ssh_access = var.enable_node_ssh
  ssh_cidr_block    = var.node_ssh_cidr
}

################################################################################
# IAM Module
################################################################################
module "iam" {
  source = "./modules/iam"

  name_prefix              = local.name_prefix
  base_tags                = local.base_tags
  cluster_oidc_issuer_url  = module.eks_cluster.cluster_oidc_issuer_url
  oidc_provider_thumbprint = data.tls_certificate.cluster.certificates[0].sha1_fingerprint
}

################################################################################
# EKS Cluster Module
################################################################################
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name              = "${local.name_prefix}-${var.cluster_name}"
  cluster_name_prefix       = local.name_prefix
  base_tags                 = local.base_tags
  kubernetes_version        = var.kubernetes_version
  cluster_iam_role_arn      = module.iam.cluster_iam_role_arn
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  cluster_security_group_id = module.security.cluster_security_group_id
  endpoint_private_access   = var.endpoint_private_access
  endpoint_public_access    = var.endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  enabled_cluster_log_types = var.enabled_cluster_log_types
  log_retention_days        = var.log_retention_days
}

################################################################################
# EKS Node Group Module
################################################################################
module "node_group" {
  source = "./modules/node_group"

  cluster_name              = module.eks_cluster.cluster_name
  cluster_name_prefix       = local.name_prefix
  base_tags                 = local.base_tags
  node_group_iam_role_arn   = module.iam.node_group_iam_role_arn
  private_subnet_ids        = module.vpc.private_subnet_ids
  kubernetes_version        = var.kubernetes_version
  desired_size              = var.node_desired_size
  min_size                  = var.node_min_size
  max_size                  = var.node_max_size
  capacity_type             = var.node_capacity_type
  instance_types            = var.node_instance_types
  disk_size                 = var.node_disk_size
  enable_remote_access      = var.enable_node_remote_access
  ec2_ssh_key_name          = var.node_ssh_key_name
  source_security_group_ids = [module.security.node_security_group_id]
  labels                    = var.node_labels
}

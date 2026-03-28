################################################################################
# Get available AZs
################################################################################
data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# Get OIDC thumbprint for EKS cluster IRSA
################################################################################
data "tls_certificate" "cluster" {
  url = module.eks_cluster.cluster_oidc_issuer_url
}

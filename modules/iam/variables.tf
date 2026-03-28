variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "base_tags" {
  description = "Base tags for all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  type        = string
}

variable "oidc_provider_thumbprint" {
  description = "OIDC provider thumbprint"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for service account"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "default"
}

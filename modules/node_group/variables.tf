variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "base_tags" {
  description = "Base tags for all resources"
  type        = map(string)
  default     = {}
}

variable "node_group_iam_role_arn" {
  description = "IAM role ARN for node group"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for node group"
  type        = string
  default     = "1.28"
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 33
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "instance_types" {
  description = "List of EC2 instance types for nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Disk size in GB for node root volume"
  type        = number
  default     = 20
}

variable "enable_remote_access" {
  description = "Enable remote access to nodes"
  type        = bool
  default     = false
}

variable "ec2_ssh_key_name" {
  description = "EC2 SSH key name for remote access"
  type        = string
  default     = ""
}

variable "source_security_group_ids" {
  description = "Security group IDs for remote access"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Kubernetes labels for node group"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints for node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

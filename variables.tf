################################################################################
# AWS Configuration
################################################################################
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
  sensitive   = true
}

################################################################################
# Project Configuration
################################################################################
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myproject"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric and hyphens, 1-20 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

################################################################################
# VPC Configuration
################################################################################
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be valid CIDR notation."
  }
}

variable "availability_zone_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 1 && var.availability_zone_count <= 4
    error_message = "Availability zone count must be between 1 and 4."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 1
    error_message = "Private subnet count must be at least 1."
  }
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2

  validation {
    condition     = var.public_subnet_count >= 1
    error_message = "Public subnet count must be at least 1."
  }
}

################################################################################
# EKS Cluster Configuration
################################################################################
variable "cluster_name" {
  description = "EKS cluster name prefix"
  type        = string
  default     = "eks"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,37}$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric and hyphens, 1-37 characters."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks for public API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit"]

  validation {
    condition     = alltrue([for log_type in var.enabled_cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)])
    error_message = "Invalid log type. Valid types: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

################################################################################
# Node Group Configuration
################################################################################
variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "Desired node size must be at least 1."
  }
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "Minimum node size must be at least 1."
  }
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4

  validation {
    condition     = var.node_max_size >= var.node_min_size
    error_message = "Maximum node size must be >= minimum node size."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Disk size in GB for node root volume"
  type        = number
  default     = 30

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "Node disk size must be at least 20 GB."
  }
}

variable "node_labels" {
  description = "Kubernetes labels for node group"
  type        = map(string)
  default     = {}
}

################################################################################
# Security Configuration
################################################################################
variable "enable_node_remote_access" {
  description = "Enable remote access to nodes"
  type        = bool
  default     = false
}

variable "node_ssh_key_name" {
  description = "EC2 SSH key name for node remote access"
  type        = string
  default     = ""
}

variable "enable_node_ssh" {
  description = "Enable SSH access to nodes"
  type        = bool
  default     = false
}

variable "node_ssh_cidr" {
  description = "CIDR block for SSH access to nodes"
  type        = string
  default     = "10.0.0.0/8"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "base_tags" {
  description = "Base tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "enable_ssh_access" {
  description = "Enable SSH access to nodes"
  type        = bool
  default     = false
}

variable "ssh_cidr_block" {
  description = "CIDR block for SSH access"
  type        = string
  default     = "10.0.0.0/8"
}

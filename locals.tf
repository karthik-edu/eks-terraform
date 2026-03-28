locals {
  # Environment configuration
  environment = var.environment
  project     = var.project_name

  # Computed naming convention
  name_prefix = "${local.project}-${local.environment}"

  # Merge base tags with all resources
  base_tags = merge(
    var.common_tags,
    {
      Project     = local.project
      Environment = local.environment
      CreatedBy   = "Terraform"
      ManagedBy   = "Terraform"
    }
  )

  # Availability zones for multi-AZ deployment
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    min(var.availability_zone_count, length(data.aws_availability_zones.available.names))
  )
}

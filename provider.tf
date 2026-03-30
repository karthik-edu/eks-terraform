provider "aws" {
  region  = var.aws_region
 #profile = var.aws_profile

  default_tags {
    tags = local.base_tags
  }
}

provider "tls" {}

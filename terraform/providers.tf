# ============================================================
# Provider Configuration
# Tells Terraform to use the AWS provider
# ============================================================

provider "aws" {
  region = var.aws_region

  # These tags will be applied to EVERY resource automatically
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}

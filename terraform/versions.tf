# ============================================================
# Version Constraints
# Lock Terraform and provider versions for reproducibility
# ============================================================

terraform {
  # Must use Terraform 1.5 or higher
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # Use AWS provider 5.x (don't jump to 6.x automatically)
    }
  }
}

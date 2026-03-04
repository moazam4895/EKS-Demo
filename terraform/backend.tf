# ============================================================
# Dev Environment: Terraform Remote State Backend
# Replace YOUR_ACCOUNT_ID with your actual AWS account ID
# ============================================================

terraform {
  backend "s3" {
    bucket         = "eks-demo-terraform-state-dev-935803162418"  # ← from bootstrap
    key            = "eks-demo/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-demo-terraform-locks-dev"                   # ← from bootstrap
    encrypt        = true  # Encrypt state at rest
  }
}

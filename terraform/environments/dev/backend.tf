cat > terraform/environments/dev/backend.tf << 'ENDOFFILE'
terraform {
  backend "s3" {
    bucket         = "eks-demo-terraform-state-dev-935803162418"
    key            = "eks-demo/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-demo-terraform-locks-dev"
    encrypt        = true
  }
}
ENDOFFILE

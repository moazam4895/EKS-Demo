terraform {
  backend "s3" {
    bucket         = "eks-demo-terraform-state-prod-935803162418"
    key            = "eks-demo/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-demo-terraform-locks-prod"
    encrypt        = true
  }
}

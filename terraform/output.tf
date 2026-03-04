# ============================================================
# Root Outputs — printed after apply
# ============================================================

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "github_actions_role_arn" {
  description = "GitHub Actions IAM Role ARN — add this to GitHub Secrets"
  value       = module.iam.github_actions_role_arn
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

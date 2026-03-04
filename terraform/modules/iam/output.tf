output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role — put this in GitHub secrets"
  value       = aws_iam_role.github_actions.arn
}

# ============================================================
# EKS Module Outputs
# ============================================================

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data for cluster auth"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC provider URL (used for IAM Roles for Service Accounts)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_group_id" {
  description = "ID of the managed node group"
  value       = aws_eks_node_group.main.id
}

# ============================================================
# Variables for the EKS module
# ============================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for EKS control plane ENIs"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM Role ARN for EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "IAM Role ARN for EKS node group"
  type        = string
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

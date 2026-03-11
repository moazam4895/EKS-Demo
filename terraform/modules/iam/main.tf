# ============================================================
# IAM Module
# Creates roles and policies for EKS cluster and node group
# ============================================================

# ==============================
# EKS CLUSTER ROLE
# ==============================
# This role is assumed BY the EKS control plane to manage AWS resources
# (like creating load balancers, security groups, etc.)

# Data source: trust policy that allows EKS service to assume this role
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]  # EKS service can assume this role
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-role"
  })
}

# Attach the managed AWS policy that grants EKS all the permissions it needs
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Allows EKS to manage VPC resources (security groups, ENIs)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ==============================
# EKS NODE GROUP ROLE
# ==============================
# This role is assumed BY the EC2 worker nodes
# Allows nodes to join the cluster and pull ECR images

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # EC2 (nodes) can assume this role
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_node_group" {
  name               = "${var.project_name}-${var.environment}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-node-role"
  })
}

# Worker node needs these 3 policies to function:
# 1. EKSWorkerNodePolicy — allows node to register with cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# 2. EKS_CNI_Policy — allows vpc-cni plugin to manage network interfaces
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# 3. EC2ContainerRegistryReadOnly — allows pulling Docker images from ECR
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ==============================
# GITHUB ACTIONS OIDC ROLE
# ==============================
# This allows GitHub Actions to assume an AWS role WITHOUT static credentials
# It uses OpenID Connect (OIDC) — GitHub proves identity via a JWT token

data "aws_caller_identity" "current" {}

# Create the OIDC provider in AWS (GitHub's public OIDC)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint (you can verify this at https://github.com/.well-known/openid-configuration)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policy: only tokens from YOUR GitHub repo can assume this role
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Conditions restrict which GitHub Actions workflow can assume this role
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      # IMPORTANT: Change this to your GitHub username/repo
      # The "ref:refs/heads/main" part restricts to the main branch only
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:moazam4895/EKS-Demo:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-${var.environment}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-github-actions-role"
  })
}

# Inline policy for GitHub Actions — least privilege
# Only what is needed to manage EKS infrastructure
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-eks-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
            "Action": [
                "eks:*",
                "ec2:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:PassRole",
                "iam:TagRole",
                "iam:UntagRole",
                "iam:ListInstanceProfilesForRole",
                "iam:CreateServiceLinkedRole",
                "iam:DeleteServiceLinkedRole",
                "iam:GetServiceLinkedRoleDeletionStatus",
                "iam:CreateOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:ListOpenIDConnectProviders",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetEncryptionConfiguration",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:DescribeTable",
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "logs:DeleteLogGroup",
                "logs:TagResource",
                "logs:ListTagsForResource",
                "logs:ListTagsLogGroup",
                "logs:CreateLogDelivery",
                "logs:PutLogEvents"
            ],        
	Resource = "*"
      }
    ]
  })
}

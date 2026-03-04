# ============================================================
# EKS Module
# Creates: EKS Cluster, Managed Node Group, Security Groups,
#          CloudWatch Logging, and EKS Add-ons
# ============================================================

# --- Security Group for EKS Cluster ---
# Controls network traffic to the EKS API server (control plane)
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic from the control plane
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"         # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  })
}

# --- Security Group for Worker Nodes ---
resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow nodes to communicate with each other
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true  # allows traffic between nodes in this SG
  }

  # Allow control plane to talk to nodes (kubelet, metrics)
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  # Allow all outbound (nodes need to pull images, contact AWS APIs, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  })
}

# --- Allow nodes to talk to cluster control plane ---
resource "aws_security_group_rule" "nodes_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.nodes.id
  description              = "Allow worker nodes to communicate with cluster API"
}

# --- CloudWatch Log Group for EKS ---
# Stores cluster logs (API server, audit, scheduler, etc.)
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-${var.environment}/cluster"
  retention_in_days = 7  # Keep logs for 7 days (cost control)

  tags = var.tags
}

# --- EKS Cluster ---
# This is the Kubernetes control plane (managed by AWS)
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  # Network config: tells EKS which subnets and SG to use
  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true   # Nodes can reach API via private network
    endpoint_public_access  = true   # You can reach API from your laptop
  }

  # Enable various logging types to CloudWatch
  enabled_cluster_log_types = [
    "api",            # API server logs
    "audit",          # Audit logs (who did what)
    "authenticator",  # Authentication logs
    "controllerManager",
    "scheduler"
  ]

  # Ensure CloudWatch log group exists before cluster tries to log
  depends_on = [
    aws_cloudwatch_log_group.eks,
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# --- EKS Managed Node Group ---
# These are the EC2 instances (worker nodes) that run your Pods
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = var.node_role_arn

  # Worker nodes go in PRIVATE subnets (never expose workers directly)
  subnet_ids = var.private_subnet_ids

  # Instance configuration
  instance_types = var.instance_types
  ami_type       = "AL2_x86_64"   # Amazon Linux 2 — standard for EKS
  capacity_type  = "ON_DEMAND"    # Change to "SPOT" to save 60-70% (less reliable)

  # Disk configuration
  disk_size = 20  # GB for the OS disk on each node

  # Auto-scaling settings
  scaling_config {
    desired_size = var.node_desired_size  # Start with this many nodes
    min_size     = var.node_min_size      # Scale down no further than this
    max_size     = var.node_max_size      # Scale up no further than this
  }

  # Rolling update strategy
  update_config {
    max_unavailable = 1  # Only take 1 node offline at a time during updates
  }

  # Node group needs the cluster to exist first
  depends_on = [
    aws_eks_cluster.main,
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-node-group"
  })

  # Lifecycle: Allow external auto-scaling to change desired count without Terraform reverting it
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ============================================================
# EKS Add-ons
# Add-ons are extra functionality managed by AWS:
# - vpc-cni: networking between pods
# - coredns: DNS for service discovery
# - kube-proxy: network rules on each node
# ============================================================

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# ============================================================
# Development Environment Values
# ============================================================

project_name = "eks-demo"
environment  = "dev"
owner        = "platform-team"
aws_region   = "us-east-1"
vpc_cidr     = "10.0.0.0/16"

kubernetes_version = "1.29"
instance_types     = ["t2.micro"]

# Smaller footprint for dev
node_desired_size = 2
node_min_size     = 1
node_max_size     = 3

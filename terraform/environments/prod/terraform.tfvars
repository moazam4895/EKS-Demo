# ============================================================
# Production Environment Values
# ============================================================

project_name = "eks-demo"
environment  = "prod"
owner        = "platform-team"
aws_region   = "us-east-1"
vpc_cidr     = "10.1.0.0/16"  # Different CIDR from dev

kubernetes_version = "1.29"
instance_types     = ["t2.micro"]   # Bigger instances for prod

# Larger footprint for prod
node_desired_size = 3
node_min_size     = 2
node_max_size     = 10

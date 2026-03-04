# ============================================================
# Root Module — Orchestrates all sub-modules
# ============================================================

# Get list of available AZs in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values: computed values used throughout
locals {
  # Use first 3 AZs in the region
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Build subnet CIDRs dynamically
  public_subnet_cidrs  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnet_cidrs = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 11)]

  # Common tags applied to all resources via the module
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# ── IAM module ──
# Create all IAM roles first (other modules need the role ARNs)
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# ── Networking module ──
module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.azs
  tags                 = local.common_tags
}

# ── EKS module ──
module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.kubernetes_version

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  cluster_role_arn  = module.iam.eks_cluster_role_arn
  node_role_arn     = module.iam.eks_node_role_arn

  instance_types    = var.instance_types
  node_desired_size = var.node_desired_size
  node_min_size     = var.node_min_size
  node_max_size     = var.node_max_size

  tags = local.common_tags

  # EKS needs IAM roles to exist before it can be created
  depends_on = [module.iam]
}

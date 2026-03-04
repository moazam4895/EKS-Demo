# ============================================================
# Networking Module
# Creates: VPC, Public & Private Subnets, IGW, NAT, Routes
# ============================================================

# --- VPC ---
# The VPC is your private network in AWS. All resources live inside it.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true   # Allows AWS DNS resolution inside VPC
  enable_dns_hostnames = true   # Gives EC2 instances DNS names

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
    # EKS requires these specific tags on the VPC
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  })
}

# --- Public Subnets ---
# Public subnets have a route to the Internet Gateway.
# We create one per Availability Zone for high availability.
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Instances in public subnets get a public IP automatically
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    # EKS uses this tag to know it can create public load balancers here
    "kubernetes.io/role/elb"                                          = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}"    = "shared"
  })
}

# --- Private Subnets ---
# Private subnets have NO direct internet route.
# EKS worker nodes go here — they access internet through NAT Gateway.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false  # No public IPs — they use NAT

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    # EKS uses this tag to know it can create internal load balancers here
    "kubernetes.io/role/internal-elb"                                  = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}"     = "shared"
  })
}

# --- Internet Gateway ---
# The IGW is the "door" between your VPC and the public internet.
# Public subnets route traffic through this.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# --- Elastic IPs for NAT Gateways ---
# A NAT Gateway needs a static public IP address (Elastic IP).
# We create one EIP per NAT Gateway (one per AZ for HA).
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  # EIP must be created AFTER the IGW
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

# --- NAT Gateways ---
# NAT Gateways allow private subnet resources (EKS nodes) to reach
# the internet (for updates, pulling Docker images) without being
# directly reachable from the internet.
resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id  # NAT lives in PUBLIC subnet!

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
  })
}

# --- Public Route Table ---
# Routes traffic from public subnets to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                  # All internet traffic
    gateway_id = aws_internet_gateway.main.id  # Goes through IGW
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Tables ---
# One per AZ — each routes to its own NAT Gateway for high availability
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"                          # All internet traffic
    nat_gateway_id = aws_nat_gateway.main[count.index].id # Goes through NAT
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  })
}

# Associate each private subnet with its private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

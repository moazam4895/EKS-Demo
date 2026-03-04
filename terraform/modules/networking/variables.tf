# ============================================================
# Variables for the Networking module
# ============================================================

variable "project_name" {
  description = "Name of the project - used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Example: 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

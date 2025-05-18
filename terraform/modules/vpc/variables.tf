# ==============================================================================
# VPCモジュール - 入力変数
# ==============================================================================

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "azs_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
  
  validation {
    condition = var.azs_count >= 2 && var.azs_count <= 4
    error_message = "AZs count must be between 2 and 4."
  }
}

# ==============================================================================
# DNS設定
# ==============================================================================

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# ==============================================================================
# NAT Gateway設定
# ==============================================================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = false
}

# ==============================================================================
# サブネット設定
# ==============================================================================

variable "create_database_subnets" {
  description = "Create database subnets"
  type        = bool
  default     = false
}

variable "create_elasticache_subnets" {
  description = "Create ElastiCache subnets"
  type        = bool
  default     = false
}

# ==============================================================================
# VPCエンドポイント設定
# ==============================================================================

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_endpoint" {
  description = "Enable ECR VPC Endpoints"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs VPC Endpoint"
  type        = bool
  default     = true
}

variable "enable_monitoring_endpoint" {
  description = "Enable CloudWatch Monitoring VPC Endpoint"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoint" {
  description = "Enable Systems Manager VPC Endpoints"
  type        = bool
  default     = false
}

# ==============================================================================
# セキュリティ設定
# ==============================================================================

variable "enable_dhcp_options" {
  description = "Enable custom DHCP options"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

# ==============================================================================
# ネットワークACL設定
# ==============================================================================

variable "manage_default_network_acl" {
  description = "Manage default network ACL"
  type        = bool
  default     = true
}

variable "default_network_acl_deny_all" {
  description = "Deny all traffic in default network ACL"
  type        = bool
  default     = false
}

# ==============================================================================
# フローログ設定
# ==============================================================================

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_log_destination_type" {
  description = "Type of destination for VPC Flow Logs (cloud-watch-logs, s3)"
  type        = string
  default     = "cloud-watch-logs"
  
  validation {
    condition = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_destination_arn" {
  description = "ARN of destination for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "vpc_flow_log_permissions_boundary" {
  description = "ARN of permissions boundary for VPC Flow Log IAM role"
  type        = string
  default     = null
}

# ==============================================================================
# タグ設定
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for the Internet Gateway"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Additional tags for NAT EIPs"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# 高度な設定
# ==============================================================================

variable "instance_tenancy" {
  description = "Instance tenancy option for the VPC"
  type        = string
  default     = "default"
  
  validation {
    condition = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be either 'default' or 'dedicated'."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 support"
  type        = bool
  default     = false
}

variable "assign_ipv6_address_on_creation" {
  description = "Assign IPv6 address on subnet creation"
  type        = bool
  default     = false
}

variable "public_subnet_ipv6_prefixes" {
  description = "IPv6 prefixes for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_ipv6_prefixes" {
  description = "IPv6 prefixes for private subnets"
  type        = list(string)
  default     = []
}

variable "database_subnet_ipv6_prefixes" {
  description = "IPv6 prefixes for database subnets"
  type        = list(string)
  default     = []
}

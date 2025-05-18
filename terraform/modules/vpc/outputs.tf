# ==============================================================================
# VPCモジュール - 出力値
# ==============================================================================

# ==============================================================================
# VPC
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.main.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = aws_vpc.main.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with this VPC"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "ID of the security group created by default on VPC creation"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.main.default_route_table_id
}

# ==============================================================================
# インターネットゲートウェイ
# ==============================================================================

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# ==============================================================================
# パブリックサブネット
# ==============================================================================

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_azs" {
  description = "List of Availability Zones of the public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route"
  value       = aws_route_table.public.route
}

# ==============================================================================
# プライベートサブネット
# ==============================================================================

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_azs" {
  description = "List of Availability Zones of the private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

# ==============================================================================
# データベースサブネット
# ==============================================================================

output "database_subnet_ids" {
  description = "List of IDs of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].id : []
}

output "database_subnet_arns" {
  description = "List of ARNs of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].arn : []
}

output "database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].cidr_block : []
}

output "database_subnet_azs" {
  description = "List of Availability Zones of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].availability_zone : []
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = var.create_database_subnets ? aws_db_subnet_group.main[0].id : null
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.create_database_subnets ? aws_db_subnet_group.main[0].name : null
}

# ==============================================================================
# NAT Gateway
# ==============================================================================

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_allocation_ids" {
  description = "List of allocation IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].allocation_id
}

output "nat_gateway_subnet_ids" {
  description = "List of subnet IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].subnet_id
}

output "nat_gateway_network_interface_ids" {
  description = "List of ENI IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].network_interface_id
}

output "nat_gateway_private_ips" {
  description = "List of private IP addresses of the NAT Gateways"
  value       = aws_nat_gateway.main[*].private_ip
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses of the NAT Gateways"
  value       = aws_nat_gateway.main[*].public_ip
}

# ==============================================================================
# Elastic IP
# ==============================================================================

output "nat_eip_ids" {
  description = "List of allocation IDs of Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].id
}

output "nat_eip_public_ips" {
  description = "List of public IP addresses associated with the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# ==============================================================================
# VPCエンドポイント
# ==============================================================================

output "vpc_endpoint_s3_id" {
  description = "ID of VPC endpoint for S3"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_s3_prefix_list_id" {
  description = "The prefix list ID of the exposed AWS service"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].prefix_list_id : null
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of VPC endpoint for ECR API"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "vpc_endpoint_ecr_api_dns_entry" {
  description = "DNS entries for the VPC Endpoint for ECR API"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_api[0].dns_entry : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of VPC endpoint for ECR DKR"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "vpc_endpoint_ecr_dkr_dns_entry" {
  description = "DNS entries for the VPC Endpoint for ECR DKR"
  value       = var.enable_ecr_endpoint ? aws_vpc_endpoint.ecr_dkr[0].dns_entry : null
}

output "vpc_endpoint_logs_id" {
  description = "ID of VPC endpoint for CloudWatch Logs"
  value       = var.enable_logs_endpoint ? aws_vpc_endpoint.logs[0].id : null
}

output "vpc_endpoint_logs_dns_entry" {
  description = "DNS entries for the VPC Endpoint for CloudWatch Logs"
  value       = var.enable_logs_endpoint ? aws_vpc_endpoint.logs[0].dns_entry : null
}

# ==============================================================================
# セキュリティグループ
# ==============================================================================

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC endpoints"
  value       = length(aws_security_group.vpc_endpoints) > 0 ? aws_security_group.vpc_endpoints[0].id : null
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_default_security_group.default.id
}

output "default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_default_network_acl.default.id
}

# ==============================================================================
# アベイラビリティゾーン情報
# ==============================================================================

output "azs" {
  description = "List of availability zones used"
  value       = local.azs
}

output "azs_count" {
  description = "Number of availability zones used"
  value       = var.azs_count
}

# ==============================================================================
# その他の情報
# ==============================================================================

output "name_prefix" {
  description = "Name prefix used for resources"
  value       = var.name_prefix
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

# ==============================================================================
# サブネット情報の簡易マップ
# ==============================================================================

output "subnets_by_az" {
  description = "Map of subnets by availability zone"
  value = {
    for i, az in local.azs : az => {
      public_subnet_id  = aws_subnet.public[i].id
      private_subnet_id = aws_subnet.private[i].id
      database_subnet_id = var.create_database_subnets ? aws_subnet.database[i].id : null
    }
  }
}

output "subnet_groups" {
  description = "Subnet groups for easy reference"
  value = {
    public = {
      subnet_ids   = aws_subnet.public[*].id
      cidr_blocks  = aws_subnet.public[*].cidr_block
      azs          = aws_subnet.public[*].availability_zone
    }
    private = {
      subnet_ids   = aws_subnet.private[*].id
      cidr_blocks  = aws_subnet.private[*].cidr_block
      azs          = aws_subnet.private[*].availability_zone
    }
    database = var.create_database_subnets ? {
      subnet_ids   = aws_subnet.database[*].id
      cidr_blocks  = aws_subnet.database[*].cidr_block
      azs          = aws_subnet.database[*].availability_zone
    } : null
  }
}

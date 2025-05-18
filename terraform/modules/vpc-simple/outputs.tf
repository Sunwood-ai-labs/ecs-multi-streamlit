# ==============================================================================
# VPCモジュール（Simple版） - 出力値
# ==============================================================================

# ==============================================================================
# VPC
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ==============================================================================
# サブネット（シンプル版）
# ==============================================================================

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# ALBで必要なサブネットIDのリスト形式も提供
output "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB compatibility)"
  value       = [aws_subnet.public.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (for ECS compatibility)"
  value       = [aws_subnet.private.id]
}

# ==============================================================================
# アベイラビリティゾーン
# ==============================================================================

output "availability_zone" {
  description = "Availability zone used"
  value       = local.az
}

# ==============================================================================
# NAT Gateway
# ==============================================================================

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_nat_gateway.main.public_ip
}

# ==============================================================================
# VPCエンドポイント（必要な場合のみ）
# ==============================================================================

output "vpc_endpoint_s3_id" {
  description = "ID of VPC endpoint for S3"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group for VPC endpoints"
  value       = var.enable_ecr_endpoint ? aws_security_group.vpc_endpoints[0].id : null
}

# ==============================================================================
# その他
# ==============================================================================

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

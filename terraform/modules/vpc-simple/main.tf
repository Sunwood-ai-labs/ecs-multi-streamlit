# ==============================================================================
# VPCモジュール（Simple版） - ネットワーク基盤
# ==============================================================================

# ローカル変数
locals {
  # シンプル構成: 単一AZ、最小限のサブネット
  az = data.aws_availability_zones.available.names[0]
  
  # サブネットCIDR（シンプル計算）
  public_subnet_cidr  = cidrsubnet(var.vpc_cidr, 8, 1)
  private_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 2)
}

# データソース
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# ==============================================================================
# VPC
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
    Type = "VPC"
  })
}

# ==============================================================================
# インターネットゲートウェイ
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
    Type = "Internet Gateway"
  })
}

# ==============================================================================
# パブリックサブネット（1つのみ）
# ==============================================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${local.az}"
    Type = "Public Subnet"
    Tier = "Public"
  })
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "Route Table"
    Tier = "Public"
  })
}

# パブリックサブネットのルートテーブル関連付け
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# プライベートサブネット（1つのみ）
# ==============================================================================

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidr
  availability_zone = local.az
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${local.az}"
    Type = "Private Subnet"
    Tier = "Private"
  })
}

# Elastic IP for NAT Gateway（1つのみ）
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
    Type = "Elastic IP"
    Purpose = "NAT Gateway"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway（1つのみ）
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
    Type = "NAT Gateway"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# プライベートルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
    Type = "Route Table"
    Tier = "Private"
  })
}

# プライベートサブネットのルートテーブル関連付け
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ==============================================================================
# VPCエンドポイント（最小限のみ）
# ==============================================================================

# S3 VPCエンドポイント（ECRで必要）
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0
  
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
    Type = "VPC Endpoint"
    Service = "S3"
  })
}

# ECR API VPCエンドポイント（コスト削減のため）
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-api-endpoint"
    Type = "VPC Endpoint"
    Service = "ECR API"
  })
}

# ECR DKR VPCエンドポイント（コスト削減のため）
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-dkr-endpoint"
    Type = "VPC Endpoint"
    Service = "ECR DKR"
  })
}

# VPCエンドポイント用セキュリティグループ
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_ecr_endpoint ? 1 : 0
  
  name_prefix = "${var.name_prefix}-vpce-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpce-sg"
    Type = "Security Group"
    Purpose = "VPC Endpoints"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# セキュリティ強化：デフォルトSGのルールを制限
# ==============================================================================

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  
  # すべてのルールを削除（セキュリティ強化）
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-sg"
    Type = "Security Group"
    Purpose = "Default (Restricted)"
  })
}

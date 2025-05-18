# ==============================================================================
# VPCモジュール - ネットワーク基盤
# ==============================================================================

# ローカル変数
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.azs_count)
  
  # サブネットCIDR計算
  private_subnets = [
    for i in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  public_subnets = [
    for i in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, i + 100)
  ]
  database_subnets = [
    for i in range(var.azs_count) : cidrsubnet(var.vpc_cidr, 8, i + 200)
  ]
}

# データソース: 利用可能なアベイラビリティゾーン
data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# VPC
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
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
# パブリックサブネット
# ==============================================================================

resource "aws_subnet" "public" {
  count = var.azs_count
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Type = "Public Subnet"
    Tier = "Public"
    AZ   = local.azs[count.index]
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
  count = var.azs_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# プライベートサブネット
# ==============================================================================

resource "aws_subnet" "private" {
  count = var.azs_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${local.azs[count.index]}"
    Type = "Private Subnet"
    Tier = "Private"
    AZ   = local.azs[count.index]
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? var.azs_count : 0
  
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${local.azs[count.index]}"
    Type = "Elastic IP"
    Purpose = "NAT Gateway"
    AZ   = local.azs[count.index]
  })
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.azs_count : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${local.azs[count.index]}"
    Type = "NAT Gateway"
    AZ   = local.azs[count.index]
  })
  
  depends_on = [aws_internet_gateway.main]
}

# プライベートルートテーブル
resource "aws_route_table" "private" {
  count = var.azs_count
  
  vpc_id = aws_vpc.main.id
  
  # NAT Gatewayが有効な場合のルート
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${local.azs[count.index]}"
    Type = "Route Table"
    Tier = "Private"
    AZ   = local.azs[count.index]
  })
}

# プライベートサブネットのルートテーブル関連付け
resource "aws_route_table_association" "private" {
  count = var.azs_count
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ==============================================================================
# データベースサブネット（オプション）
# ==============================================================================

resource "aws_subnet" "database" {
  count = var.create_database_subnets ? var.azs_count : 0
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_subnets[count.index]
  availability_zone = local.azs[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-${local.azs[count.index]}"
    Type = "Database Subnet"
    Tier = "Database"
    AZ   = local.azs[count.index]
  })
}

# データベースサブネットグループ
resource "aws_db_subnet_group" "main" {
  count = var.create_database_subnets ? 1 : 0
  
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
    Type = "DB Subnet Group"
  })
}

# ==============================================================================
# VPCエンドポイント
# ==============================================================================

# S3 VPCエンドポイント (Gateway型)
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0
  
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.private[*].id, [aws_route_table.public.id])
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
    Type = "VPC Endpoint"
    Service = "S3"
  })
}

# ECR API VPCエンドポイント (Interface型)
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-api-endpoint"
    Type = "VPC Endpoint"
    Service = "ECR API"
  })
}

# ECR DKR VPCエンドポイント (Interface型)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-dkr-endpoint"
    Type = "VPC Endpoint"
    Service = "ECR DKR"
  })
}

# CloudWatch Logs VPCエンドポイント (Interface型)
resource "aws_vpc_endpoint" "logs" {
  count = var.enable_logs_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-logs-endpoint"
    Type = "VPC Endpoint"
    Service = "CloudWatch Logs"
  })
}

# VPCエンドポイント用セキュリティグループ
resource "aws_security_group" "vpc_endpoints" {
  count = (var.enable_ecr_endpoint || var.enable_logs_endpoint) ? 1 : 0
  
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
# セキュリティグループ（デフォルト）
# ==============================================================================

# デフォルトセキュリティグループのルールを制限
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  
  # すべてのルールを削除（セキュリティ強化）
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-sg"
    Type = "Security Group"
    Purpose = "Default (Restricted)"
  })
}

# ==============================================================================
# ネットワークACL（デフォルト）
# ==============================================================================

# デフォルトネットワークACLの設定
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  
  # デフォルトルールを維持（必要に応じて制限可能）
  
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-nacl"
    Type = "Network ACL"
    Purpose = "Default"
  })
}

# ==============================================================================
# データソース
# ==============================================================================

data "aws_region" "current" {}

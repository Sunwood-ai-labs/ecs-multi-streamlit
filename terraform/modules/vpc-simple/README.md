# VPC Simple Module 🏗️

AWS VPCを**シンプルに**構築するためのTerraformモジュールです。  
デモ・検証・開発環境用に最適化された、最小限の設定で動作するVPCを作成します。

## 🎯 特徴

### ✨ シンプル構成
- **単一AZ構成**: コストと複雑さを最小限に
- **必要最小限のサブネット**: パブリック・プライベートのみ
- **シングルNAT Gateway**: AZ冗長化なしでコスト削減

### 💰 コスト最適化
- データベースサブネット無し
- VPCエンドポイント最小限（S3のみデフォルト有効）
- 複雑な設定項目無し

### 🚀 すぐ使える
- デフォルト設定で即座にデプロイ可能
- ALB・ECS・ECRとの連携を考慮した出力値
- シンプルな変数設定

## 📊 リソース構成

```
10.0.0.0/16 (VPC)
├── 10.0.1.0/24 (Public Subnet)  → Internet Gateway
└── 10.0.2.0/24 (Private Subnet) → NAT Gateway
```

### 作成されるリソース
- VPC (DNS解決有効)
- インターネットゲートウェイ
- パブリックサブネット (1つ)
- プライベートサブネット (1つ)
- NAT Gateway (1つ)
- Elastic IP (NAT Gateway用)
- ルートテーブル (パブリック・プライベート)
- VPCエンドポイント (オプション)
  - S3 Gateway エンドポイント
  - ECR API/DKR Interface エンドポイント

## 📝 使用方法

### 基本的な使用例

```hcl
module "vpc" {
  source = "./modules/vpc-simple"
  
  name_prefix = "my-project-dev"
  vpc_cidr    = "10.0.0.0/16"
  
  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### VPCエンドポイント有効化

```hcl
module "vpc" {
  source = "./modules/vpc-simple"
  
  name_prefix = "my-project-dev"
  vpc_cidr    = "10.0.0.0/16"
  
  # S3エンドポイント（デフォルト: true）
  enable_s3_endpoint  = true
  
  # ECRエンドポイント（コスト削減のためデフォルト: false）
  enable_ecr_endpoint = true
  
  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

## 📋 入力変数

| 変数名 | 型 | デフォルト値 | 説明 |
|--------|----|-----------|----|
| `name_prefix` | string | - | リソース名のプレフィックス（必須） |
| `vpc_cidr` | string | `"10.0.0.0/16"` | VPCのCIDRブロック |
| `enable_s3_endpoint` | bool | `true` | S3 VPCエンドポイントを有効化 |
| `enable_ecr_endpoint` | bool | `false` | ECR VPCエンドポイントを有効化 |
| `tags` | map(string) | `{}` | すべてのリソースに適用するタグ |

## 📤 出力値

| 出力名 | 説明 |
|--------|------|
| `vpc_id` | VPCのID |
| `vpc_cidr_block` | VPCのCIDRブロック |
| `public_subnet_id` | パブリックサブネットのID |
| `private_subnet_id` | プライベートサブネットのID |
| `public_subnet_ids` | パブリックサブネットIDのリスト（ALB用） |
| `private_subnet_ids` | プライベートサブネットIDのリスト（ECS用） |
| `availability_zone` | 使用しているアベイラビリティゾーン |
| `nat_gateway_id` | NAT GatewayのID |
| `nat_gateway_public_ip` | NAT GatewayのパブリックIP |

## 🔗 他モジュールとの連携

### ALBとの連携
```hcl
module "alb" {
  source = "./modules/alb"
  
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  # ...
}
```

### ECSとの連携
```hcl
module "ecs" {
  source = "./modules/ecs"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  # ...
}
```

## ⚠️ 注意事項

### 本番環境には不向き
このモジュールは**デモ・開発環境**用に最適化されています：

- **Single Point of Failure**: シングルAZ構成のため、AZ障害時に全体停止
- **スケーラビリティ制限**: サブネット数・IP数に制限
- **セキュリティ**: 最小限の設定のみ

### 本番環境では
本格的なマルチAZ冗長化構成が必要な場合は、元の `vpc` モジュールを使用してください。

## 💰 コスト見積もり

| リソース | 月額コスト概算 (東京リージョン) |
|----------|------------------------------|
| NAT Gateway | ~$45 |
| Elastic IP | ~$3.6 |
| VPCエンドポイント (Interface) | ~$7.5/個 |
| **合計** | **~$50** (VPCエンドポイントなし) |

## 🔗 完全な使用例

```hcl
# terraform/environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc-simple"
  
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  
  # VPCエンドポイント設定（最小限、コスト考慮）
  enable_s3_endpoint  = true  # ECRで必要
  enable_ecr_endpoint = false # デモ用途でOFF（コスト削減）
  
  tags = local.common_tags
}

# ALB
module "alb" {
  source = "../../modules/alb"
  
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  # ...
}

# ECS
module "ecs" {
  source = "../../modules/ecs"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  # ...
}
```

## 📚 リソース詳細

### セキュリティグループ
- デフォルトセキュリティグループ: 全ルールを削除（セキュリティ強化）
- VPCエンドポイント用SG: HTTPS (443) のみ許可

### ルートテーブル
- パブリック: インターネットゲートウェイ向け
- プライベート: NAT Gateway向け

---

**Created with ❤️ by ギャルAI キラリ** ✨

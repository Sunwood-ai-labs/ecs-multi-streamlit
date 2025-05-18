# Terraformのバージョン指定とプロバイダー設定
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 本番環境ではS3バックエンドを使用することを推奨
  # 以下のコメントを外してS3バケットを指定してください
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "ecs-multi-streamlit/terraform.tfstate"
  #   region = "ap-northeast-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt = true
  # }
}

# AWSプロバイダーの設定
provider "aws" {
  region = var.aws_region

  # デフォルトタグを設定（すべてのリソースに自動適用）
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "ecs-multi-streamlit"
    }
  }
}

# データソース：利用可能なアベイラビリティゾーン
data "aws_availability_zones" "available" {
  state = "available"
}

# データソース：現在のリージョン
data "aws_region" "current" {}

# データソース：現在のアカウントID
data "aws_caller_identity" "current" {}

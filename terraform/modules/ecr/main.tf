# ==============================================================================
# ECRモジュール - Elastic Container Registry
# ==============================================================================

# ローカル変数
locals {
  # 共通ライフサイクルポリシー
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_policy_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.lifecycle_policy_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  # カスタムライフサイクルポリシーがある場合はそれを使用
  final_lifecycle_policy = var.custom_lifecycle_policy != null ? var.custom_lifecycle_policy : local.lifecycle_policy
}

# データソース
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# ECRリポジトリ
# ==============================================================================

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)
  
  name                 = "${var.name_prefix}-${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete
  
  image_scanning_configuration {
    scan_on_push = var.enable_image_scanning
  }
  
  encryption_configuration {
    encryption_type = var.enable_kms_encryption ? "KMS" : "AES256"
    kms_key        = var.enable_kms_encryption ? var.kms_key_id : null
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value}"
    Type = "ECR Repository"
    App  = each.value
  })
}

# ==============================================================================
# ECRライフサイクルポリシー
# ==============================================================================

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = var.enable_lifecycle_policy ? aws_ecr_repository.main : {}
  
  repository = each.value.name
  policy     = local.final_lifecycle_policy
  
  depends_on = [aws_ecr_repository.main]
}

# ==============================================================================
# ECRリポジトリポリシー
# ==============================================================================

# 基本的なリポジトリポリシー（クロスアカウントアクセス用）
data "aws_iam_policy_document" "ecr_policy" {
  for_each = var.enable_cross_account_access ? toset(var.repositories) : toset([])
  
  # プル権限
  statement {
    sid    = "AllowPull"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = concat(
        ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
        var.cross_account_principals
      )
    }
    
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
  }
  
  # プッシュ権限（必要な場合）
  dynamic "statement" {
    for_each = var.allow_push_access ? [1] : []
    content {
      sid    = "AllowPush"
      effect = "Allow"
      
      principals {
        type        = "AWS"
        identifiers = var.push_access_principals
      }
      
      actions = [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
    }
  }
}

# リポジトリポリシーの適用
resource "aws_ecr_repository_policy" "main" {
  for_each = var.enable_cross_account_access ? aws_ecr_repository.main : {}
  
  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr_policy[each.key].json
  
  depends_on = [aws_ecr_repository.main]
}

# ==============================================================================
# ECRレジストリポリシー（レジストリレベルの設定）
# ==============================================================================

# レプリケーション設定
resource "aws_ecr_registry_policy" "main" {
  count = var.enable_registry_policy ? 1 : 0
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReplication"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:CreateRepository",
          "ecr:ReplicateImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# ECRレプリケーション設定
# ==============================================================================

resource "aws_ecr_replication_configuration" "main" {
  count = var.enable_replication ? 1 : 0
  
  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_destinations
      content {
        destination {
          region      = rule.value.region
          registry_id = rule.value.registry_id
        }
        
        dynamic "repository_filter" {
          for_each = rule.value.repository_filters != null ? rule.value.repository_filters : []
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

# ==============================================================================
# ECRスキャン設定
# ==============================================================================

# 拡張スキャン設定（必要な場合）
resource "aws_ecr_registry_scanning_configuration" "main" {
  count = var.enable_enhanced_scanning ? 1 : 0
  
  scan_type = "ENHANCED"
  
  dynamic "rule" {
    for_each = var.enhanced_scanning_rules
    content {
      scan_frequency = rule.value.scan_frequency
      
      repository_filter {
        filter      = rule.value.repository_filter
        filter_type = rule.value.filter_type
      }
    }
  }
}

# ==============================================================================
# CloudWatch Logs（ECR用）
# ==============================================================================

# ECRのAPI使用ログ用CloudWatch Logs グループ
resource "aws_cloudwatch_log_group" "ecr_api" {
  count = var.enable_api_logging ? 1 : 0
  
  name              = "/aws/ecr/api/${var.name_prefix}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.enable_log_encryption ? var.log_kms_key_id : null
  
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ecr-api-logs"
    Type    = "CloudWatch Log Group"
    Purpose = "ECR API Logging"
  })
}

# ==============================================================================
# IAMロール（ECR用）
# ==============================================================================

# ECRアクセス用のIAMロール
resource "aws_iam_role" "ecr_access" {
  count = var.create_ecr_access_role ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecr-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-access-role"
    Type = "IAM Role"
    Purpose = "ECR Access"
  })
}

# ECRアクセス用のIAMポリシー
resource "aws_iam_role_policy" "ecr_access" {
  count = var.create_ecr_access_role ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecr-access-"
  role        = aws_iam_role.ecr_access[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          for repo in aws_ecr_repository.main : repo.arn
        ]
      }
    ]
  })
}

# ==============================================================================
# KMSキー（ECR用）
# ==============================================================================

# ECR暗号化用のKMSキー
resource "aws_kms_key" "ecr" {
  count = var.create_kms_key ? 1 : 0
  
  description              = "KMS key for ECR encryption"
  deletion_window_in_days  = var.kms_key_deletion_window
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR Service"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecr-kms-key"
    Type = "KMS Key"
    Purpose = "ECR Encryption"
  })
}

# KMSキーのエイリアス
resource "aws_kms_alias" "ecr" {
  count = var.create_kms_key ? 1 : 0
  
  name          = "alias/${var.name_prefix}-ecr"
  target_key_id = aws_kms_key.ecr[0].key_id
}

# ==============================================================================
# CloudWatch アラート（ECR用）
# ==============================================================================

# イメージプッシュアラート
resource "aws_cloudwatch_metric_alarm" "image_push_failure" {
  for_each = var.enable_monitoring ? aws_ecr_repository.main : {}
  
  alarm_name          = "${var.name_prefix}-${each.key}-push-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RepositoryPushCount"
  namespace           = "AWS/ECR"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10" # 5分間で10回以上のプッシュ失敗
  alarm_description   = "This metric monitors ECR push failures"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    RepositoryName = each.value.name
  }
  
  alarm_actions = var.notification_sns_arn != null ? [var.notification_sns_arn] : []
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-push-failure-alarm"
    Type = "CloudWatch Alarm"
    Repository = each.key
  })
}

# イメージスキャン検出アラート
resource "aws_cloudwatch_metric_alarm" "scan_findings" {
  for_each = var.enable_monitoring && var.enable_image_scanning ? aws_ecr_repository.main : {}
  
  alarm_name          = "${var.name_prefix}-${each.key}-scan-findings"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HighFindingCount"
  namespace           = "AWS/ECR"
  period              = "86400" # 1日
  statistic           = "Maximum"
  threshold           = "5" # 高危険度の脆弱性が5個以上
  alarm_description   = "This metric monitors high severity vulnerabilities"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    RepositoryName = each.value.name
    ScanStatus     = "COMPLETE"
  }
  
  alarm_actions = var.notification_sns_arn != null ? [var.notification_sns_arn] : []
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-scan-findings-alarm"
    Type = "CloudWatch Alarm"
    Repository = each.key
  })
}

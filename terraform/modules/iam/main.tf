# ==============================================================================
# IAMモジュール - Identity and Access Management
# ==============================================================================

# ローカル変数
locals {
  # ECS実行ロール用の信頼ポリシー
  ecs_task_execution_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  # ECSタスクロール用の信頼ポリシー
  ecs_task_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  # 共通のタグ
  common_tags = merge(var.tags, {
    Module = "IAM"
  })
}

# データソース
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# ECS Task Execution Role
# ==============================================================================

# ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix        = "${var.name_prefix}-ecs-execution-"
  assume_role_policy = local.ecs_task_execution_assume_role_policy
  
  description = "IAM role for ECS task execution"
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-ecs-execution-role"
    Type    = "IAM Role"
    Purpose = "ECS Task Execution"
  })
}

# ECS Task Execution Roleの基本ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECRアクセス用のカスタムポリシー
resource "aws_iam_role_policy" "ecs_task_execution_ecr_policy" {
  name_prefix = "${var.name_prefix}-ecs-execution-ecr-"
  role        = aws_iam_role.ecs_task_execution_role.id
  
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
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

# CloudWatch Logs用のカスタムポリシー
resource "aws_iam_role_policy" "ecs_task_execution_logs_policy" {
  count = var.create_cloudwatch_log_groups ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-execution-logs-"
  role        = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          for log_group in var.log_group_names : 
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${log_group}:*"
        ]
      }
    ]
  })
}

# Systems Manager Parameter Store用のポリシー（シークレット管理用）
resource "aws_iam_role_policy" "ecs_task_execution_ssm_policy" {
  count = var.enable_ssm_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-execution-ssm-"
  role        = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/*"
        ]
      }
    ]
  })
}

# Secrets Manager用のポリシー（シークレット管理用）
resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  count = var.enable_secrets_manager_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-execution-secrets-"
  role        = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.name_prefix}/*"
        ]
      }
    ]
  })
}

# ==============================================================================
# ECS Task Role
# ==============================================================================

# ECSタスクロール
resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "${var.name_prefix}-ecs-task-"
  assume_role_policy = local.ecs_task_assume_role_policy
  
  description = "IAM role for ECS tasks"
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-ecs-task-role"
    Type    = "IAM Role"
    Purpose = "ECS Task"
  })
}

# CloudWatch監視用のポリシー
resource "aws_iam_role_policy" "ecs_task_cloudwatch_policy" {
  count = var.enable_cloudwatch_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-task-cloudwatch-"
  role        = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:PutMetricStream",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# X-Ray トレーシング用のポリシー
resource "aws_iam_role_policy" "ecs_task_xray_policy" {
  count = var.enable_xray_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-task-xray-"
  role        = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3アクセス用のポリシー（ファイルアップロード・ダウンロード用）
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  count = var.enable_s3_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-task-s3-"
  role        = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns != null ? concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        ) : []
      }
    ]
  })
}

# DynamoDB アクセス用のポリシー（データベースアクセス用）
resource "aws_iam_role_policy" "ecs_task_dynamodb_policy" {
  count = var.enable_dynamodb_access ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-task-dynamodb-"
  role        = aws_iam_role.ecs_task_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = var.dynamodb_table_arns != null ? var.dynamodb_table_arns : []
      }
    ]
  })
}

# カスタムポリシーのアタッチ
resource "aws_iam_role_policy" "ecs_task_custom_policy" {
  count = var.custom_task_policy_json != null ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-task-custom-"
  role        = aws_iam_role.ecs_task_role.id
  policy      = var.custom_task_policy_json
}

# ==============================================================================
# ALB用IAMロール（サービスリンクロール）
# ==============================================================================

# ALB用のサービスリンクロール（必要な場合のみ作成）
resource "aws_iam_service_linked_role" "elasticloadbalancing" {
  count            = var.create_alb_service_linked_role ? 1 : 0
  aws_service_name = "elasticloadbalancing.amazonaws.com"
  
  tags = local.common_tags
}

# ==============================================================================
# Auto Scaling用のIAMロール
# ==============================================================================

# Auto Scaling用のIAMロール
resource "aws_iam_role" "ecs_autoscaling_role" {
  count = var.enable_ecs_autoscaling ? 1 : 0
  
  name_prefix = "${var.name_prefix}-ecs-autoscaling-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-ecs-autoscaling-role"
    Type    = "IAM Role"
    Purpose = "ECS Auto Scaling"
  })
}

# Auto Scaling用の基本ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_autoscaling_role_policy" {
  count = var.enable_ecs_autoscaling ? 1 : 0
  
  role       = aws_iam_role.ecs_autoscaling_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
}

# ==============================================================================
# CloudWatch Logs グループ
# ==============================================================================

# CloudWatch Logs グループ作成
resource "aws_cloudwatch_log_group" "ecs_log_groups" {
  for_each = var.create_cloudwatch_log_groups ? toset(var.log_group_names) : toset([])
  
  name              = each.value
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.enable_log_encryption ? var.log_kms_key_id : null
  
  tags = merge(local.common_tags, {
    Name    = each.value
    Type    = "CloudWatch Log Group"
    Purpose = "ECS Container Logs"
  })
}

# ==============================================================================
# KMS Key（ログ暗号化用）
# ==============================================================================

# CloudWatch Logs暗号化用のKMSキー
resource "aws_kms_key" "logs" {
  count = var.create_logs_kms_key ? 1 : 0
  
  description              = "KMS key for CloudWatch Logs encryption"
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
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = [
              for log_group in var.log_group_names : 
              "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${log_group}"
            ]
          }
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-logs-kms-key"
    Type    = "KMS Key"
    Purpose = "CloudWatch Logs Encryption"
  })
}

# KMSキーのエイリアス
resource "aws_kms_alias" "logs" {
  count = var.create_logs_kms_key ? 1 : 0
  
  name          = "alias/${var.name_prefix}-logs"
  target_key_id = aws_kms_key.logs[0].key_id
}

# ==============================================================================
# CodeDeploy用IAMロール（Blue/Green デプロイメント用）
# ==============================================================================

# CodeDeploy用のIAMロール
resource "aws_iam_role" "codedeploy_role" {
  count = var.enable_codedeploy ? 1 : 0
  
  name_prefix = "${var.name_prefix}-codedeploy-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-codedeploy-role"
    Type    = "IAM Role"
    Purpose = "CodeDeploy"
  })
}

# CodeDeploy用の基本ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
  count = var.enable_codedeploy ? 1 : 0
  
  role       = aws_iam_role.codedeploy_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ==============================================================================
# GitHub Actions用IAMロール（OIDC Identity Provider使用）
# ==============================================================================

# GitHub Actions OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.enable_github_actions_oidc ? 1 : 0
  
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com",
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-github-actions-oidc"
    Type    = "OIDC Provider"
    Purpose = "GitHub Actions"
  })
}

# GitHub Actions用のIAMロール
resource "aws_iam_role" "github_actions_role" {
  count = var.enable_github_actions_oidc ? 1 : 0
  
  name_prefix = "${var.name_prefix}-github-actions-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_repository != null ? 
              "repo:${var.github_repository}:*" : "repo:*/*:*"
          }
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name    = "${var.name_prefix}-github-actions-role"
    Type    = "IAM Role"
    Purpose = "GitHub Actions"
  })
}

# GitHub Actions用の最小権限ポリシー
resource "aws_iam_role_policy" "github_actions_policy" {
  count = var.enable_github_actions_oidc ? 1 : 0
  
  name_prefix = "${var.name_prefix}-github-actions-"
  role        = aws_iam_role.github_actions_role[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchGetRepository",
          "ecr:DescribeRegistry",
          "ecr:DescribeImageScanFindings",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetRepository",
          "ecr:ListImages",
          "ecr:ListTagsForResource",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}

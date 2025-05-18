# ==============================================================================
# ECRモジュール - 出力値
# ==============================================================================

# ==============================================================================
# ECRリポジトリ
# ==============================================================================

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.arn
  }
}

output "repository_urls" {
  description = "Map of repository names to URLs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.repository_url
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to registry IDs"
  value = {
    for k, v in aws_ecr_repository.main : k => v.registry_id
  }
}

output "repository_names" {
  description = "Map of repository keys to actual names"
  value = {
    for k, v in aws_ecr_repository.main : k => v.name
  }
}

# ==============================================================================
# KMSキー
# ==============================================================================

output "kms_key_id" {
  description = "ID of the KMS key for ECR encryption"
  value       = var.create_kms_key ? aws_kms_key.ecr[0].id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key for ECR encryption"
  value       = var.create_kms_key ? aws_kms_key.ecr[0].arn : null
}

output "kms_key_alias" {
  description = "Alias of the KMS key for ECR encryption"
  value       = var.create_kms_key ? aws_kms_alias.ecr[0].name : null
}

# ==============================================================================
# IAMロール
# ==============================================================================

output "ecr_access_role_arn" {
  description = "ARN of the ECR access IAM role"
  value       = var.create_ecr_access_role ? aws_iam_role.ecr_access[0].arn : null
}

output "ecr_access_role_name" {
  description = "Name of the ECR access IAM role"
  value       = var.create_ecr_access_role ? aws_iam_role.ecr_access[0].name : null
}

# ==============================================================================
# CloudWatch Logs
# ==============================================================================

output "log_group_name" {
  description = "Name of the CloudWatch log group for ECR API"
  value       = var.enable_api_logging ? aws_cloudwatch_log_group.ecr_api[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for ECR API"
  value       = var.enable_api_logging ? aws_cloudwatch_log_group.ecr_api[0].arn : null
}

# ==============================================================================
# CloudWatch Alarms
# ==============================================================================

output "push_failure_alarm_arns" {
  description = "ARNs of push failure alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.image_push_failure : k => v.arn
  }
}

output "scan_findings_alarm_arns" {
  description = "ARNs of scan findings alarms"
  value = {
    for k, v in aws_cloudwatch_metric_alarm.scan_findings : k => v.arn
  }
}

# ==============================================================================
# レプリケーション設定
# ==============================================================================

output "replication_configuration" {
  description = "ECR replication configuration"
  value       = var.enable_replication ? aws_ecr_replication_configuration.main[0] : null
}

# ==============================================================================
# その他
# ==============================================================================

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = length(aws_ecr_repository.main) > 0 ? values(aws_ecr_repository.main)[0].registry_id : null
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ==============================================================================
# 詳細情報のマップ
# ==============================================================================

output "repositories_detail" {
  description = "Detailed information about all repositories"
  value = {
    for k, v in aws_ecr_repository.main : k => {
      name         = v.name
      arn          = v.arn
      registry_id  = v.registry_id
      repository_url = v.repository_url
      tags         = v.tags_all
    }
  }
}

output "repository_count" {
  description = "Number of repositories created"
  value       = length(aws_ecr_repository.main)
}

# Docker login commands for convenience
output "docker_login_commands" {
  description = "Docker login commands for ECR repositories"
  value = {
    for k, v in aws_ecr_repository.main : k => "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${v.repository_url}"
  }
}

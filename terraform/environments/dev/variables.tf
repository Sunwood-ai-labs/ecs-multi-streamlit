# ==============================================================================
# 汎用変数
# ==============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-northeast-1"
  
  validation {
    condition = can(regex("^[a-z]+-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be in the format of 'region-zone-number' (e.g., ap-northeast-1)."
  }
}

variable "project_name" {
  description = "Name of the project (used for naming resources)"
  type        = string
  default     = "ecs-multi-streamlit"
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ==============================================================================
# ネットワーク設定
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

# AZ数とNAT Gateway設定は削除（シンプル版では単一AZ、NAT Gateway固定）

# ==============================================================================
# ECS設定
# ==============================================================================

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null # プロジェクト名から自動生成
}

variable "fargate_cpu" {
  description = "CPU units for Fargate tasks (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
  
  validation {
    condition = contains([256, 512, 1024, 2048, 4096], var.fargate_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "fargate_memory" {
  description = "Memory for Fargate tasks (in MB)"
  type        = number
  default     = 1024
  
  validation {
    condition = (
      (var.fargate_cpu == 256 && contains([512, 1024, 2048], var.fargate_memory)) ||
      (var.fargate_cpu == 512 && contains([1024, 2048, 3072, 4096], var.fargate_memory)) ||
      (var.fargate_cpu == 1024 && var.fargate_memory >= 2048 && var.fargate_memory <= 8192) ||
      (var.fargate_cpu == 2048 && var.fargate_memory >= 4096 && var.fargate_memory <= 16384) ||
      (var.fargate_cpu == 4096 && var.fargate_memory >= 8192 && var.fargate_memory <= 30720)
    )
    error_message = "Memory must be compatible with CPU. See AWS Fargate task sizing."
  }
}

variable "ecs_task_desired_count" {
  description = "Desired number of tasks for each app"
  type        = number
  default     = 1
  
  validation {
    condition = var.ecs_task_desired_count >= 1 && var.ecs_task_desired_count <= 10
    error_message = "Desired count must be between 1 and 10."
  }
}

variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

# ==============================================================================
# ECR設定
# ==============================================================================

variable "ecr_repositories" {
  description = "List of ECR repository names for Streamlit apps"
  type        = list(string)
  default     = ["app1", "app2", "app3"]
  
  validation {
    condition = length(var.ecr_repositories) > 0
    error_message = "At least one ECR repository must be specified."
  }
}

variable "ecr_lifecycle_policy_count" {
  description = "Number of images to keep in ECR"
  type        = number
  default     = 30
}

# ==============================================================================
# ALB設定
# ==============================================================================

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = null # プロジェクト名から自動生成
}

variable "enable_https" {
  description = "Enable HTTPS for ALB"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

# ==============================================================================
# セキュリティ設定
# ==============================================================================

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 本番環境では制限することを推奨
  
  validation {
    condition = length(var.allowed_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified."
  }
}

# WAF設定は削除（シンプル版では不要）

# ==============================================================================
# ログ設定
# ==============================================================================

variable "cloudwatch_log_retention_in_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_retention_in_days)
    error_message = "Log retention must be one of the allowed values by AWS CloudWatch."
  }
}

variable "enable_container_insights" {
  description = "Enable container insights for ECS cluster"
  type        = bool
  default     = true
}

# ==============================================================================
# 監視・アラート設定
# ==============================================================================

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerts"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}

# ==============================================================================
# コスト最適化設定
# ==============================================================================

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot for cost optimization"
  type        = bool
  default     = false
}

variable "spot_allocation_capacity" {
  description = "Percentage of Fargate Spot to use (0-100)"
  type        = number
  default     = 50
  
  validation {
    condition = var.spot_allocation_capacity >= 0 && var.spot_allocation_capacity <= 100
    error_message = "Spot allocation capacity must be between 0 and 100."
  }
}

# ==============================================================================
# デバッグ・開発設定
# ==============================================================================

variable "enable_debug_logs" {
  description = "Enable debug-level logging"
  type        = bool
  default     = false
}

variable "create_bastion_host" {
  description = "Create a bastion host for debugging"
  type        = bool
  default     = false
}

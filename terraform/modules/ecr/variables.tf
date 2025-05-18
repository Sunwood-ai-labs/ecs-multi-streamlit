# ==============================================================================
# ECRモジュール - 入力変数
# ==============================================================================

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.repositories) > 0
    error_message = "At least one repository must be specified."
  }
}

# ==============================================================================
# リポジトリ設定
# ==============================================================================

variable "image_tag_mutability" {
  description = "Image tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Force delete the repository even if it contains images"
  type        = bool
  default     = false
}

# ==============================================================================
# イメージスキャン設定
# ==============================================================================

variable "enable_image_scanning" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "enable_enhanced_scanning" {
  description = "Enable enhanced scanning"
  type        = bool
  default     = false
}

variable "enhanced_scanning_rules" {
  description = "Enhanced scanning rules"
  type = list(object({
    repository_filter = string
    filter_type      = string
    scan_frequency   = string
  }))
  default = []
}

# ==============================================================================
# 暗号化設定
# ==============================================================================

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for repositories"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a new KMS key for ECR encryption"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
  
  validation {
    condition = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# ==============================================================================
# ライフサイクルポリシー設定
# ==============================================================================

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for repositories"
  type        = bool
  default     = true
}

variable "lifecycle_policy_count" {
  description = "Number of images to keep"
  type        = number
  default     = 30
  
  validation {
    condition = var.lifecycle_policy_count > 0
    error_message = "Lifecycle policy count must be greater than 0."
  }
}

variable "custom_lifecycle_policy" {
  description = "Custom lifecycle policy JSON"
  type        = string
  default     = null
}

# ==============================================================================
# クロスアカウントアクセス設定
# ==============================================================================

variable "enable_cross_account_access" {
  description = "Enable cross-account access"
  type        = bool
  default     = false
}

variable "cross_account_principals" {
  description = "List of cross-account principals"
  type        = list(string)
  default     = []
}

variable "allow_push_access" {
  description = "Allow push access from external accounts"
  type        = bool
  default     = false
}

variable "push_access_principals" {
  description = "List of principals allowed to push"
  type        = list(string)
  default     = []
}

# ==============================================================================
# レプリケーション設定
# ==============================================================================

variable "enable_replication" {
  description = "Enable repository replication"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "List of replication destinations"
  type = list(object({
    region      = string
    registry_id = string
    repository_filters = optional(list(object({
      filter      = string
      filter_type = string
    })))
  }))
  default = []
}

# ==============================================================================
# レジストリポリシー設定
# ==============================================================================

variable "enable_registry_policy" {
  description = "Enable registry policy"
  type        = bool
  default     = false
}

# ==============================================================================
# IAMロール設定
# ==============================================================================

variable "create_ecr_access_role" {
  description = "Create IAM role for ECR access"
  type        = bool
  default     = false
}

# ==============================================================================
# ログ設定
# ==============================================================================

variable "enable_api_logging" {
  description = "Enable ECR API logging to CloudWatch"
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_in_days)
    error_message = "Log retention must be one of the allowed values by AWS CloudWatch."
  }
}

variable "enable_log_encryption" {
  description = "Enable log encryption"
  type        = bool
  default     = true
}

variable "log_kms_key_id" {
  description = "KMS key ID for log encryption"
  type        = string
  default     = null
}

# ==============================================================================
# 監視・アラート設定
# ==============================================================================

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerts"
  type        = bool
  default     = true
}

variable "notification_sns_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = null
}

# ==============================================================================
# タグ設定
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "repository_tags" {
  description = "Additional tags for repositories"
  type        = map(string)
  default     = {}
}

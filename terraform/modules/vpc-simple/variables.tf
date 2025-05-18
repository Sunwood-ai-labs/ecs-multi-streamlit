# ==============================================================================
# VPCモジュール（Simple版） - 入力変数
# ==============================================================================

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

# ==============================================================================
# VPCエンドポイント設定（最小限）
# ==============================================================================

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint (needed for ECR)"
  type        = bool
  default     = true
}

variable "enable_ecr_endpoint" {
  description = "Enable ECR VPC Endpoints (cost optimization)"
  type        = bool
  default     = false # デフォルトOFF（コスト削減）
}

# ==============================================================================
# タグ設定
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

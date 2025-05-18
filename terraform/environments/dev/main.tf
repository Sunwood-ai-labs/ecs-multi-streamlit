# ==============================================================================
# メインの設定ファイル
# ECS + Fargate で複数のStreamlitアプリを単一ALBで公開するインフラストラクチャ
# ==============================================================================

# ローカル変数の定義
locals {
  # 命名規則
  name_prefix = "${var.project_name}-${var.environment}"
  
  # 共通タグ
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    CreatedBy   = "Terraform"
    Repository  = "ecs-multi-streamlit"
  }
  
  # ECRリポジトリのURIマップ
  ecr_repository_urls = {
    for repo in var.ecr_repositories : repo => module.ecr.repository_urls[repo]
  }
  
  # Streamlitアプリの設定
  streamlit_apps = {
    app1 = {
      name          = "app1"
      display_name  = "Data Visualization Dashboard"
      path          = "/app1"
      container_port = 8501
      health_check_path = "/app1/_stcore/health"
      priority      = 100
    }
    app2 = {
      name          = "app2"
      display_name  = "Machine Learning Demo"
      path          = "/app2"
      container_port = 8501
      health_check_path = "/app2/_stcore/health"
      priority      = 200
    }
    app3 = {
      name          = "app3"
      display_name  = "Real-time Monitoring Dashboard"
      path          = "/app3"
      container_port = 8501
      health_check_path = "/app3/_stcore/health"
      priority      = 300
    }
  }
}

# ==============================================================================
# VPCモジュール（Simple版） - ネットワーク基盤
# ==============================================================================
module "vpc" {
  source = "../../modules/vpc-simple"
  
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  
  # VPCエンドポイント設定（最小限、コスト考慮）
  enable_s3_endpoint  = true  # ECRで必要
  enable_ecr_endpoint = false # デモ用途でOFF（コスト削減）
  
  tags = local.common_tags
}

# ==============================================================================
# ECRモジュール - Dockerイメージリポジトリ
# ==============================================================================
module "ecr" {
  source = "../../modules/ecr"
  
  name_prefix   = local.name_prefix
  repositories  = var.ecr_repositories
  
  # ライフサイクルポリシー
  lifecycle_policy_count = var.ecr_lifecycle_policy_count
  
  # セキュリティ設定
  enable_image_scanning = true
  enable_kms_encryption = true
  
  tags = local.common_tags
}

# ==============================================================================
# IAMモジュール - 権限管理
# ==============================================================================
module "iam" {
  source = "../../modules/iam"
  
  name_prefix = local.name_prefix
  
  # ECRリポジトリのARN
  ecr_repository_arns = values(module.ecr.repository_arns)
  
  # CloudWatch Logs設定
  create_cloudwatch_log_groups = true
  log_group_names = [
    for app in keys(local.streamlit_apps) : "/ecs/${local.name_prefix}-${app}"
  ]
  
  tags = local.common_tags
}

# ==============================================================================
# ALBモジュール - Application Load Balancer
# ==============================================================================
module "alb" {
  source = "../../modules/alb"
  
  name            = var.alb_name != null ? var.alb_name : "${local.name_prefix}-alb"
  name_prefix     = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnet_ids
  
  # セキュリティ設定
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_https        = var.enable_https
  certificate_arn     = var.acm_certificate_arn
  
  # Streamlitアプリのターゲットグループ設定
  target_groups = {
    for app_name, app_config in local.streamlit_apps : app_name => {
      name     = "${local.name_prefix}-${app_name}"
      port     = app_config.container_port
      protocol = "HTTP"
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        path                = app_config.health_check_path
        matcher             = "200"
        port                = "traffic-port"
        protocol            = "HTTP"
      }
    }
  }
  
  # リスナールール設定（パスベースルーティング）
  listener_rules = {
    for app_name, app_config in local.streamlit_apps : app_name => {
      priority = app_config.priority
      conditions = [
        {
          path_pattern = {
            values = ["${app_config.path}*"]
          }
        }
      ]
      actions = [
        {
          type             = "forward"
          target_group_key = app_name
        }
      ]
    }
  }
  
  # WAF設定は削除（シンプル版では不要）
  
  tags = local.common_tags
}

# ==============================================================================
# ECSモジュール - コンテナオーケストレーション
# ==============================================================================
module "ecs" {
  source = "../../modules/ecs"
  
  cluster_name = var.ecs_cluster_name != null ? var.ecs_cluster_name : "${local.name_prefix}-cluster"
  name_prefix  = local.name_prefix
  
  # ネットワーク設定
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  
  # セキュリティグループ設定
  alb_security_group_id = module.alb.security_group_id
  
  # IAMロール
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn          = module.iam.ecs_task_role_arn
  
  # Container Insights
  enable_container_insights = var.enable_container_insights
  
  # Streamlitサービス設定
  services = {
    for app_name, app_config in local.streamlit_apps : app_name => {
      # 基本設定
      name                = "${local.name_prefix}-${app_name}"
      task_definition_family = "${local.name_prefix}-${app_name}-task"
      
      # Fargateの仕様
      cpu    = var.fargate_cpu
      memory = var.fargate_memory
      
      # コンテナ設定
      container_definitions = [
        {
          name  = app_name
          image = "${local.ecr_repository_urls[app_name]}:latest"
          
          # ネットワーク設定
          portMappings = [
            {
              containerPort = app_config.container_port
              protocol      = "tcp"
            }
          ]
          
          # 環境変数
          environment = [
            {
              name  = "STREAMLIT_SERVER_PORT"
              value = tostring(app_config.container_port)
            },
            {
              name  = "STREAMLIT_SERVER_ADDRESS"
              value = "0.0.0.0"
            },
            {
              name  = "STREAMLIT_SERVER_HEADLESS"
              value = "true"
            },
            {
              name  = "STREAMLIT_BASE_URL_PATH"
              value = app_config.path
            }
          ]
          
          # ログ設定
          logConfiguration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${local.name_prefix}-${app_name}"
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = "ecs"
            }
          }
          
          # ヘルスチェック
          healthCheck = {
            command = [
              "CMD-SHELL",
              "curl -f http://localhost:${app_config.container_port}/_stcore/health || exit 1"
            ]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
          }
          
          # セキュリティ
          essential = true
          readonlyRootFilesystem = false
        }
      ]
      
      # サービス設定
      desired_count                      = var.ecs_task_desired_count
      enable_execute_command            = true
      enable_autoscaling               = var.enable_autoscaling
      autoscaling_min_capacity         = var.autoscaling_min_capacity
      autoscaling_max_capacity         = var.autoscaling_max_capacity
      
      # ALBターゲットグループ設定
      target_group_arn = module.alb.target_group_arns[app_name]
      
      # サービスディスカバリー（オプション）
      enable_service_discovery = false
      
      # Fargate Spot設定
      enable_fargate_spot      = var.enable_fargate_spot
      spot_allocation_capacity = var.spot_allocation_capacity
    }
  }
  
  # CloudWatch Logs設定
  log_retention_in_days = var.cloudwatch_log_retention_in_days
  
  tags = local.common_tags
  
  depends_on = [
    module.ecr,
    module.iam,
    module.alb
  ]
}

# ==============================================================================
# 監視・アラート設定
# ==============================================================================

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  for_each = var.enable_monitoring ? local.streamlit_apps : {}
  
  alarm_name          = "${local.name_prefix}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs cpu utilization"
  
  dimensions = {
    ServiceName = module.ecs.service_names[each.key]
    ClusterName = module.ecs.cluster_name
  }
  
  alarm_actions = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  for_each = var.enable_monitoring ? local.streamlit_apps : {}
  
  alarm_name          = "${local.name_prefix}-${each.key}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs memory utilization"
  
  dimensions = {
    ServiceName = module.ecs.service_names[each.key]
    ClusterName = module.ecs.cluster_name
  }
  
  alarm_actions = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []
  
  tags = local.common_tags
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_monitoring && var.notification_email != "" ? 1 : 0
  
  name = "${local.name_prefix}-alerts"
  
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count = var.enable_monitoring && var.notification_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ==============================================================================
# 追加のセキュリティリソース
# ==============================================================================

# Systems Manager Parameter for storing configuration
resource "aws_ssm_parameter" "app_config" {
  for_each = local.streamlit_apps
  
  name  = "/${local.name_prefix}/${each.key}/config"
  type  = "SecureString"
  value = jsonencode({
    app_name     = each.value.display_name
    path         = each.value.path
    version      = "1.0.0"
    environment  = var.environment
    created_at   = timestamp()
  })
  
  description = "Configuration for ${each.value.display_name}"
  
  tags = local.common_tags
}

# ==============================================================================
# 出力値
# ==============================================================================

# ALB DNS名
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

# ALB ゾーンID
output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

# ECS クラスター名
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

# ECS サービス名
output "ecs_service_names" {
  description = "Names of the ECS services"
  value       = module.ecs.service_names
}

# ECR リポジトリURL
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = local.ecr_repository_urls
}

# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

# アプリケーションのURL
output "application_urls" {
  description = "URLs to access the Streamlit applications"
  value = {
    for app_name, app_config in local.streamlit_apps : app_name => {
      url          = "http://${module.alb.dns_name}${app_config.path}"
      display_name = app_config.display_name
    }
  }
}

# 接続情報
output "connection_info" {
  description = "Connection information for the deployed applications"
  value = {
    alb_endpoint = module.alb.dns_name
    applications = local.streamlit_apps
    region       = data.aws_region.current.name
    environment  = var.environment
  }
}

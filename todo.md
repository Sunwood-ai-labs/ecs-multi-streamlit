# ECS + Fargate で複数Streamlitアプリを単一ALBで公開デプロイ

## 🎯 プロジェクト概要
AWS ECS + Fargateを使用して3つのStreamlitアプリケーションを実行し、単一のALB（Application Load Balancer）で公開するTerraform一式を作成する。Terraformはベストプラクティスに従い、リポジトリを公開デプロイ対応にする。

## ✅ メインタスク

### 📱 Streamlitアプリケーション開発
- [ ] App1: データ可視化ダッシュボード（/app1でアクセス）
- [ ] App2: 機械学習デモアプリ（/app2でアクセス）
- [ ] App3: リアルタイム監視ダッシュボード（/app3でアクセス）
- [ ] 各アプリ用のDockerfile作成
- [ ] requirements.txtファイル作成
- [ ] ローカル開発用docker-compose.yml作成

### 🏗️ Terraformインフラストラクチャ
- [ ] ベストプラクティス準拠のディレクトリ構造設計
- [ ] VPCモジュール（サブネット、セキュリティグループ）
- [ ] ALBモジュール（パスベースルーティング設定）
- [ ] ECSクラスターモジュール
- [ ] ECS Serviceモジュール（3つのサービス）
- [ ] ECRリポジトリ（3つのアプリ用）
- [ ] IAMロール・ポリシー設定
- [ ] CloudWatch Logs設定

### 🔄 CI/CDパイプライン
- [ ] GitHub Actions for Docker image build & push
- [ ] GitHub Actions for Terraform planning
- [ ] GitHub Actions for Terraform apply
- [ ] 環境別デプロイメント（dev/staging/prod）

### 📋 プロジェクト管理・文書化
- [ ] プロジェクト用のヘッダー画像生成
- [ ] 詳細なREADME.md作成
- [ ] アーキテクチャ図作成
- [ ] デプロイ手順書作成
- [ ] 運用・監視手順書作成

### 🚀 GitHub公開デプロイ
- [ ] GitHubリポジトリ作成
- [ ] Issue作成（各タスク用）
- [ ] ブランチ戦略設定（main/develop/feature）
- [ ] 公開デプロイ設定
- [ ] リリースノート作成

## 📝 調査・検討事項
- [ ] ALBのパスベースルーティング設定方法
- [ ] ECS Fargateでの複数サービス管理
- [ ] Terraformベストプラクティス（モジュール化、状態管理）
- [ ] Streamlitアプリのマルチパス対応
- [ ] セキュリティ設定（セキュリティグループ、IAM）
- [ ] コスト最適化設定

## 🔄 進捗管理
- 完了タスクは `- [x]` でマーク
- 新しい課題や変更は随時追加
- 各Git Issueとの紐付けを行う

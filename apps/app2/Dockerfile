# マルチステージビルドでサイズを最小化
FROM python:3.11-slim as builder

# 作業ディレクトリ設定
WORKDIR /app

# 依存関係をインストール
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# 本番用イメージ
FROM python:3.11-slim

# セキュリティとパフォーマンスのための設定
RUN groupadd --gid 1000 streamlit && \
    useradd --uid 1000 --gid streamlit --shell /bin/bash --create-home streamlit

# 作業ディレクトリ設定
WORKDIR /app

# 必要なシステムパッケージをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Pythonライブラリをbuilderからコピー
COPY --from=builder /root/.local /home/streamlit/.local

# アプリケーションファイルをコピー
COPY app.py .

# 非rootユーザーに変更
USER streamlit

# PATHに.localを追加
ENV PATH=/home/streamlit/.local/bin:$PATH

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Streamlitアプリを起動
EXPOSE 8501

CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0", "--server.headless=true", "--server.enableCORS=false", "--server.enableXsrfProtection=false"]

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from datetime import datetime, timedelta
import time
import random

# ページ設定
st.set_page_config(
    page_title="📈 リアルタイム監視ダッシュボード",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded"
)

# カスタムCSS
st.markdown("""
<style>
    .main-title {
        font-size: 3rem;
        font-weight: bold;
        background: linear-gradient(90deg, #ff6b6b, #4ecdc4);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        text-align: center;
        margin-bottom: 2rem;
    }
    .status-card {
        background-color: #f8f9fa;
        padding: 1.5rem;
        border-radius: 1rem;
        border-left: 5px solid #28a745;
        margin: 1rem 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .alert-card {
        background-color: #fff3cd;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 5px solid #ffc107;
        margin: 0.5rem 0;
    }
    .critical-card {
        background-color: #f8d7da;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 5px solid #dc3545;
        margin: 0.5rem 0;
    }
    .metric-container {
        background: white;
        padding: 1rem;
        border-radius: 0.5rem;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
</style>
""", unsafe_allow_html=True)

# ヘッダー
st.markdown('<div class="main-title">📈 リアルタイム監視ダッシュボード</div>', unsafe_allow_html=True)

# サイドバー設定
with st.sidebar:
    st.header("⚙️ ダッシュボード設定")
    
    # 自動更新設定
    auto_refresh = st.checkbox("🔄 自動更新", value=True)
    if auto_refresh:
        refresh_rate = st.selectbox(
            "更新間隔",
            [1, 2, 5, 10, 30],
            index=2,
            format_func=lambda x: f"{x}秒"
        )
    
    # 監視対象選択
    st.subheader("📊 監視対象")
    monitor_cpu = st.checkbox("💻 CPU使用率", value=True)
    monitor_memory = st.checkbox("🧠 メモリ使用率", value=True)
    monitor_network = st.checkbox("🌐 ネットワーク", value=True)
    monitor_disk = st.checkbox("💾 ディスク使用率", value=True)
    
    # アラート設定
    st.subheader("🚨 アラート閾値")
    cpu_threshold = st.slider("CPU警告閾値 (%)", 0, 100, 80)
    memory_threshold = st.slider("メモリ警告閾値 (%)", 0, 100, 85)
    network_threshold = st.slider("ネットワーク警告閾値 (Mbps)", 0, 1000, 500)
    
    # 表示期間
    st.subheader("📅 表示期間")
    time_window = st.selectbox(
        "データ表示期間",
        ["1分", "5分", "10分", "30分", "1時間"],
        index=2
    )

# データ生成関数
@st.cache_data(ttl=1)  # 1秒間キャッシュ
def generate_realtime_data():
    """リアルタイムデータを生成"""
    current_time = datetime.now()
    
    # CPU使用率（0-100%）
    cpu_base = random.uniform(30, 60)
    cpu_spike = random.choice([0, 0, 0, random.uniform(20, 40)])  # 時々スパイク
    cpu_usage = min(100, cpu_base + cpu_spike + random.uniform(-5, 5))
    
    # メモリ使用率（0-100%）
    memory_base = random.uniform(40, 70)
    memory_usage = min(100, memory_base + random.uniform(-3, 8))
    
    # ネットワーク通信量（Mbps）
    network_in = random.uniform(10, 200) + random.choice([0, 0, random.uniform(100, 400)])
    network_out = random.uniform(5, 150) + random.choice([0, 0, random.uniform(50, 300)])
    
    # ディスク使用率（相対的に安定）
    disk_usage = random.uniform(45, 75) + random.uniform(-2, 2)
    
    # アプリケーション応答時間（ms）
    response_time = random.uniform(50, 200) + random.choice([0, 0, random.uniform(200, 800)])
    
    # アクティブユーザー数
    active_users = random.randint(100, 500)
    
    # エラー率（%）
    error_rate = random.uniform(0, 0.5) + random.choice([0, 0, 0, random.uniform(0.5, 3)])
    
    return {
        'timestamp': current_time,
        'cpu_usage': cpu_usage,
        'memory_usage': memory_usage,
        'network_in': network_in,
        'network_out': network_out,
        'disk_usage': disk_usage,
        'response_time': response_time,
        'active_users': active_users,
        'error_rate': error_rate
    }

# 履歴データ管理
if 'history_data' not in st.session_state:
    st.session_state.history_data = []

# 時間窓の設定
time_windows = {
    "1分": 60,
    "5分": 300,
    "10分": 600,
    "30分": 1800,
    "1時間": 3600
}

# データを定期的に更新
if auto_refresh:
    # プレースホルダーを作成
    placeholder = st.empty()
    
    while True:
        new_data = generate_realtime_data()
        st.session_state.history_data.append(new_data)
        
        # 指定された時間窓内のデータのみ保持
        current_time = datetime.now()
        cutoff_time = current_time - timedelta(seconds=time_windows[time_window])
        st.session_state.history_data = [
            data for data in st.session_state.history_data
            if data['timestamp'] > cutoff_time
        ]
        
        with placeholder.container():
            # 最新データを表示
            if st.session_state.history_data:
                latest_data = st.session_state.history_data[-1]
                
                # ステータス概要
                st.markdown("## 🔴 システム状況")
                
                col1, col2, col3, col4 = st.columns(4)
                
                with col1:
                    # CPU使用率
                    cpu_color = "🔴" if latest_data['cpu_usage'] > cpu_threshold else "🟢"
                    st.markdown(
                        f"""
                        <div class="metric-container">
                            <h4>{cpu_color} CPU使用率</h4>
                            <h2>{latest_data['cpu_usage']:.1f}%</h2>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                
                with col2:
                    # メモリ使用率
                    memory_color = "🔴" if latest_data['memory_usage'] > memory_threshold else "🟢"
                    st.markdown(
                        f"""
                        <div class="metric-container">
                            <h4>{memory_color} メモリ使用率</h4>
                            <h2>{latest_data['memory_usage']:.1f}%</h2>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                
                with col3:
                    # 応答時間
                    response_color = "🔴" if latest_data['response_time'] > 500 else "🟢"
                    st.markdown(
                        f"""
                        <div class="metric-container">
                            <h4>{response_color} 応答時間</h4>
                            <h2>{latest_data['response_time']:.0f}ms</h2>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                
                with col4:
                    # エラー率
                    error_color = "🔴" if latest_data['error_rate'] > 1.0 else "🟢"
                    st.markdown(
                        f"""
                        <div class="metric-container">
                            <h4>{error_color} エラー率</h4>
                            <h2>{latest_data['error_rate']:.2f}%</h2>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                
                # アラート表示
                alerts = []
                if latest_data['cpu_usage'] > cpu_threshold:
                    alerts.append(f"⚠️ CPU使用率が高いです: {latest_data['cpu_usage']:.1f}%")
                if latest_data['memory_usage'] > memory_threshold:
                    alerts.append(f"⚠️ メモリ使用率が高いです: {latest_data['memory_usage']:.1f}%")
                if latest_data['response_time'] > 500:
                    alerts.append(f"⚠️ 応答時間が遅いです: {latest_data['response_time']:.0f}ms")
                if latest_data['error_rate'] > 1.0:
                    alerts.append(f"🔴 エラー率が高いです: {latest_data['error_rate']:.2f}%")
                
                if alerts:
                    st.markdown("## 🚨 アラート")
                    for alert in alerts:
                        st.markdown(
                            f'<div class="alert-card">{alert}</div>',
                            unsafe_allow_html=True
                        )
                
                # データがある場合のみグラフを表示
                if len(st.session_state.history_data) > 1:
                    # データを DataFrame に変換
                    df = pd.DataFrame(st.session_state.history_data)
                    
                    # グラフ表示
                    st.markdown("## 📊 リアルタイムグラフ")
                    
                    # システムリソース監視
                    if monitor_cpu or monitor_memory or monitor_disk:
                        st.subheader("💻 システムリソース")
                        fig = make_subplots(
                            rows=1, cols=1,
                            subplot_titles=["システムリソース使用率"]
                        )
                        
                        if monitor_cpu:
                            fig.add_trace(
                                go.Scatter(
                                    x=df['timestamp'],
                                    y=df['cpu_usage'],
                                    mode='lines+markers',
                                    name='CPU使用率',
                                    line=dict(color='#ff6b6b', width=2)
                                )
                            )
                        
                        if monitor_memory:
                            fig.add_trace(
                                go.Scatter(
                                    x=df['timestamp'],
                                    y=df['memory_usage'],
                                    mode='lines+markers',
                                    name='メモリ使用率',
                                    line=dict(color='#4ecdc4', width=2)
                                )
                            )
                        
                        if monitor_disk:
                            fig.add_trace(
                                go.Scatter(
                                    x=df['timestamp'],
                                    y=df['disk_usage'],
                                    mode='lines+markers',
                                    name='ディスク使用率',
                                    line=dict(color='#45b7d1', width=2)
                                )
                            )
                        
                        fig.update_layout(
                            yaxis_title="使用率 (%)",
                            xaxis_title="時刻",
                            height=400,
                            showlegend=True
                        )
                        st.plotly_chart(fig, use_container_width=True)
                    
                    # ネットワーク監視
                    if monitor_network:
                        st.subheader("🌐 ネットワーク通信量")
                        fig_network = go.Figure()
                        
                        fig_network.add_trace(
                            go.Scatter(
                                x=df['timestamp'],
                                y=df['network_in'],
                                mode='lines+markers',
                                name='受信 (Mbps)',
                                line=dict(color='#96ceb4', width=2),
                                fill='tonexty'
                            )
                        )
                        
                        fig_network.add_trace(
                            go.Scatter(
                                x=df['timestamp'],
                                y=df['network_out'],
                                mode='lines+markers',
                                name='送信 (Mbps)', 
                                line=dict(color='#ffeaa7', width=2),
                                fill='tozeroy'
                            )
                        )
                        
                        fig_network.update_layout(
                            yaxis_title="通信量 (Mbps)",
                            xaxis_title="時刻",
                            height=400
                        )
                        st.plotly_chart(fig_network, use_container_width=True)
                    
                    # アプリケーション監視
                    st.subheader("🚀 アプリケーション性能")
                    
                    col_response, col_users = st.columns(2)
                    
                    with col_response:
                        # 応答時間
                        fig_response = px.line(
                            df, x='timestamp', y='response_time',
                            title='応答時間の推移',
                            labels={'response_time': '応答時間 (ms)', 'timestamp': '時刻'}
                        )
                        fig_response.update_traces(line_color='#fd79a8', line_width=3)
                        st.plotly_chart(fig_response, use_container_width=True)
                    
                    with col_users:
                        # アクティブユーザー数
                        fig_users = px.area(
                            df, x='timestamp', y='active_users',
                            title='アクティブユーザー数',
                            labels={'active_users': 'ユーザー数', 'timestamp': '時刻'}
                        )
                        fig_users.update_traces(fill='tonexty', fillcolor='rgba(116, 185, 255, 0.4)')
                        st.plotly_chart(fig_users, use_container_width=True)
                    
                    # エラー率
                    st.subheader("❌ エラー監視")
                    fig_error = px.bar(
                        df.tail(20), x='timestamp', y='error_rate',
                        title='エラー率の推移（直近20データポイント）',
                        labels={'error_rate': 'エラー率 (%)', 'timestamp': '時刻'}
                    )
                    fig_error.update_traces(marker_color='#e84393')
                    st.plotly_chart(fig_error, use_container_width=True)
                    
                    # 統計サマリー
                    st.markdown("## 📋 統計サマリー")
                    
                    summary_col1, summary_col2 = st.columns(2)
                    
                    with summary_col1:
                        st.subheader("📊 平均値")
                        avg_stats = pd.DataFrame({
                            '項目': ['CPU使用率', 'メモリ使用率', '応答時間', 'エラー率'],
                            '平均値': [
                                f"{df['cpu_usage'].mean():.1f}%",
                                f"{df['memory_usage'].mean():.1f}%",
                                f"{df['response_time'].mean():.0f}ms",
                                f"{df['error_rate'].mean():.2f}%"
                            ]
                        })
                        st.dataframe(avg_stats, use_container_width=True)
                    
                    with summary_col2:
                        st.subheader("📈 最大値")
                        max_stats = pd.DataFrame({
                            '項目': ['CPU使用率', 'メモリ使用率', '応答時間', 'エラー率'],
                            '最大値': [
                                f"{df['cpu_usage'].max():.1f}%",
                                f"{df['memory_usage'].max():.1f}%",
                                f"{df['response_time'].max():.0f}ms",
                                f"{df['error_rate'].max():.2f}%"
                            ]
                        })
                        st.dataframe(max_stats, use_container_width=True)
                
                # 最終更新時刻
                st.markdown(
                    f"""
                    <div style='text-align: center; color: #666; padding: 1rem;'>
                        最終更新: {latest_data['timestamp'].strftime('%Y-%m-%d %H:%M:%S')}
                    </div>
                    """,
                    unsafe_allow_html=True
                )
        
        # 指定された間隔で更新
        time.sleep(refresh_rate)

else:
    # 自動更新がOFFの場合
    if st.button("🔄 手動更新", type="primary"):
        new_data = generate_realtime_data()
        st.session_state.history_data.append(new_data)
        st.success("データを更新しました！")
    
    st.info("👈 サイドバーで「🔄 自動更新」をONにすると、リアルタイムでデータが更新されます。")

# フッター
st.markdown("---")
st.markdown(
    """
    <div style='text-align: center; color: #666; padding: 1rem;'>
        📈 Created with Streamlit | Real-time Monitoring Dashboard
    </div>
    """,
    unsafe_allow_html=True
)

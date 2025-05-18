import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta

# Streamlitアプリの設定
st.set_page_config(
    page_title="📊 データ可視化ダッシュボード",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# カスタムCSS
st.markdown("""
<style>
    .metric-container {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 5px solid #ff4b4b;
    }
    .header-style {
        font-size: 2.5rem;
        font-weight: bold;
        color: #262730;
        text-align: center;
        margin-bottom: 2rem;
    }
</style>
""", unsafe_allow_html=True)

# ヘッダー
st.markdown('<p class="header-style">📊 データ可視化ダッシュボード</p>', unsafe_allow_html=True)
st.markdown("---")

# サイドバー
with st.sidebar:
    st.header("🎛️ 設定オプション")
    
    # データ生成のパラメータ
    data_points = st.slider("データポイント数", 100, 1000, 500)
    categories = st.multiselect(
        "カテゴリー選択",
        ["売上", "利益", "顧客数", "製品数"],
        default=["売上", "利益"]
    )
    
    # 日付範囲
    st.subheader("📅 期間設定")
    start_date = st.date_input("開始日", datetime.now() - timedelta(days=30))
    end_date = st.date_input("終了日", datetime.now())
    
    # グラフタイプ
    chart_type = st.selectbox(
        "グラフタイプ",
        ["線グラフ", "棒グラフ", "散布図", "ヒートマップ"]
    )

# データ生成
@st.cache_data
def generate_sample_data(n_points, categories):
    """サンプルデータ生成"""
    np.random.seed(42)
    dates = pd.date_range(start=start_date, end=end_date, periods=n_points)
    
    data = {"日付": dates}
    for category in categories:
        if category == "売上":
            data[category] = np.random.normal(100000, 20000, n_points)
        elif category == "利益":
            data[category] = np.random.normal(15000, 5000, n_points)
        elif category == "顧客数":
            data[category] = np.random.poisson(500, n_points)
        elif category == "製品数":
            data[category] = np.random.randint(50, 200, n_points)
    
    return pd.DataFrame(data)

if categories:
    df = generate_sample_data(data_points, categories)
    
    # メトリクス表示
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        if "売上" in categories:
            total_sales = df["売上"].sum()
            st.metric("💰 総売上", f"¥{total_sales:,.0f}")
    
    with col2:
        if "利益" in categories:
            total_profit = df["利益"].sum()
            st.metric("💎 総利益", f"¥{total_profit:,.0f}")
    
    with col3:
        if "顧客数" in categories:
            avg_customers = df["顧客数"].mean()
            st.metric("👥 平均顧客数", f"{avg_customers:.0f}人")
    
    with col4:
        if "製品数" in categories:
            avg_products = df["製品数"].mean()
            st.metric("📦 平均製品数", f"{avg_products:.0f}個")
    
    st.markdown("---")
    
    # グラフ表示
    col_chart, col_table = st.columns([2, 1])
    
    with col_chart:
        st.subheader(f"📈 {chart_type}")
        
        if chart_type == "線グラフ":
            fig = px.line(df, x="日付", y=categories, title="時系列データ")
        elif chart_type == "棒グラフ":
            df_melted = df.melt(id_vars=["日付"], value_vars=categories)
            fig = px.bar(df_melted, x="日付", y="value", color="variable", title="棒グラフ")
        elif chart_type == "散布図" and len(categories) >= 2:
            fig = px.scatter(df, x=categories[0], y=categories[1], title="散布図")
        elif chart_type == "ヒートマップ":
            # 相関行列のヒートマップ
            corr_matrix = df[categories].corr()
            fig = px.imshow(corr_matrix, text_auto=True, title="相関ヒートマップ")
        else:
            fig = px.line(df, x="日付", y=categories, title="デフォルト線グラフ")
        
        fig.update_layout(height=500)
        st.plotly_chart(fig, use_container_width=True)
    
    with col_table:
        st.subheader("📋 データテーブル")
        st.dataframe(df.tail(10), use_container_width=True)
        
        # 統計サマリー
        st.subheader("📊 統計サマリー")
        st.write(df[categories].describe())
    
    # インタラクティブ分析
    st.markdown("---")
    st.subheader("🔍 インタラクティブ分析")
    
    analysis_type = st.radio(
        "分析タイプを選択:",
        ["トレンド分析", "分布分析", "相関分析"],
        horizontal=True
    )
    
    if analysis_type == "トレンド分析":
        selected_category = st.selectbox("分析対象", categories)
        if selected_category:
            # 移動平均
            window_size = st.slider("移動平均期間", 5, 50, 10)
            df[f"{selected_category}_MA"] = df[selected_category].rolling(window=window_size).mean()
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=df["日付"], y=df[selected_category], name=selected_category))
            fig.add_trace(go.Scatter(x=df["日付"], y=df[f"{selected_category}_MA"], name=f"移動平均({window_size}日)"))
            fig.update_layout(title=f"{selected_category}のトレンド分析", height=400)
            st.plotly_chart(fig, use_container_width=True)
    
    elif analysis_type == "分布分析":
        selected_category = st.selectbox("分析対象", categories)
        if selected_category:
            fig = px.histogram(df, x=selected_category, nbins=30, title=f"{selected_category}の分布")
            st.plotly_chart(fig, use_container_width=True)
    
    elif analysis_type == "相関分析" and len(categories) >= 2:
        # 相関係数の計算
        correlation = df[categories].corr()
        
        # 相関行列を表示
        fig = px.imshow(
            correlation,
            text_auto=True,
            aspect="auto",
            title="変数間の相関係数"
        )
        st.plotly_chart(fig, use_container_width=True)

else:
    st.warning("⚠️ 少なくとも一つのカテゴリーを選択してください。")

# フッター
st.markdown("---")
st.markdown(
    """
    <div style='text-align: center; color: #666; padding: 1rem;'>
        💖 Created with Streamlit | 📊 Data Visualization Dashboard
    </div>
    """,
    unsafe_allow_html=True
)

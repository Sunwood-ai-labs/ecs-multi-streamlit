import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score, mean_squared_error, classification_report
from sklearn.datasets import make_classification, make_regression
import seaborn as sns
import matplotlib.pyplot as plt

# ページ設定
st.set_page_config(
    page_title="🤖 機械学習デモアプリ",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# カスタムCSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .section-header {
        font-size: 1.5rem;
        font-weight: bold;
        color: #ff7f0e;
        margin-top: 2rem;
        margin-bottom: 1rem;
    }
    .metric-box {
        background-color: #f8f9fa;
        padding: 1rem;
        border-radius: 0.5rem;
        border: 1px solid #e9ecef;
        margin: 0.5rem 0;
    }
    .prediction-box {
        background-color: #e8f5e9;
        padding: 1.5rem;
        border-radius: 0.5rem;
        border-left: 5px solid #4caf50;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# メインヘッダー
st.markdown('<p class="main-header">🤖 機械学習デモアプリ</p>', unsafe_allow_html=True)
st.markdown("---")

# サイドバー
with st.sidebar:
    st.header("⚙️ モデル設定")
    
    # タスクタイプ選択
    task_type = st.selectbox(
        "🎯 タスクタイプ",
        ["分類 (Classification)", "回帰 (Regression)", "クラスタリング", "次元削減"]
    )
    
    # アルゴリズム選択
    if task_type == "分類 (Classification)":
        algorithm = st.selectbox(
            "🔧 アルゴリズム",
            ["Random Forest", "Logistic Regression", "Decision Tree"]
        )
    elif task_type == "回帰 (Regression)":
        algorithm = st.selectbox(
            "🔧 アルゴリズム", 
            ["Random Forest", "Linear Regression"]
        )
    else:
        algorithm = "Random Forest"
    
    # データ設定
    st.subheader("📊 データ設定")
    n_samples = st.slider("サンプル数", 100, 2000, 1000)
    n_features = st.slider("特徴量数", 2, 20, 10)
    
    if task_type == "分類 (Classification)":
        n_classes = st.slider("クラス数", 2, 5, 3)
        noise = st.slider("ノイズレベル", 0.0, 0.3, 0.1)
    
    # モデルパラメータ
    st.subheader("🎛️ モデルパラメータ")
    if algorithm == "Random Forest":
        n_estimators = st.slider("推定器数", 10, 200, 100)
        max_depth = st.slider("最大深度", 1, 20, 10)
    
    # 実行ボタン
    run_model = st.button("🚀 モデル実行", type="primary")

# データ生成関数
@st.cache_data
def generate_data(task_type, n_samples, n_features, **kwargs):
    if task_type == "分類 (Classification)":
        X, y = make_classification(
            n_samples=n_samples,
            n_features=n_features,
            n_classes=kwargs.get('n_classes', 3),
            n_informative=min(n_features, kwargs.get('n_classes', 3)),
            noise=kwargs.get('noise', 0.1),
            random_state=42
        )
    else:  # 回帰
        X, y = make_regression(
            n_samples=n_samples,
            n_features=n_features,
            noise=10,
            random_state=42
        )
    return X, y

# モデル訓練関数
def train_model(X_train, y_train, algorithm, **params):
    if algorithm == "Random Forest":
        if len(np.unique(y_train)) <= 10:  # 分類
            model = RandomForestClassifier(
                n_estimators=params.get('n_estimators', 100),
                max_depth=params.get('max_depth', 10),
                random_state=42
            )
        else:  # 回帰
            model = RandomForestRegressor(
                n_estimators=params.get('n_estimators', 100),
                max_depth=params.get('max_depth', 10),
                random_state=42
            )
    elif algorithm == "Logistic Regression":
        model = LogisticRegression(random_state=42, max_iter=1000)
    elif algorithm == "Linear Regression":
        model = LinearRegression()
    elif algorithm == "Decision Tree":
        model = DecisionTreeClassifier(random_state=42)
    
    model.fit(X_train, y_train)
    return model

# メインコンテンツ
if run_model:
    with st.spinner('データ生成とモデル訓練中...🔄'):
        # データ生成
        if task_type == "分類 (Classification)":
            X, y = generate_data(task_type, n_samples, n_features, n_classes=n_classes, noise=noise)
        else:
            X, y = generate_data(task_type, n_samples, n_features)
        
        # データ分割
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # モデル訓練
        if algorithm == "Random Forest":
            model = train_model(X_train, y_train, algorithm, n_estimators=n_estimators, max_depth=max_depth)
        else:
            model = train_model(X_train, y_train, algorithm)
        
        # 予測
        y_pred = model.predict(X_test)
        
        # 結果表示
        col1, col2 = st.columns([1, 1])
        
        with col1:
            st.markdown('<p class="section-header">📈 モデル性能</p>', unsafe_allow_html=True)
            
            if task_type == "分類 (Classification)":
                accuracy = accuracy_score(y_test, y_pred)
                st.markdown(
                    f"""
                    <div class="metric-box">
                        <h3>🎯 精度 (Accuracy)</h3>
                        <h2>{accuracy:.3f}</h2>
                    </div>
                    """,
                    unsafe_allow_html=True
                )
                
                # 分類レポート
                st.subheader("📊 分類レポート")
                report = classification_report(y_test, y_pred, output_dict=True)
                report_df = pd.DataFrame(report).transpose()
                st.dataframe(report_df.round(3))
                
            else:  # 回帰
                mse = mean_squared_error(y_test, y_pred)
                rmse = np.sqrt(mse)
                st.markdown(
                    f"""
                    <div class="metric-box">
                        <h3>📉 RMSE</h3>
                        <h2>{rmse:.3f}</h2>
                    </div>
                    """,
                    unsafe_allow_html=True
                )
        
        with col2:
            st.markdown('<p class="section-header">📊 データ可視化</p>', unsafe_allow_html=True)
            
            if task_type == "分類 (Classification)":
                # 2つの特徴量を使った散布図（分類）
                fig = px.scatter(
                    x=X_test[:, 0], 
                    y=X_test[:, 1],
                    color=y_test.astype(str),
                    title="真のラベル",
                    labels={'x': '特徴量1', 'y': '特徴量2', 'color': 'クラス'}
                )
                st.plotly_chart(fig, use_container_width=True)
                
                # 予測結果
                fig2 = px.scatter(
                    x=X_test[:, 0], 
                    y=X_test[:, 1],
                    color=y_pred.astype(str),
                    title="予測ラベル",
                    labels={'x': '特徴量1', 'y': '特徴量2', 'color': 'クラス'}
                )
                st.plotly_chart(fig2, use_container_width=True)
            
            else:  # 回帰
                # 予測 vs 実際のプロット
                fig = px.scatter(
                    x=y_test, 
                    y=y_pred,
                    title="予測値 vs 実際値",
                    labels={'x': '実際値', 'y': '予測値'}
                )
                # 理想線を追加
                min_val = min(y_test.min(), y_pred.min())
                max_val = max(y_test.max(), y_pred.max())
                fig.add_trace(go.Scatter(
                    x=[min_val, max_val],
                    y=[min_val, max_val],
                    mode='lines',
                    name='理想線',
                    line=dict(color='red', dash='dash')
                ))
                st.plotly_chart(fig, use_container_width=True)
        
        # 特徴量重要度（Random Forestの場合）
        if algorithm == "Random Forest" and hasattr(model, 'feature_importances_'):
            st.markdown('<p class="section-header">🔍 特徴量重要度</p>', unsafe_allow_html=True)
            
            importance_df = pd.DataFrame({
                '特徴量': [f'特徴量{i+1}' for i in range(n_features)],
                '重要度': model.feature_importances_
            }).sort_values('重要度', ascending=True)
            
            fig = px.bar(
                importance_df, 
                x='重要度', 
                y='特徴量',
                orientation='h',
                title='特徴量重要度ランキング'
            )
            st.plotly_chart(fig, use_container_width=True)
        
        # インタラクティブ予測
        st.markdown('<p class="section-header">🎮 インタラクティブ予測</p>', unsafe_allow_html=True)
        
        st.write("任意の値を入力して予測してみましょう！")
        
        input_cols = st.columns(min(5, n_features))
        input_values = []
        
        for i in range(n_features):
            with input_cols[i % 5]:
                value = st.number_input(
                    f"特徴量{i+1}",
                    value=float(X_test[0, i]),
                    key=f"feature_{i}"
                )
                input_values.append(value)
        
        if st.button("🔮 予測実行"):
            input_array = np.array(input_values).reshape(1, -1)
            prediction = model.predict(input_array)[0]
            
            if task_type == "分類 (Classification)":
                if hasattr(model, 'predict_proba'):
                    proba = model.predict_proba(input_array)[0]
                    st.markdown(
                        f"""
                        <div class="prediction-box">
                            <h3>🎯 予測結果</h3>
                            <h2>クラス: {prediction}</h2>
                            <p>予測確率: {max(proba):.3f}</p>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
                    
                    # 確率分布
                    prob_df = pd.DataFrame({
                        'クラス': [f'クラス{i}' for i in range(len(proba))],
                        '確率': proba
                    })
                    fig = px.bar(prob_df, x='クラス', y='確率', title='各クラスの予測確率')
                    st.plotly_chart(fig, use_container_width=True)
                else:
                    st.markdown(
                        f"""
                        <div class="prediction-box">
                            <h3>🎯 予測結果</h3>
                            <h2>クラス: {prediction}</h2>
                        </div>
                        """,
                        unsafe_allow_html=True
                    )
            else:  # 回帰
                st.markdown(
                    f"""
                    <div class="prediction-box">
                        <h3>🎯 予測結果</h3>
                        <h2>予測値: {prediction:.3f}</h2>
                    </div>
                    """,
                    unsafe_allow_html=True
                )
        
        # データダウンロード
        st.markdown("---")
        st.subheader("💾 データ/モデル情報")
        
        col_download1, col_download2 = st.columns(2)
        
        with col_download1:
            # データセット情報
            data_info = pd.DataFrame({
                '項目': ['サンプル数（訓練用）', 'サンプル数（テスト用）', '特徴量数', 'アルゴリズム'],
                '値': [len(X_train), len(X_test), n_features, algorithm]
            })
            st.write("📊 データセット情報")
            st.dataframe(data_info, use_container_width=True)
        
        with col_download2:
            # 予測結果をCSVでダウンロード
            result_df = pd.DataFrame({
                '実際値': y_test,
                '予測値': y_pred
            })
            csv = result_df.to_csv(index=False)
            st.download_button(
                label="📥 予測結果をダウンロード",
                data=csv,
                file_name="prediction_results.csv",
                mime="text/csv"
            )

else:
    # 初期表示
    st.info("👈 サイドバーでパラメータを設定して「🚀 モデル実行」ボタンを押してください。")
    
    st.markdown("## 🌟 機能紹介")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.markdown("""
        ### 🎯 分類タスク
        - Random Forest
        - Logistic Regression
        - Decision Tree
        - 精度評価と分類レポート
        """)
    
    with col2:
        st.markdown("""
        ### 📈 回帰タスク
        - Random Forest Regressor
        - Linear Regression
        - RMSE評価
        - 予測vs実際値のプロット
        """)
    
    with col3:
        st.markdown("""
        ### 🔍 可視化機能
        - 特徴量重要度
        - インタラクティブ予測
        - 結果のダウンロード
        - クラス確率分布
        """)

# フッター
st.markdown("---")
st.markdown(
    """
    <div style='text-align: center; color: #666; padding: 1rem;'>
        🤖 Created with Streamlit | ML Demo Application
    </div>
    """,
    unsafe_allow_html=True
)

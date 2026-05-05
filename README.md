# Snowflake × AI によるクオンツ・ポートフォリオ最適化 ハンズオン

**Quantitative Portfolio Optimization with Snowflake AI Data Cloud**

> 対象者: クオンツアナリスト / ポートフォリオマネージャー  
> 所要時間: 約3時間30分  
> 環境: Snowflake トライアルアカウント（GPU不要・外部接続不要）

---

## 概要

本ハンズオンでは、Snowflake の AI/ML 機能をフルに活用し、  
「有報・決算資料の非構造化分析」と「マルチファクターモデルに基づくポートフォリオ最適化」を  
一貫したパイプラインとして構築します。

### 体験できること

| フェーズ | テーマ | Snowflake 機能 |
|---------|--------|--------------|
| **Block 1A** | 有報 PDF の構造化処理 | `AI_PARSE_DOCUMENT`, `SPLIT_TEXT_RECURSIVE_CHARACTER`, Cortex Search |
| **Block 1B** | 決算トランスクリプトのセンチメント分析 | `AI_COMPLETE`, `AI_FILTER` |
| **Block 2** | 5ファクターモデル構築と統計検証 | Snowflake Notebook, ML Registry |
| **Block 3** | CVaR ポートフォリオ最適化 SP | Python Stored Procedure, scipy |
| **Block 4** | AI エージェントの自動構築 | Cortex Code, Semantic View, Cortex Agent |
| **Block 5** | Snowflake Intelligence によるデモ | Snowflake Intelligence, Agent Skills |

---

## アーキテクチャ

```
Snowflake Marketplace (無料)
 ├── STOCK_PRICE_TIMESERIES    → 株価・モメンタムファクター
 ├── SEC_REPORT_ATTRIBUTES     → ROE・売上成長（クオリティ/バリューファクター）
 └── EARNINGS_TRANSCRIPTS      → 決算説明会トランスクリプト

リポジトリ同梱 PDF (docs/)
 └── 年次報告書サンプル (SEC 10-K MDA / 有報抜粋)

       ↓ Snowflake Notebook (CPU)

5ファクターモデル                     非構造化データ分析
 ├── Momentum (Jegadeesh & Titman 1993)  ├── AI_PARSE_DOCUMENT → Chunking
 ├── Value    (Revenue Growth / SEC)      ├── Cortex Search (RAG)
 ├── Quality  (ROE - Leverage / SEC)      └── AI_COMPLETE → Sentiment Score
 ├── Volatility (σ逆数 / F&P 2014)
 └── Sentiment (AI_COMPLETE Score)

       ↓ LightGBM + IC 統計検定 (t-stat, p-value, ICIR)

Stored Procedures (エージェントのカスタムツール)
 ├── GET_FACTOR_SCORES()   — 5ファクター + モメンタムトレンド + 統計スクリーニング
 └── OPTIMIZE_PORTFOLIO()  — CVaR 最小化 + セクター制約 + Information Ratio

       ↓ Cortex Code (Plan Mode)

Semantic Views (Cortex Analyst)
 ├── FACTOR_ANALYTICS_VIEW     — quantitative_analyzer 相当
 └── FUNDAMENTAL_ANALYTICS_VIEW — financial_analyzer 相当

       ↓

QUANT_PM_AGENT (Cortex Agent × Snowflake Intelligence)
 6 ツール統合: ファクターSP × 最適化SP × 2 Semantic View × 2 Cortex Search
```

---

## ファイル構成

```
quant-portfolio-optimization-snowflake-hol/
├── README.md
├── setup.sql                              ← 環境構築（API/Git Integration含む）
├── notebooks/
│   └── quant_portfolio_hol.ipynb          ← メインハンズオンノートブック
├── docs/
│   └── toyota_semiannual_2025_09.pdf      ← トヨタ自動車 半期報告書（2025年9月期）
└── skills/
    └── portfolio_optimizer/
        └── SKILL.md                       ← Cortex Agent Skills 定義ファイル
```

> **なぜ PDF は Toyota のみ？**  
> 米国株（NVDA/AAPL/JPM 等）の財務データ・決算トランスクリプトは  
> **Snowflake Public Data (Free)** に含まれる `SEC_REPORT_ATTRIBUTES` と `EARNINGS_TRANSCRIPTS` で完全にカバーされます。  
> PDF 処理パイプライン（`AI_PARSE_DOCUMENT` → Chunking → Cortex Search）のデモには  
> **日本語文書であるトヨタの半期報告書**を使用することで、  
> 「英語・日本語問わず同じパイプラインが機能する」ことを示します。

---

## 前提条件

- Snowflake トライアルアカウント (AWS US East 推奨)
- ACCOUNTADMIN ロール
- Snowflake Marketplace からの無料データ取得権限

### 取得が必要な Marketplace データ

1. **Snowflake Public Data (Free)**  
   [https://app.snowflake.com/marketplace/listing/GZTSZ290BV255](https://app.snowflake.com/marketplace/listing/GZTSZ290BV255)  
   → 株価・SEC財務データ・決算トランスクリプトを含む

2. **Snowflake Public Data Cortex Knowledge Extension (Earning Call Transcript)**  
   Marketplace 検索: `cortex knowledge extension`  
   → 決算コールトランスクリプトの事前構築済み Cortex Search（オプション）

---

## クイックスタート

```
1. このリポジトリをクローンまたはダウンロード
2. Snowflake Marketplace からデータを取得（上記2件）
3. notebooks/quant_portfolio_hol.ipynb を Snowflake Workspaces にアップロード
4. セルを順番に実行（Block 0 → Block 5）
5. Snowflake Intelligence でデモプロンプトを試す
```

---

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 非構造化データ処理 | `AI_PARSE_DOCUMENT`, `AI_COMPLETE`, `AI_FILTER`, `SPLIT_TEXT_RECURSIVE_CHARACTER` |
| 機械学習 | LightGBM, scikit-learn, scipy (conda 内蔵、外部接続不要) |
| ML 管理 | Snowflake ML Registry |
| セマンティック検索 | Cortex Search, Cortex Knowledge Extensions |
| 自然言語 SQL | Cortex Analyst (Semantic View) |
| AI コーディング | Cortex Code in Snowsight (Plan Mode) |
| エージェント | Cortex Agent, Snowflake Intelligence, Agent Skills |

---

## ファクターモデルの理論的背景

| ファクター | 理論的根拠 | 計算方法 |
|-----------|----------|---------|
| **Momentum** | Jegadeesh & Titman (1993) — 12M-1M クロスセクショナルリターン | `ret_12m - ret_1m` |
| **Value** | Fama & French (1992) — 低バリュエーション銘柄のプレミアム | Revenue Growth (SEC) |
| **Quality** | Asness et al. (2019) — ROE・低レバレッジ銘柄のプレミアム | `ROE - Leverage × 0.3` |
| **Low Volatility** | Frazzini & Pedersen (2014) — BAB ファクター | `-σ_252` (符号反転) |
| **Sentiment** | Tetlock (2007) — テキスト感情のリターン予測力 | AI_COMPLETE スコア |

### 統計的有意性の評価指標

| 指標 | 意味 | 実用水準 |
|------|------|---------|
| **IC (Information Coefficient)** | ファクタースコアと翌月リターンの Spearman 相関 | IC > 0.05 |
| **ICIR** | IC の平均 / IC の標準偏差 | ICIR > 0.5 |
| **t-統計量** | IC がゼロと有意差があるか | t > 2.0 (5% 有意) |
| **% IC > 0** | ICがプラスになる月の割合 | > 55% |

---

## ポートフォリオ最適化の理論的背景

**CVaR (Conditional Value-at-Risk)** 最小化  
Rockafellar & Uryasev (2000) に基づく線形プログラミング定式化

$$\text{minimize} \quad \text{CVaR}_{\alpha}(w) = \frac{1}{(1-\alpha)T} \sum_{t: r_t \leq \text{VaR}_{\alpha}} (-r_t^p)$$

制約条件:
- $\sum_i w_i = 1$ （フルインベスト）
- $w_{\min} \leq w_i \leq w_{\max}$ （個別銘柄ウェイト制約）
- $\sum_{i \in S} w_i \leq w_{\text{sector}}$ （セクター集中制約）

---

## 参考資料

- [Snowflake Quant Research Developer Guide](https://www.snowflake.com/en/developers/guides/quantitative-research-with-ai-functions-and-cortex-code/)
- [Cortex Agents Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Snowflake ML Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)
- [Agent Skills Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-skills)
- [LQG Event HOL (English)](https://github.com/sfc-gh-mstellwall/lqg_event_april_2026)
- [Agentic AI for Asset Management (Japanese)](https://github.com/sfc-gh-kmotokubota/sfguide-agentic-ai-for-asset-management-ja)

---

*本資料のコードは公開データのみを使用しています。  
Snowflake Inc. は本ハンズオンで紹介する投資手法の有効性を保証するものではありません。*

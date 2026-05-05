---
name: portfolio-optimizer
description: >
  ファクタースクリーニングとCVaR最適化を統合してポートフォリオを構築するスキル。
  「ポートフォリオを最適化して」「CVaRを最小化するポートフォリオ」などのリクエストで発動。
  5ファクタースクリーニング → センチメント確認 → CVaR最適化 → リスク指標表示の順で実行する。
---

# いつ使うか

- ユーザーがポートフォリオの構築・最適化を求めている
- CVaR最小化・リスク管理・アロケーションに関する質問
- ファクタースクリーニングとポートフォリオ構築を統合するタスク
- 「セクター制約付きで最適ポートフォリオを作って」「Information Ratio も出して」

# このスキルの機能

1. **5ファクタースクリーニング** → モメンタムトレンド・統計的有意性でトップ銘柄を特定
2. **センチメント確認** → 決算トランスクリプトの AI 分析と照合
3. **CVaR 最適化** → セクター制約・ポジションサイジング込みでポートフォリオを構築
4. **結果レポート** → 配分・リスク指標（CVaR/Sharpe/IR/最大ドローダウン）を表示

# 実行手順

## Step 1: GET_FACTOR_SCORES でスクリーニング

```sql
CALL QUANT_HOL_DB.QUANT.GET_FACTOR_SCORES(
    10,     -- TOP_N
    0.3,    -- MIN_MOMENTUM_Z
    0.0,    -- MIN_QUALITY_Z
    TRUE,   -- MOMENTUM_IMPROVING
    TRUE,   -- SENTIMENT_FILTER
    0.10    -- MIN_IC_SIGNIFICANCE
);
```

## Step 2: OPTIMIZE_PORTFOLIO で構築

スクリーニングで得た `top_tickers` を使用:

```sql
CALL QUANT_HOL_DB.PM.OPTIMIZE_PORTFOLIO(
    [<top_tickers>],
    0.25,   -- MAX_WEIGHT
    0.03,   -- MIN_WEIGHT
    0.95,   -- CVaR_CONFIDENCE
    252,    -- LOOKBACK_DAYS
    0.40,   -- MAX_SECTOR_WEIGHT (テック集中40%上限)
    0.0     -- TARGET_VOLATILITY (制約なし)
);
```

## Step 3: 結果の解釈

| 指標 | 読み方 | 目安 |
|------|--------|------|
| CVaR 95% | 最悪5%シナリオの平均損失 | 低いほど良い |
| Sharpe Ratio | リスク調整後リターン | > 1.0 が実用水準 |
| Information Ratio | アクティブリターンの効率性 | > 0.5 が実用水準 |
| Max Drawdown | 最大下落率 | 小さいほど安定 |

# 制約ガイドライン（デフォルト）

| パラメータ | デフォルト | 説明 |
|-----------|----------|------|
| max_weight | 0.25 | 個別銘柄上限 25% |
| min_weight | 0.03 | 最小 3%（小ポジション排除） |
| cvar_confidence | 0.95 | 95% 信頼水準 |
| max_sector_weight | 0.40 | セクター集中上限 40% |
| lookback_days | 252 | 直近 1 年データ |

# AGENTS.md - Quant Portfolio Optimization ハンズオン

## プロジェクト概要

米国株の5ファクターモデル（Momentum / Value / Quality / Low Volatility / Sentiment）を用いた
クオンツポートフォリオ最適化を Snowflake の AI/ML 機能で構築するハンズオンコンテンツです。

ファクター計算 → 統計検証（IC/ICIR/t-stat） → LightGBM予測 → CVaR最適化 → Cortex Agent 構築
までを 1 つのノートブックで段階的に体験します。

## 言語に関する注意事項

このプロジェクトは**日本語話者向けのハンズオン**です。以下の点を厳守してください：

- **会話・応答はすべて日本語**で行うこと
- **コード内のコメントは日本語**で記述すること
- **処理ログ・ステータスメッセージは日本語**で出力すること
- **エラーメッセージの説明やトラブルシューティングも日本語**で行うこと
- **マークダウンセルの説明文は日本語**で記述すること
- SQL 文や Python コードのキーワード・関数名はそのままで構いませんが、**説明やコメントは日本語**にすること
- **ユーザーへの質問案・選択肢も日本語**で提示すること

## プロジェクト構成

```
/
├── setup.sql                              # 環境セットアップ（DB/スキーマ/ステージ/Git連携）
├── notebooks/
│   └── quant_portfolio_hol.ipynb          # メインノートブック（Block 0〜5）
├── docs/
│   └── toyota_semiannual_2025_09.pdf      # トヨタ半期報告書（PDF処理デモ用）
├── skills/
│   └── portfolio_optimizer/
│       └── SKILL.md                       # Cortex Agent Skill 定義
├── README.md                              # 全体ドキュメント（理論・数学・アーキテクチャ）
└── AGENTS.md                              # このファイル
```

## Snowflake 環境

- **データベース**: `QUANT_HOL_DB`
- **スキーマ**: `QUANT`（ファクター分析）/ `PM`（ポートフォリオ管理）/ `AI`（エージェント・Semantic View）
- **ウェアハウス**: `QUANT_HOL_WH`（Medium）
- **ステージ**: `QUANT_HOL_DB.QUANT.ANNUAL_REPORTS`（PDF）/ `QUANT_HOL_DB.AI.SKILL_STAGE`（Skills）
- **Marketplace データ**: `SNOWFLAKE_PUBLIC_DATA_PAID`（株価・SEC・トランスクリプト）
- **CKE**: `SNOWFLAKE_PUBLIC_DATA_CORTEX_KNOWLEDGE_EXTENSION_EARNING_CALL_TRANSCRIPT_AND_DOCUMENTATION`

## ノートブック構成（Block 0〜5）

| Block | 内容 | 主要機能 |
|-------|------|----------|
| **0** | 環境セットアップ・コスト制御 | Resource Monitor, Cross-Region |
| **1A** | 有報PDF → Cortex Search | AI_PARSE_DOCUMENT, SPLIT_TEXT_RECURSIVE_CHARACTER |
| **1B** | 決算トランスクリプト → センチメント | AI_COMPLETE, AI_FILTER, PROMPT() |
| **2** | 5ファクター計算・統計検証・ML | IC/ICIR/t-stat, LightGBM, ML Registry |
| **3** | ストアドプロシージャ | GET_FACTOR_SCORES (リアルタイム推論), OPTIMIZE_PORTFOLIO (CVaR) |
| **4** | Cortex Agent 構築 | Semantic View × 2, Cortex Search × 2, SP × 2 |
| **4.5** | Agent Skills 追加 | SKILL.md アップロード・GUI登録 |
| **5** | Snowflake Intelligence デモ | Artifacts（チャート保存・共有・リフレッシュ） |

## Cortex Code で使える主要コマンド

### 基本操作

| コマンド | 説明 |
|----------|------|
| `/help` | ヘルプを表示 |
| `/clear` | 会話履歴をクリア |
| `/compact` | コンテキストウィンドウを圧縮 |
| `/agents` | 利用可能なエージェント一覧 |

### Plan Mode（設計→実装）

Cortex Code で複雑なタスクを依頼する場合は **Plan Mode** を使うと精度が上がります:

```
Plan Mode ON で以下を実行してください:
QUANT_HOL_DB.AI スキーマに Semantic View を作成...
```

Plan Mode では Cortex Code が実行計画を提示 → 承認後に自動実行します。

### Skill 呼び出し

Snowflake Intelligence で `/` を入力するとスキルが表示されます:

- `/portfolio-optimizer` — ファクタースクリーニング → CVaR最適化の一連フロー

### このハンズオンでの推奨プロンプト例

**ファクタースクリーニング:**
```
バリュー・クオリティが高くモメンタムが改善中の銘柄をスクリーニングして
```

**統計検証:**
```
モデルの統計的有意性（IC、p-value、IR）を確認して
```

**ファンダメンタル検証:**
```
NVIDIAのSEC提出書類から売上成長とマージン拡大を確認して
```

**ポートフォリオ構築:**
```
スクリーニング銘柄でCVaR最小化・テック集中40%以下のポートフォリオを構築して
```

**有報検索（日本語）:**
```
トヨタの事業リスクについて、為替変動や競争環境の記載を教えて
```

## 使用する Snowflake AI/ML 機能一覧

| カテゴリ | 機能 | 用途 |
|----------|------|------|
| **Document AI** | `AI_PARSE_DOCUMENT` | PDF → テキスト抽出（LAYOUT モード） |
| **Text Processing** | `SPLIT_TEXT_RECURSIVE_CHARACTER` | チャンク分割（1000文字/200重複） |
| **Cortex Search** | Cortex Search Service | 有報・トランスクリプトのセマンティック検索 |
| **LLM** | `AI_COMPLETE` | センチメント構造化・ファクター分析 |
| **Sentiment** | `AI_SENTIMENT` | 1行SQLでセンチメントスコア（-1〜1）取得 |
| **Classification** | `AI_CLASSIFY` | トランスクリプトを投資シグナルに分類 |
| **Aggregation** | `AI_AGG` | 複数銘柄を横断集約し市場ムード要約 |
| **AI Filter** | `AI_FILTER` + `PROMPT()` | 地政学リスク銘柄スクリーニング |
| **ML** | Snowflake ML Registry | LightGBM モデルの登録・バージョニング・推論 |
| **Semantic Layer** | Semantic View | Text-to-SQL（ファクター・ファンダメンタル） |
| **Agent** | Cortex Agent | 6ツール統合オーケストレーション |
| **Skills** | Agent Skills | SKILL.md による再利用可能ワークフロー |
| **Intelligence** | Snowflake Intelligence | Artifacts（チャート保存・リフレッシュ・共有） |

## トラブルシューティング

| 問題 | 原因 | 対処 |
|------|------|------|
| SEC データ取得失敗 | `COMPANY_IDS` カラム不在 | プロキシファクターに自動フォールバック（正常動作） |
| AI_COMPLETE タイムアウト | テキストが長すぎる | `LEFT(text, 4000)` で切り詰め済み |
| ML Registry モデル未検出 | スキーマ不一致 | SP 内で `database_name='QUANT_HOL_DB', schema_name='PUBLIC'` 指定済み |
| matplotlib 日本語文字化け | フォント未インストール | 英語ラベルに統一済み |
| ALTER AGENT でツール消失 | 既知の制約 | GUI から Skills 追加（ALTER AGENT は使わない） |
| クレジット不足 | トライアルの日次制限 | Resource Monitor 設定済み（300 credits） |

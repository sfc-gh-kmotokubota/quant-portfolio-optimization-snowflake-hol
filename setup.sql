-- ============================================================
-- setup.sql
-- Snowflake Quantitative Portfolio Optimization HOL
-- ============================================================
-- 実行前の確認事項:
--   1. ACCOUNTADMIN ロールで実行すること
--   2. Snowflake Marketplace から "Snowflake Public Data (Free)" を取得済みであること
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- SECTION 1: データベース・スキーマ・ウェアハウス
-- ============================================================

CREATE DATABASE  IF NOT EXISTS QUANT_HOL_DB;
CREATE SCHEMA    IF NOT EXISTS QUANT_HOL_DB.QUANT;
CREATE SCHEMA    IF NOT EXISTS QUANT_HOL_DB.PM;
CREATE SCHEMA    IF NOT EXISTS QUANT_HOL_DB.AI;

CREATE WAREHOUSE IF NOT EXISTS QUANT_HOL_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE
    COMMENT        = 'Quant Portfolio Optimization HOL Warehouse';

-- ============================================================
-- SECTION 2: コストコントロール
-- ============================================================

CREATE OR REPLACE RESOURCE MONITOR QUANT_HOL_MONITOR
    WITH CREDIT_QUOTA = 300
    FREQUENCY        = MONTHLY
    START_TIMESTAMP  = IMMEDIATELY
    TRIGGERS
        ON 50  PERCENT DO NOTIFY
        ON 80  PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE QUANT_HOL_WH
    SET RESOURCE_MONITOR = QUANT_HOL_MONITOR;

-- ============================================================
-- SECTION 3: Cortex AI 設定（クロスリージョン推論を有効化）
-- ============================================================
-- AI_COMPLETE / AI_PARSE_DOCUMENT 等の利用に必要
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

-- ============================================================
-- SECTION 4: ステージ作成
-- ============================================================

-- 有報 PDF 格納ステージ
CREATE STAGE IF NOT EXISTS QUANT_HOL_DB.QUANT.ANNUAL_REPORTS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT   = '年次報告書・有報 PDF 格納場所';

-- Agent Skills 格納ステージ
CREATE STAGE IF NOT EXISTS QUANT_HOL_DB.AI.SKILL_STAGE
    COMMENT = 'Cortex Agent Skills (SKILL.md) 格納場所';

-- ============================================================
-- SECTION 5: GitHub API Integration
-- ============================================================
-- GitHub に接続するための API Integration
-- プライベートリポジトリへのアクセスに使用する

CREATE OR REPLACE API INTEGRATION QUANT_HOL_GITHUB_INTEGRATION
    API_PROVIDER          = git_https_api
    API_ALLOWED_PREFIXES  = ('https://github.com/sfc-gh-kmotokubota')
    ENABLED               = TRUE;

-- API Integration の確認
DESCRIBE API INTEGRATION QUANT_HOL_GITHUB_INTEGRATION;

-- ============================================================
-- SECTION 6: Git Repository Integration
-- パブリックリポジトリのため認証不要
-- ============================================================

CREATE OR REPLACE GIT REPOSITORY QUANT_HOL_DB.QUANT.QUANT_HOL_REPO
    API_INTEGRATION = QUANT_HOL_GITHUB_INTEGRATION
    ORIGIN          = 'https://github.com/sfc-gh-kmotokubota/quant-portfolio-optimization-snowflake-hol'
    COMMENT         = 'Quant Portfolio Optimization HOL Repository (Public)';

-- Git リポジトリの最新状態を取得
ALTER GIT REPOSITORY QUANT_HOL_DB.QUANT.QUANT_HOL_REPO FETCH;

-- Git リポジトリ内のファイル確認
LS @QUANT_HOL_DB.QUANT.QUANT_HOL_REPO/branches/main/;

-- ============================================================
-- SECTION 7: Git → Internal Stage への PDF コピー
-- ============================================================
-- docs/ 配下の年次報告書 PDF を内部ステージにコピー

COPY FILES
    INTO @QUANT_HOL_DB.QUANT.ANNUAL_REPORTS_STAGE
    FROM @QUANT_HOL_DB.QUANT.QUANT_HOL_REPO/branches/main/docs/;

-- コピー結果の確認
LS @QUANT_HOL_DB.QUANT.ANNUAL_REPORTS_STAGE;

-- ============================================================
-- SECTION 8: Git → Internal Stage への SKILL.md コピー
-- ============================================================

COPY FILES
    INTO @QUANT_HOL_DB.AI.SKILL_STAGE
    FROM @QUANT_HOL_DB.QUANT.QUANT_HOL_REPO/branches/main/skills/;

-- コピー結果の確認
LS @QUANT_HOL_DB.AI.SKILL_STAGE/;

-- ============================================================
-- SECTION 9: ノートブック用のロール・権限設定
-- ============================================================

-- ハンズオン参加者ロール作成（任意）
CREATE ROLE IF NOT EXISTS QUANT_HOL_ROLE;

-- 基本権限付与
GRANT USAGE ON DATABASE  QUANT_HOL_DB         TO ROLE QUANT_HOL_ROLE;
GRANT USAGE ON SCHEMA    QUANT_HOL_DB.QUANT   TO ROLE QUANT_HOL_ROLE;
GRANT USAGE ON SCHEMA    QUANT_HOL_DB.PM      TO ROLE QUANT_HOL_ROLE;
GRANT USAGE ON SCHEMA    QUANT_HOL_DB.AI      TO ROLE QUANT_HOL_ROLE;
GRANT USAGE ON WAREHOUSE QUANT_HOL_WH         TO ROLE QUANT_HOL_ROLE;

-- オブジェクト作成権限
GRANT CREATE TABLE      ON SCHEMA QUANT_HOL_DB.QUANT TO ROLE QUANT_HOL_ROLE;
GRANT CREATE TABLE      ON SCHEMA QUANT_HOL_DB.PM    TO ROLE QUANT_HOL_ROLE;
GRANT CREATE TABLE      ON SCHEMA QUANT_HOL_DB.AI    TO ROLE QUANT_HOL_ROLE;
GRANT CREATE PROCEDURE  ON SCHEMA QUANT_HOL_DB.QUANT TO ROLE QUANT_HOL_ROLE;
GRANT CREATE PROCEDURE  ON SCHEMA QUANT_HOL_DB.PM    TO ROLE QUANT_HOL_ROLE;
GRANT CREATE CORTEX SEARCH SERVICE ON SCHEMA QUANT_HOL_DB.QUANT TO ROLE QUANT_HOL_ROLE;
GRANT CREATE CORTEX SEARCH SERVICE ON SCHEMA QUANT_HOL_DB.AI    TO ROLE QUANT_HOL_ROLE;
GRANT CREATE SEMANTIC VIEW ON SCHEMA QUANT_HOL_DB.AI TO ROLE QUANT_HOL_ROLE;
GRANT CREATE AGENT      ON SCHEMA QUANT_HOL_DB.AI    TO ROLE QUANT_HOL_ROLE;

-- ステージ権限
GRANT READ, WRITE ON STAGE QUANT_HOL_DB.QUANT.ANNUAL_REPORTS_STAGE TO ROLE QUANT_HOL_ROLE;
GRANT READ, WRITE ON STAGE QUANT_HOL_DB.AI.SKILL_STAGE             TO ROLE QUANT_HOL_ROLE;

-- Git リポジトリ参照権限
GRANT USAGE ON INTEGRATION QUANT_HOL_GITHUB_INTEGRATION       TO ROLE QUANT_HOL_ROLE;
GRANT READ  ON GIT REPOSITORY QUANT_HOL_DB.QUANT.QUANT_HOL_REPO TO ROLE QUANT_HOL_ROLE;

-- Marketplace データへの参照権限（取得済みであること）
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_PUBLIC_DATA_FREE TO ROLE QUANT_HOL_ROLE;

-- Snowflake ML 機能
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE QUANT_HOL_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.ML_RUNTIME_WAREHOUSE_USER TO ROLE QUANT_HOL_ROLE;

-- ユーザーへのロール付与（必要に応じてコメントを外す）
-- GRANT ROLE QUANT_HOL_ROLE TO USER <username>;

-- ============================================================
-- SECTION 10: セットアップ確認
-- ============================================================

-- 作成したオブジェクト一覧
SELECT 'DATABASE'  AS OBJECT_TYPE, DATABASE_NAME   AS NAME FROM INFORMATION_SCHEMA.DATABASES     WHERE DATABASE_NAME  = 'QUANT_HOL_DB'
UNION ALL
SELECT 'WAREHOUSE', WAREHOUSE_NAME                         FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSES WHERE WAREHOUSE_NAME = 'QUANT_HOL_WH'
ORDER BY 1;

-- ステージ確認
SHOW STAGES IN SCHEMA QUANT_HOL_DB.QUANT;
SHOW STAGES IN SCHEMA QUANT_HOL_DB.AI;

-- Git リポジトリ確認
SHOW GIT REPOSITORIES IN SCHEMA QUANT_HOL_DB.QUANT;

-- セットアップ完了メッセージ
SELECT 'Setup complete! Proceed to quant_portfolio_hol.ipynb' AS STATUS,
       CURRENT_TIMESTAMP() AS COMPLETED_AT;

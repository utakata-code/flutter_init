# Flutter Core Architecture Template

## 概要

このドキュメントは、Flutter プロジェクトにおける Core ライブラリの構成とガイドラインを提供します。
`utakata/scripts/generate/generate_core.sh` を使ってアプリ共通の基盤となるディレクトリを生成し、フィーチャー開発に依存しない横断的関心事（ルーティング、テーマ、API、例外、データベースなど）を整理します。

Core は「どのフィーチャーからも参照可能な共通モジュール」であり、UI や各フィーチャー固有のロジックを含めません。Clean Architecture の各層から安全に参照できるよう、責務を最小限に保ちます。

## 生成されるディレクトリ構造（Core）

`utakata/scripts/generate/generate_core.sh` により、以下の構造が生成されます。

```
lib/core/
├── routing/          # ルーティング設定（GoRouter 等）
│   └── path/         # 画面パス・ルート定義（定数・型）
├── theme/            # テーマ設定（Design Tokens, Color/Typo 等）
├── api/              # API クライアント設定（Dio 等の共通設定）
├── env/              # 環境変数・アプリ設定（環境ごとの設定管理）
├── exceptions/       # 共通例外（基底例外・ネットワーク・ストレージ）
├── database/         # DB 接続・共通ユーティリティ
│   ├── table/        # テーブル定義（Drift スキーマ等）
│   └── migration/    # マイグレーションファイル（バージョン別）
```

補足:
- 共通例外の詳細は `utakata/guides/lib/core/exceptions/exceptions_guide.md` を参照してください。
- 例外ファイルの生成は `utakata/scripts/generate/init_core_exceptions.sh` で自動化できます。

## 役割と責務（ディレクトリ別）

### routing/
- アプリ全体のルーティング設定（例：`GoRouter` の初期化、リダイレクト方針）
- `path/` には画面ごとのパス定数・型を配置（UI を含めない）
- フィーチャー側の画面はパス定義を参照するだけに留める

### theme/
- カラーパレット、タイポグラフィ、スペーシング等の Design Tokens
- `ThemeData` 構成に必要な共通値／拡張（拡張は UI コンポーネントに依存しない範囲）
- フィーチャー固有のスタイルは各フィーチャー配下に定義し、Core は共通化に専念

### api/
- HTTP クライアントの共通設定（ベース URL、タイムアウト、インターセプタ）
- リトライ・エラーハンドリングの基本方針（詳細は各 DataSource で上書き可）
- 具体的な API エンドポイント定義はフィーチャー側の DataSource で行う

### env/
- 環境変数の定義と管理（開発・ステージング・本番環境の切り替え）
- API キーやベース URL などの環境依存値を集約
- `--dart-define` や `.env` ファイルとの連携
- フィーチャー固有の設定は含めず、アプリ全体の環境設定のみ

### exceptions/
- 共通基底例外（`BaseException`）とネットワーク／ストレージ例外を提供
- 層ごとの取り扱いは `core/exceptions/exceptions_guide.md` に準拠
- 例外の変換箇所は Repository／UseCase に集約し、UI へはドメイン語彙で伝達

### database/
- DB 接続の初期化、共通ユーティリティ（パス、暗号化、マイグレーション方針）
- `table/` にテーブル定義（例：Drift テーブル）を配置し、フィーチャー間で再利用可能に
- `migration/` にバージョン別のマイグレーションファイルを配置し、スキーマ変更の履歴を管理
- 具体的な CRUD はフィーチャー側の Repository／DataSource で実装

## 禁止事項（Core）

- UI コンポーネント／画面ロジックの配置（Presentation 層へ）
- フィーチャー固有のドメインロジックや語彙の混入（Feature 配下へ）
- フィーチャー配下から Core を参照する循環依存の発生（Core → Feature の参照は不可）

## 命名・配置指針

- ルーティング：`routing/path/` に画面パス定数や型をまとめ、`routing/` で Router 本体を構成
- テーマ：`theme/` に `colors.dart`, `typography.dart`, `spacing.dart` などを分割
- 環境変数：`env/` に `env.dart`, `app_config.dart` などを配置
- API：`api/` に `http_client.dart`, `interceptors/` などを配置
- DB：`database/` に `database.dart`, `table/` に各テーブル定義, `migration/` にバージョン別マイグレーション
- 例外：`exceptions/` はファイル名 `{種類}_exception.dart`、クラス名 `{種類}Exception`

## 参照ガイド

- フィーチャー側は Core のみを参照し、Core はフィーチャーを参照しない
- インフラ層（DataSource）は Core の `api/`, `database/`, `exceptions/` を積極利用
- Presentation 層は `routing/path` によるパス定義を参照し、UI 文言は UI 側で確定

## 導入手順

1. Core 構造の生成
   - `utakata/scripts/generate/generate_core.sh --yes`
2. 共通例外ファイルの生成（必要時）
   - `utakata/scripts/generate/init_core_exceptions.sh --yes`
3. 依存関係の追加（必要時）
   - `utakata/scripts/setup/add_dependencies.sh --yes`

これらのスクリプトにより、プロジェクトの基盤が自動生成され、フィーチャー開発に集中できる環境が整備されます。
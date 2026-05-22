# アプリケーション仕様書

> このファイルは第一段階（仕様策定）で更新する仕様書です。

## メタ情報
- プロジェクト名: utakata studio
- バージョン: 0.1.0
- 最終更新日: 2026-05-22
- 作成者: AI + haruma

## 概要

### コンセプト

utakata studio は **utakata CLI のすべての操作を GUI から実行するためのビジュアルフロントエンド** である。

utakata のコンセプトは **「人間と AI を区別しない共創」** — CLI も GUI もともにインターフェイスであり、どちらから操作しても同じワークフローが実行される。utakata studio はその **GUI インターフェイス** として機能する。

CLI がプロセスの標準入出力を通じてフィードバックを返すように、studio はリアクティブな Flutter UI を通じてフィードバックを返す。コマンドの実行結果はリアルタイムに画面に反映され、ファイルシステムの変更は自動検知される。

### 目的（解決したい課題）
- `arch_definition.yaml` は 500 行近い大規模 YAML であり、テキストエディタだけでは構造の全体像が把握しにくい
- utakata CLI のコマンド体系（9 コマンド + サブコマンド）を覚えなくても GUI から直感的に操作したい
- コマンド実行結果（validate の違反一覧、diff の差分、status の統計）を視覚的に把握したい
- AI エージェントと人間が同じプロジェクト上で共創する際に、操作の透明性を確保したい

### 背景・文脈
- utakata は spec-driven な Flutter 開発 CLI ツール（`utakata_code` パッケージ）
- utakata studio は utakata 自身をドッグフーディングして構築する最初の GUI プロジェクト
- `utakata_code` パッケージのドメインモデルを直接再利用する
- Desktop native（Windows / macOS / Linux）と Web サーバー（localhost）の両方をサポートする

## ターゲットユーザー・ペルソナ
- 主要ペルソナ:
  - utakata を使って Flutter プロジェクトを開発するエンジニア
  - AI エージェント（CLI 経由で操作するが、結果を studio で可視化する）
- ユーザー課題:
  - アーキテクチャ定義の全体像を素早く把握したい
  - YAML 編集時にリアルタイムで構文チェックしたい
  - utakata コマンドを GUI からワンクリックで実行したい
  - コマンド実行のログとフィードバックを一箇所で確認したい
- 利用シナリオ:
  1. **プロジェクト初期**: `utakata create` → アーキテクチャを studio で選択・カスタマイズ
  2. **フィーチャー追加**: `feature_request.yaml` を GUI で編集 → `plan` → `feature init` をワンクリック
  3. **構造検証**: `validate` / `diff` / `check` の結果を色分け表示で確認
  4. **日常開発**: `status` ダッシュボードで進捗を俯瞰、`scan` で構造を最新化

## ユースケース一覧

### utakata CLI コマンドとの対応表

| CLI コマンド | UC | Studio での操作 |
|---|---|---|
| `utakata create <name>` | UC-01 | 新規プロジェクト作成ウィザード |
| `utakata arch list` | UC-02 | アーキテクチャ一覧の表示 |
| `utakata arch show [id]` | UC-03 | アーキテクチャ定義の詳細ビュー（レイヤー・命名規則・ガイド） |
| `utakata arch export [id] [path]` | UC-04 | アーキテクチャ定義の YAML エクスポート |
| `utakata arch create [id]` | UC-05 | カスタムアーキテクチャのボイラープレート生成 |
| `utakata plan` | UC-06 | feature_request.yaml → plan_architecture.yaml の生成 |
| `utakata feature add <name>` | UC-07 | 単一フィーチャーの追加（フォーム入力） |
| `utakata feature init` | UC-08 | 全フィーチャーの一括生成 |
| `utakata scan` | UC-09 | 現在のディレクトリ構造をスキャン → スナップショット保存 |
| `utakata validate` | UC-10 | 命名規則・構造のバリデーション → 違反一覧表示 |
| `utakata diff` | UC-11 | 計画 vs 実体の差分表示（Missing / Extra） |
| `utakata check` | UC-12 | ヘルスチェック（diff + exit code） |
| `utakata status` | UC-13 | プロジェクト総合ステータスのダッシュボード表示 |
| — | UC-14 | arch_definition.yaml のリアルタイム編集 + バリデーション |
| — | UC-15 | feature_request.yaml の GUI エディタ |

## スコープ定義

### In-Scope（v0.1.0 対象）
- **コア機能**:
  - UC-14: arch_definition.yaml のロード・リアルタイム編集・バリデーション
  - UC-03: アーキテクチャ定義の詳細ビュー（レイヤー構造ビジュアライザ）
  - ファイル保存
- **基本 UI**:
  - 3 ペイン構成（サイドバー / YAML エディタ / ビジュアライザ）
  - ダークテーマ（プレミアムデザイン）
  - ウィンドウ制御（Desktop native）
- **プラットフォーム**:
  - Desktop native（Windows / macOS / Linux）
  - Web（localhost サーバー）

### In-Scope（v0.2.0 予定）
- UC-06 〜 UC-08: plan / feature add / feature init の GUI 実行
- UC-09 〜 UC-12: scan / validate / diff / check の GUI 実行 + 結果表示
- UC-13: status ダッシュボード
- UC-15: feature_request.yaml の GUI エディタ
- コマンド実行ログのリアルタイムストリーム表示

### In-Scope（v0.3.0 予定）
- UC-01: 新規プロジェクト作成ウィザード
- UC-02, UC-04, UC-05: アーキテクチャ管理の完全 GUI 化
- ファイルシステム監視（FileSystemEntity.watch）による自動リフレッシュ

### Out-of-Scope
- モバイル（iOS / Android）対応
- マルチプロジェクト同時管理
- ユーザー認証・マルチユーザー
- リモートサーバーへの接続

## 機能要件（機能定義）

### F-01: utakata CLI ブリッジ
- 説明: utakata CLI コマンドを Dart の `Process.run` 経由で実行し、stdout/stderr をリアルタイムにキャプチャする共通基盤
- 受け入れ基準: 任意の utakata コマンドを非同期で実行でき、出力がストリームとして取得できること
- 依存関係: dart:io (Process), utakata CLI がシステムにインストール済みであること

### F-02: arch_definition.yaml ロード＆表示
- 説明: プロジェクトの `AI/architecture/arch_definition.yaml` をロードし、テキストエディタに表示する
- 受け入れ基準: アプリ起動時に自動ロードされ、テキストが編集可能な状態で表示される
- 依存関係: yaml パッケージ、dart:io

### F-03: リアルタイムバリデーション
- 説明: テキスト変更時にリアルタイムで YAML パース → 構文チェックを実行し、結果をサイドバーに表示
- 受け入れ基準: エラー時は赤色ステータス + エラーメッセージ、正常時は緑色 + 統計情報が表示される
- 依存関係: utakata_code のドメインモデル

### F-04: レイヤー構造ビジュアライザ
- 説明: パースされた layers をグラデーションカードで階層表示し、各レイヤーのディレクトリ構造を展開表示する
- 受け入れ基準: 全レイヤーがカラフルなカードで描画され、依存方向の矢印が表示される
- 依存関係: F-03 のパース結果

### F-05: ファイル保存
- 説明: 編集した YAML をファイルに上書き保存する
- 受け入れ基準: 保存ボタン押下で元ファイルが更新される
- 依存関係: dart:io

### F-06: サイドバー
- 説明: プロジェクト情報、utakata コマンド群へのナビゲーション、バリデーションステータス、構造統計を表示
- 受け入れ基準: 各セクションが適切にグルーピングされ、ステータスがアニメーション付きで切り替わる
- 依存関係: F-03 の状態

## 画面設計（概要）

### 主要画面
- **StudioHomePage**: 3 ペイン構成のメイン画面
  - 左ペイン（280px 固定）: サイドバー — ロゴ、ナビゲーション、バリデーションステータス、構造統計
  - 中央ペイン（flex: 5）: YAML エディタ — ヘッダーバー（保存・リロードボタン）+ テキストフィールド
  - 右ペイン（flex: 4）: ビジュアライザ — レイヤー構造のグラフィカル描画

### 画面遷移（v0.2.0 以降）
- サイドバーのナビゲーションで以下の画面を切り替え:
  - **Editor**: arch_definition.yaml 編集 + ビジュアライザ
  - **Features**: feature_request.yaml 編集 + plan / feature init 実行
  - **Health**: validate / diff / check の結果表示
  - **Dashboard**: status 表示

### ナビゲーション原則
- 3 ペインの情報が常に連動（YAML 編集 → バリデーション更新 → ビジュアライザ更新）
- CLI コマンドの実行結果はリアクティブに UI へ反映される
- 人間が GUI で操作しても、AI が CLI で操作しても、同じファイルが更新され同じ結果が得られる

## データ要件

### エンティティ定義
- `YamlValidationResultEntity`: yamlContent(String), isValid(bool), errorMessage(String?), layers(List), namingRules(List), coreModules(List), guides(List)
- utakata_code から再利用: `LayerDefinitionEntity`, `NamingRuleEntity`, `CoreModuleEntity`, `GuideEntity`
- `CommandExecutionResult`（v0.2.0）: command(String), exitCode(int), stdout(String), stderr(String), duration(Duration)

### バリデーション要件
- YAML 構文チェック（yaml パッケージ）
- layers / naming_rules / core_modules / guides の各セクションの構造検証

### 永続化・保存戦略
- ファイルシステム直接アクセス（dart:io）
- utakata が管理する YAML / Markdown ファイルがすべての永続化先
- DB 不要（utakata の設計思想: すべてがテキストファイル）

## 非機能要件
- 性能:
  - YAML バリデーションは 100ms 以内に完了すること
  - 500 行の YAML でも UI がカクつかないこと
  - CLI コマンド実行中も UI がブロックされないこと（非同期実行）
- セキュリティ: ローカルファイルのみ操作、ネットワーク通信は localhost のみ
- 可用性: デスクトップアプリとして完全オフラインで動作、Web 版は localhost サーバーとして動作
- アクセシビリティ: ダークテーマをベースとし、コントラスト比を適切に維持

## 技術選定（参照）
- 参照ドキュメント: `AI/architecture/guides/common/technology_stack.md`
- 採用技術:
  - **言語**: Dart 3.11+
  - **フレームワーク**: Flutter（Desktop: Windows, macOS, Linux + Web）
  - **状態管理**: hooks_riverpod + flutter_hooks — リアクティブ UI に最適
  - **データモデル**: freezed（必要に応じて）
  - **YAML パース**: yaml パッケージ
  - **ウィンドウ制御**: window_manager（Desktop 向け）
  - **CLI 連携**: dart:io の Process（utakata コマンドの実行）
  - **ドメインモデル共有**: utakata_code パッケージ（path 依存）
- **不要なもの**:
  - go_router: v0.1.0 では単一画面、v0.2.0 以降もサイドバーナビゲーションで十分
  - drift: DB 不要（utakata はすべてテキストファイルで管理）
  - Firebase: ローカル専用アプリ

## リスク・前提・制約
- 主要リスク:
  - utakata_code のドメインモデル変更時に studio 側の追従が必要
  - Web 版では dart:io（ファイルアクセス、Process 実行）が使えないため、サーバーサイド分離が必要
- 重要前提:
  - **utakata CLI がシステムにインストール済みであること**（`dart pub global activate utakata` または path 依存）
  - utakata_code パッケージが同リポジトリ内に存在し、path 依存で参照可能であること
  - Flutter SDK がインストール済みで Desktop + Web ビルドが有効であること
- 制約条件:
  - utakata のクリーンアーキテクチャ（4 層）に厳密準拠すること
  - utakata CLI のワークフロー（feature_request.yaml → plan → feature init）で構築すること
  - GUI の操作結果と CLI の操作結果は完全に等価であること

## 依存関係
- 外部 API／サービス: なし
- ライブラリ／プラグイン:
  - **utakata_code**（path 依存）— ドメインモデル共有 + CLI 実行
  - **hooks_riverpod** — 状態管理
  - **flutter_hooks** — UI フック
  - **window_manager** — デスクトップウィンドウ制御
  - **yaml** — YAML パース
  - **path** — パス操作
  - **freezed_annotation** — データクラス
  - **build_runner** + **freezed**（dev）— コード生成

## マイルストーン（仕様策定観点）
- M1: 仕様草案提示 → 本ドキュメント（2026-05-22 完了）
- M2: 詳細化・合意 → ユーザーレビュー後に確定
- M3: 第二段階へ移行 → 合意後、構造計画（structure_plan.md）→ feature_request.yaml → utakata plan → utakata feature init

## 受け入れ基準（全体）
- 合意文言: 「仕様内容に合意し、構造計画へ進む」
- 必要ドキュメント: 本仕様書最新版

## 更新履歴
- 2026-05-22: 仕様草案 v1 作成
- 2026-05-22: v2 ブラッシュアップ — コンセプト再定義（全 CLI 操作の GUI 化）、Web 対応追加、utakata CLI 前提条件明記

## 参考・関連
- プロセス詳細（第一段階）: `flutter-stage1-specification` スキル
- アーキテクチャ規約: `AI/architecture/features/ARCHITECTURE.md`
- utakata CLI ヘルプ: `utakata --help`（9 コマンド + サブコマンド）
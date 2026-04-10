# flutter_init

テンプレートと AI スキルを組み合わせ、クリーンアーキテクチャ構成の Flutter アプリを段階的に構築するための、スタータープロジェクトです。`.agent/skills` のスキルシステムにより、仕様策定 → 構造計画 → 実装の 3 フェーズで AI エージェントが開発をガイドします。

## 特徴

- 🧩 **スキルベースのAIガイド** — 9つの専門スキルが開発フェーズごとに適切な案内を提供
- 🔄 **ワークフロー自動化** — スラッシュコマンドでステータス管理・構造検証・静的解析を実行
- 🏗️ **クリーンアーキテクチャ** — Domain → Infrastructure → Application → Presentation の4層構造を厳守
- 📝 **ドキュメント駆動** — 仕様書・構造計画書と実装を常に同期

## 開発プロセス

`.agent/rules/flutter.md` で定義されたルールに従い、3つの開発モードから選択して進行します。

### 開発モード

| モード | 対象 | 参照 |
| --- | --- | --- |
| **モード1**: 新規アプリ開発 | ゼロから構築 | `flutter-development-guide` → 各Stage Skill |
| **モード2**: 既存アプリ（ルール使用中） | 本テンプレート準拠の既存コード | TODO（将来実装予定） |
| **モード3**: 既存アプリ（ルール未使用） | 本テンプレート非準拠の既存コード | TODO（将来実装予定） |

### 3フェーズ開発

1. **仕様策定（Stage1）**
   - 目的、ターゲット、機能、ユースケースをヒアリングし `AI/specs/application_specification.md` を更新します。
   - 技術選定は `AI/guides/technology_stack.md` に従います。
   - スキル: `flutter-stage1-specification`

2. **構造計画（Stage2）**
   - 仕様を反映したファイル一覧を整理し、`AI/specs/structure_plan.md` に記載します。
   - クリーンアーキテクチャのフォルダ構成（`AI/guides/lib/features/features_architecture.md`）を厳守し、新規ディレクトリの追加は禁止です。
   - スキル: `flutter-stage2-structure`

3. **実装（Stage3）**
   - `generate_core.sh` / `init_core_exceptions.sh` により Core 基盤を生成し、機能単位は `generate_feature.sh` でテンプレート化します。
   - Domain → Infrastructure → Application → Presentation の順に各層を実装し、各層完了時に `flutter analyze` を実行します。
   - スキル: `flutter-stage3-implementation`

フェーズ間で仕様変更が発生した場合は、前段階に戻って合意・記録を更新してください。

## AIスキル

`.agent/skills/` に配置された4つのプロセス制御スキルが、AIエージェントの開発ガイドとして機能します。

| スキル | 説明 |
| --- | --- |
| `flutter-development-guide` | 全体フローと3フェーズ開発プロセスのガイド |
| `flutter-stage1-specification` | Stage1: 仕様策定フェーズ |
| `flutter-stage2-structure` | Stage2: 構造計画フェーズ |
| `flutter-stage3-implementation` | Stage3: 実装フェーズ（各層の `*_guide.md` を直接参照） |

## ワークフロー（スラッシュコマンド）

`.agent/workflows/` に定義されたワークフローをAIエージェントとの会話中に実行できます。

| コマンド | 説明 |
| --- | --- |
| `/check_status` | プロジェクトの現在状態をチェックして表示 |
| `/update_status` | `project_status.md` を現在の状態で自動更新 |
| `/generate_structure_snapshot` | `current_structure.md` にスナップショット出力 |
| `/status_report` | check + update + snapshot を一括実行（推奨） |
| `/validate_structure` | ディレクトリ構造の違反を検出 |
| `/detect_changes` | ファイルの変更を検出して `change_history.md` に記録 |
| `/flutter_analyze` | Flutter 静的解析を実行し、問題を修正 |
| `/log_conversation` | 会話ログを記録して次回へ引き継ぐ |

AI エージェントに相談する際は、まず `/status_report` を実行することで、現状把握がスムーズになります。

## プロジェクトステータス管理

AI エージェントとの開発で重要なのは**現在の進行状況を可視化すること**です。`AI/snapshots/` で状態をYAML管理し、`AI/logs/` で会話履歴を記録します。

### ステータスファイル

| ファイル | 役割 |
| --- | --- |
| `AI/snapshots/project_status.yaml` | プロジェクトの現在状態を一元管理 |
| `AI/snapshots/structure_violations.yaml` | ディレクトリ構造と命名規則の違反を記録 |
| `AI/snapshots/change_history.yaml` | ファイルの変更履歴を時系列で記録 |
| `AI/logs/conversation_log.md` | AI エージェントとの会話履歴を記録 |
| `AI/guides/directory_structure_and_naming_rules.md` | ディレクトリ構造とファイル命名規則の完全なリファレンス（静的） |

### CLIからの直接実行

```bash
# 現在のプロジェクト状態をチェック
./AI/scripts/status/check_status.sh

# project_status.md を現在の状態で自動更新
./AI/scripts/status/update_status.sh

# current_structure.md にスナップショット出力
./AI/scripts/status/snapshot.sh

# すべて実行（推奨）
./AI/scripts/status/check_status.sh && AI/scripts/status/update_status.sh -y && AI/scripts/status/snapshot.sh
```

## リポジトリ構成

```
.
├── .agent/
│   ├── rules/                      # AIエージェント向けルール
│   │   └── flutter.md              #   開発モード選択・運用ルール
│   ├── skills/                     # 4つのプロセス制御スキル
│   │   ├── flutter-development-guide/
│   │   ├── flutter-stage1-specification/
│   │   ├── flutter-stage2-structure/
│   │   └── flutter-stage3-implementation/
│   └── workflows/                  # スラッシュコマンド定義
├── AI/
│   ├── guides/                    # 各層の詳細ガイド（*_guide.md）と技術スタック
│   ├── specs/                     # 仕様書・構造計画書（Stage成果物）
│   ├── snapshots/                 # 状態スナップショット（全てYAML）
│   │   └── preview/              #   人間用プレビュー（YAML→MD自動生成）
│   ├── logs/                      # 会話記録
│   └── scripts/                   # シェルスクリプト群
│       ├── setup/                 #   プロジェクト初期化
│       ├── generate/              #   コード生成
│       ├── status/                #   ステータス管理
│       ├── validate/              #   品質検証
│       └── build/                 #   ビルド
├── .gitignore
├── LICENSE
└── README.md
```

## スクリプト一覧

| カテゴリ | スクリプト | 説明 |
| --- | --- | --- |
| **setup/** | `init_project.sh` | `flutter create .` や初期設定を自動化 |
| | `add_dependencies.sh` | `technology_stack.md` 推奨依存を追加 |
| **generate/** | `generate_core.sh` | `lib/core` の基盤構造を生成 |
| | `init_core_exceptions.sh` | 共通例外クラスを生成 |
| | `generate_feature.sh` | フィーチャーディレクトリと雛形ファイルを生成 |
| | `generate_native.sh` | ネイティブプラットフォーム関連のファイルを生成 |
| **status/** | `check_status.sh` | プロジェクト状態をチェックして表示 |
| | `update_status.sh` | `project_status.md` を現在の状態で更新 |
| | `snapshot.sh` | `current_structure.md` にスナップショット出力 |
| | `detect_changes.sh` | ファイルの変更を検出して記録 |
| **validate/** | `validate_structure.sh` | ディレクトリ構造と命名規則の違反を検出 |
| | `find_unused_files.sh` | 未使用ファイルを検出 |
| **build/** | `build_native_ios.sh` | iOS ネイティブビルドを実行 |

`generate_feature.sh` は `-n` でフィーチャー名、`-p` で配置パス（`admin/user/shared/direct`）を指定できます。

```bash
# ユーザー機能としてUserProfileフィーチャーを作成
./AI/scripts/generate/generate_feature.sh -n UserProfile -p user -y

# 共有機能としてAuthフィーチャーを作成
./AI/scripts/generate/generate_feature.sh -n Auth -p shared -y
```

## 実装ガイドライン

- **構造**: `lib/features/<permission>/<feature>/` 配下に Domain → Infrastructure → Application → Presentation を用意します。
- **命名**: Snake case を使用し、各層の責務に合わせたファイル名・クラス名にします。
- **依存**: 上位層から下位層への一方向依存を維持し、共通処理は Core に集約します。
- **状態管理**: Riverpod と hooks を使用し、Presentation 層は基本的に `HookWidget` / `HookConsumerWidget` を採用します。
- **コード生成**: Freezed・Riverpod Generator・Drift などの build_runner ベースツールを適用し、`dart run build_runner build --delete-conflicting-outputs` を利用します。

## セットアップ手順

### 1. 新しいアプリを作成する場合

```bash
# このリポジトリをクローン
git clone https://github.com/utakata-code/flutter_init.git
cd flutter_init

# 新しいブランチを作成して開発開始
git checkout -b feature/your-app-name
```

### 2. 新しいリポジトリとして開発を開始する場合

```bash
# このリポジトリをクローン
git clone https://github.com/utakata-code/flutter_init.git
cd flutter_init

# 既存のGit履歴を削除
rm -rf .git

# 新しいGitリポジトリを初期化
git init

# 初期コミットを作成
git add .
git commit -m "Initial commit: Flutter project template"

# 新しいリモートリポジトリを追加（GitHubで新しいリポジトリを作成後）
git remote add origin https://github.com/your-username/your-new-repo.git

# メインブランチにプッシュ
git branch -M main
git push -u origin main
```

### 3. プロジェクト初期化

```bash
# Flutter プロジェクト初期化（既存の lib/ を上書きする場合は注意）
./AI/scripts/setup/init_project.sh --yes

# 推奨依存を追加
./AI/scripts/setup/add_dependencies.sh --yes

# Core 基盤を生成（未生成の場合）
./AI/scripts/generate/generate_core.sh --yes
./AI/scripts/generate/init_core_exceptions.sh --yes

# 機能テンプレートを生成
./AI/scripts/generate/generate_feature.sh -n Sample -p shared -y
```

> **Windows の場合**: Git Bash を使用してスクリプトを実行してください。

## ライセンス

LICENSE に記載されたカスタムライセンスに従います。個人利用は自由ですが、商用利用には事前許可が必要です。

## サポート

不明点やエラーは Issuesまで。

Happy building! 🚀
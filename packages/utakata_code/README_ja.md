# utakata

**utakata** は **[utakata code](https://github.com/utakata-code)** が開発する Dart CLI ツールです。
**お客様・開発者・AI エージェント**が**仕様駆動開発**によって Flutter アプリを共同構築するために設計されています。

> English documentation: [README.md](README.md)

[![pub.dev](https://img.shields.io/pub/v/utakata.svg)](https://pub.dev/packages/utakata)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

## 特徴

- 🤖 **Claude Code ネイティブ**: `create` が `.mcp.json` + `.claude/`(フック・スキル・エージェント)+ プロジェクト `CLAUDE.md` を生成。`utakata mcp` はステートレス・読み取り専用の MCP サーバー(8ツール)を提供し、AI が構造・計画・会話ログ・合意・設定を「書き込まずに」参照できます。
- 🧭 **マスター設定(`utakata.yaml`)**: アーキテクチャ、`team`(お客様・開発者・AI の役割と決定権)、`.claude/skills/` に同期する `skills`、任意のリモート `knowledge_repo`(`utakata arch get` でコミット SHA を `utakata.lock` に固定)を1ファイルで宣言。未指定なら全て同梱・完全オフラインで動作します。
- 🏗️ **マルチアーキテクチャ対応**: **Clean Architecture (4層)** と **MVVM (3層)** を標準搭載。`utakata arch eject <id>` でローカルに書き出してカスタマイズ可能。
- 🔍 **1回の check で全て検証**: `utakata check` が「不足ファイル」「余分なファイル」「命名規則違反」を1回の走査で報告します。違反箇所には GUIDE の抜粋も添えられ、直し方がその場でわかります。
- 📋 **意図レベルの計画**: `doc/specs/plan.yaml` に feature(名前・権限・entity)を宣言するだけ。`utakata apply` が不足分だけを生成します。`utakata plan adopt` は plan.yaml に載っていない実装済みコードを検出し、書式を保ったまま追記します。
- 📚 **ナレッジはリポジトリの外**: ガイドは [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) で一元管理(リリース時に同梱・プロジェクト単位で `knowledge_repo` により差し替え可能)。プロジェクトにはアプリ本体 + `doc/` + 設定だけが残ります。
- 💬 **お客様との会話の記録**: `utakata log` がお客様との会話を記録します(人間のみ書き込み・JSONL・追記専用)。`utakata agree` は合意をトラッキングします — AI は読めても書けない記録です。
- 📝 **実装計画とサマリー**: `utakata impl` が feature ごとの実装計画のライフサイクルを管理し、`utakata summary` が案件整理サマリーの合意ログ区間を自動再生成します。
- 🌐 **多言語対応**: CLI メッセージは日本語・英語に対応しています。

---

## インストール

```sh
dart pub global activate utakata
```

`$HOME/.pub-cache/bin` を `PATH` に追加してください。

---

## クイックスタート

```sh
# (任意)アプリがまだ存在しない段階(契約前フェーズ)で doc/ ワークスペースを先行作成
utakata doc init

# Flutter プロジェクトを新規作成(.mcp.json + .claude/ も同時生成)
utakata create my_app --org com.example

# doc/specs/plan.yaml に feature を宣言してから生成
utakata apply --scope feature

# 構造・命名規則・必須ファイルを1回で検証
utakata check
```

`doc/specs/plan.yaml`:

```yaml
schema: 1
project:
  architecture: clean_architecture
features:
  - name: todo
    permission: user
    entities: [todo]
```

旧 `AI/` ベースのレイアウトを使っている既存プロジェクトは `utakata doctor --migrate` で移行できます(既定は dry-run)。

---

## 組み込みアーキテクチャ

```sh
utakata arch list         # 利用可能なアーキテクチャ一覧
utakata arch show mvvm    # レイヤー構造と命名規則を表示
```

| アーキテクチャ | レイヤー数 | 説明 |
|---|---|---|
| `clean_architecture` | 4 | Domain → Infrastructure → Application → Presentation |
| `mvvm` | 3 | Model → ViewModel → View |

`plan.yaml` で feature 単位のアーキテクチャ上書きも可能です:

```yaml
features:
  - name: todo
    permission: user
    entities: [todo]
    architecture: clean_architecture   # プロジェクト既定を上書き
```

---

## コマンドリファレンス

### プロジェクトセットアップ

| コマンド | 説明 |
|---|---|
| `utakata doc init` | Flutter プロジェクト本体より先に `doc/` ワークスペース(specs/records/preview/impl/knowledge/archive)+ `utakata.yaml` を作成する |
| `utakata create <name> [--org] [--platforms] [--arch]` | 選択したアーキテクチャで Flutter プロジェクトを新規作成し、`.mcp.json` + `.claude/` も生成する |
| `utakata doctor [--migrate]` | プロジェクトを診断する。`--migrate` は旧 `AI/` ベースのレイアウト(または独自運用の `doc/`)を現行レイアウトへ移行する |

### 構造

| コマンド | 説明 |
|---|---|
| `utakata feature add <name> [--entity] [--permission] [--template <id>]` | feature を1つスキャフォールドする。`--template` は feature プリセット(プロジェクトまたは `~/.utakata/feature_templates/` から解決する `manifest.yaml`)を適用し、同じ操作で `plan.yaml` にも登録する |
| `utakata apply [--scope all\|feature\|core] [--dry-run]` | `plan.yaml` が宣言していて `lib/` に無いものを生成する |
| `utakata plan adopt [-y]` | `lib/features/` にあるが `plan.yaml` に無い feature を検出し追記する(既存のコメント・書式は保持) |
| `utakata check [--json] [--file <path>]` | 不足ファイル・余分なファイル・命名規則違反を1回の走査で報告する |
| `utakata status [--brief] [--write-report]` | Flutter バージョン + lint + check サマリー。`--brief` は flutter 呼び出しを一切行わない(Claude Code フック用) |
| `utakata arch list\|show\|eject\|export` | アーキテクチャ定義の確認、またはローカルへの書き出し(カスタマイズ開始) |
| `utakata arch get [--update]` | `utakata.yaml` の `knowledge_repo`(オプトイン)をフェッチしてコミット SHA を `utakata.lock` に固定する |

### お客様・記録系(人間が書き、AI が読む)

| コマンド | 説明 |
|---|---|
| `utakata log add "..." -s client\|developer\|system\|third_party [--at] [--thread] [--tag] [--reply-to] [--draft]` | 会話を1件追記する(`doc/records/log/YYYY-MM.jsonl`) |
| `utakata log show [--date] [--thread] [--tag]` / `utakata log render` | 会話の検索 / `doc/preview/` 配下の Markdown プレビュー再生成 |
| `utakata log import claude-session [--list\|--last\|--session <id>] [--full] [-y]` | Claude Code セッション生ログを人間の操作で `doc/records/sessions/` に取り込む(既定は user/assistant テキストのみ・秘密情報は `[REDACTED]`・確認プロンプト付き) |
| `utakata agree add --title "..." --kind client_agreement\|internal_decision\|tentative [--amount] [--from <msg id>]` | 合意を記録する(`doc/records/agreements.jsonl`・追記専用) |
| `utakata agree status <id> <status>` / `correct <id>` / `reflect <id> --plan\|--spec` / `list [--unreflected]` | 合意の状態更新・訂正(supersede)・反映記録・未反映合意の一覧 |
| `utakata impl new <feature> [--agreement] [--spec] [--basis]` / `list` / `done <id>` / `archive <id>` | feature 実装計画のライフサイクル管理(`doc/impl/PLAN-NNNN_{feature}.md`) |
| `utakata summary` | `doc/summary.md` の合意ログ区間を再生成する(手書き部分はそのまま) |

### ナレッジ

| コマンド | 説明 |
|---|---|
| `utakata guide list\|show\|eject [--arch]` | レイヤーのガイドを閲覧、またはローカルへ書き出してカスタマイズを開始する |
| `utakata guide for <file> [--json]` | `lib/features/` 配下のファイルパスから該当レイヤーのガイドを決定論的に解決する(lint エラー修正のコンテキスト供給用) |

### AI 統合

| コマンド | 説明 |
|---|---|
| `utakata mcp` | ステートレス・読み取り専用の MCP サーバーを stdio で起動する(`structure_get`・`check_run`・`plan_get`・`log_query`・`agreements_query`・`guide_get`・`guide_for_file`・`config_get`) |
| `utakata skills sync [--force]` | `utakata.yaml` の `skills` リストをアーキテクチャ同梱 SKILL から `.claude/skills/` に同期する(managed マーカー保護: 人間の作ったファイルは絶対に上書きしない) |
| `utakata claude init [--force]` | 既存プロジェクトに Claude Code 統合(`.claude/` + `.mcp.json` + `CLAUDE.md`)を後付け・補修する。既定は欠けているファイルのみ生成、`--force` で全再生成 |

`diff` は `check` への永続的なエイリアスとして残ります。`scan`・`validate`・`feature init`・`core`・`arch create` は削除・改名されました。詳細は [CHANGELOG.md](CHANGELOG.md) を参照してください。

---

## AI エージェントへの案内

`utakata create` は `.mcp.json` と `.claude/settings.json` を生成し、以下のフックを設定します:

- **SessionStart** → `utakata status --brief`(プロジェクト状態の要約。flutter 呼び出しなし)
- **PostToolUse**(Edit/Write) → `utakata check --json`(編集直後のファイルへの即時フィードバック)
- **Stop** → `utakata status --brief --write-report`
- **deny ルール**: `doc/records/**` と `doc/preview/**` への `Edit`/`Write` を拒否 — 会話ログ・合意の書き込み経路は人間専用であり、ドキュメント上の約束ではなくホスト側で技術的に強制されます

ファイルを手動で作成せず、`utakata` CLI でプロジェクト構造を拡張してください。コミット前に `utakata check` を実行することを推奨します。

---

## アーキテクチャ

`utakata` 自体も Clean Architecture で実装されています:

```
packages/utakata_code/lib/src/
├── 0_templates/       # アーキテクチャテンプレート (clean_architecture, mvvm)
├── 1_domain/          # エンティティ・リポジトリI/F・ユースケース・純関数サービス
├── 2_infrastructure/  # ファイルシステム/YAML/JSONL/プロセスのデータソース・モデル・リポジトリ実装
└── 3_application/     # コマンドハンドラ・Runner・プレゼンター・MCP サーバー
```

---

## ライセンス

**デュアルライセンス**:

1. **オープンソース (GNU GPL v3)**
   個人・オープンソースプロジェクトへの使用・フォーク・改変は [GNU GPL v3](LICENSE) のもとで無料で可能です。

2. **商用利用**
   このツール、またはツールが生成したコードの商用利用には別途商用ライセンスが必要です。
   詳細は開発者 ([@code_utakata](https://x.com/code_utakata)) までご連絡ください。

---

## リンク

- [リポジトリ](https://github.com/utakata-code/utakata)
- [pub.dev](https://pub.dev/packages/utakata)
- [X (Twitter) @code_utakata](https://x.com/code_utakata)
- [utakata code](https://github.com/utakata-code)

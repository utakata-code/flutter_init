# utakata

**utakata** は **[utakata code](https://github.com/utakata-code)** が開発する Dart CLI ツールです。  
人間と AI エージェントが**仕様駆動開発**によって Flutter アプリを共同構築するために設計されています。

> English documentation: [README.md](README.md)

[![pub.dev](https://img.shields.io/pub/v/utakata.svg)](https://pub.dev/packages/utakata)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

## 特徴

- 🤖 **AI ネイティブ開発**: 人間と AI エージェントの両方向けに設計されたコマンド群。`.agent/` ルールと `AI/guides/` を組み合わせることで、AI がアーキテクチャから逸脱せずに開発できます。
- 🏗️ **アーキテクチャ非依存**: Clean Architecture に限定されません。`arch_definition.yaml` で独自のアーキテクチャを定義できます。
- 🔍 **構造・命名規則の検証**: `utakata validate` で命名規則違反とディレクトリ構造違反を `arch_definition.yaml` に基づいて検出します。
- 📋 **仕様駆動**: `feature_request.yaml` にフィーチャーを定義し、計画書を生成、全層を一括スキャフォールドします。
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
# Flutter プロジェクトを新規作成（.agent/ と AI/ テンプレート込み）
utakata create my_app --org com.example

# AI/specs/feature_request.yaml にフィーチャーを定義後:
utakata plan          # アーキテクチャ計画書を生成
utakata feature init  # 全フィーチャーを一括生成

# 構造・命名規則を検証
utakata validate
```

---

## コマンドリファレンス

### `utakata create`

選択したアーキテクチャの基本構造と AI ワークフローテンプレートを含む Flutter プロジェクトを作成します。

```sh
utakata create my_app --org com.example
```

### `utakata plan`

`AI/specs/feature_request.yaml` を読み込み、構造化されたアーキテクチャ計画書を生成します。

```sh
utakata plan
```

### `utakata feature`

```sh
# フィーチャーを1つ追加
utakata feature add <feature_name> [--permission user|admin|shared|direct]

# plan_architecture.yaml に定義された全フィーチャーを一括生成
utakata feature init
```

### `utakata validate`

`arch_definition.yaml` に基づいて命名規則とディレクトリ構造を検証します。

```sh
utakata validate
```

### `utakata scan / diff / check`

```sh
utakata scan    # 現在の lib/ 構造をスキャン
utakata diff    # 計画と実際の構造を比較
utakata check   # diff を実行して違反を報告
```

### `utakata status`

Flutter バージョン・lint 状態・アーキテクチャ差分を一括確認します。

```sh
utakata status
```

---

## AI エージェントへの案内

生成されたプロジェクトには `.agent/rules/flutter.md` と `AI/guides/` が含まれています。

**ファイルを手動で作成せず、必ず `utakata` CLI を使ってプロジェクト構造を拡張してください。**  
コミット前に `utakata validate` を実行してゼロ違反を維持してください。

---

## アーキテクチャ

`utakata` 自体も Clean Architecture で実装されています：

```
packages/utakata_code/lib/src/
├── 1_domain/         # エンティティ・リポジトリI/F・ユースケース
├── 2_infrastructure/  # ファイルシステム・YAML・プロセス操作
└── 3_application/    # コマンドハンドラ・Runner
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

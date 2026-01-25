---
name: flutter-development-guide
description: |
  Flutter開発の全体フローと3フェーズ開発プロセスをガイドするスキル。
  「開発フローを教えて」「次のステップは？」「モードを選択したい」時に使用。
---

# 📚 Flutter 開発ガイドスキル

> **目的**: 開発プロセス全体のガイダンスを提供する

## 開発モード

### モード選択

| モード | 対象 | 参照 |
|-------|------|------|
| **モード1**: 新規アプリ開発 | ゼロから構築 | `AI/instructions/new_app/` |
| **モード2**: 既存アプリ（ルール使用中） | 本テンプレート準拠の既存コード | `AI/instructions/existing_app/with_rules/` |
| **モード3**: 既存アプリ（ルール未使用） | 本テンプレート非準拠の既存コード | `AI/instructions/existing_app/without_rules/` |

### モード選択の宣言
```
- 「モード1（新規アプリ開発）で進めます」
- 「モード2（既存アプリ・ルール使用中）を選択」
- 「モード3（既存アプリ・ルール未使用）に切り替え」
```

## 3フェーズ開発プロセス

```
仕様策定（Stage 1） → 構造計画（Stage 2） → 実装（Stage 3）
```

### Stage 1: 仕様策定
- **目的**: 要件の明確化
- **成果物**: `AI/document/application_specification.md`
- **ステップ**: ヒアリング → 草案 → 深掘り → 完成

### Stage 2: 構造計画
- **目的**: ファイル構成の計画
- **成果物**: `AI/document/structure_plan.md`
- **ステップ**: ルール確認 → 草案 → レビュー → 完成

### Stage 3: 実装
- **目的**: コードの記述
- **成果物**: 動作するアプリケーション
- **ステップ**: 準備 → 計画 → レイヤー別実装 → レビュー → 完成

## 関連スキル

| スキル | 用途 |
|-------|------|
| `flutter-stage1-specification` | Stage 1 詳細 |
| `flutter-stage2-structure` | Stage 2 詳細 |
| `flutter-stage3-implementation` | Stage 3 詳細 |
| `flutter-feature-generator` | フィーチャー生成 |
| `flutter-structure-validator` | 構造検証 |
| `flutter-code-reviewer` | コードレビュー |
| `flutter-project-status` | ステータス管理 |
| `flutter-layer-implementation` | レイヤー別実装 |

## よくある質問

### Q: どのモードを選べばいい？
- **新規開発**: モード1
- **既に本テンプレートで作成済み**: モード2
- **既存コードをリファクタリングしたい**: モード3

### Q: Stage間で仕様変更があったら？
前のStageに戻って、ドキュメントを更新してから進みます。

### Q: 実装順序は？
Domain → Infrastructure → Application → Presentation の順で実装します。

## 運用ルール

```
⚠️ 重要:
- コンテキスト分離: 選択中のモード以外の指示ファイルは参照しない
- ドリフト防止: コード変更に伴い仕様書と構造計画書を必ず更新
- ステップ厳守: 各フェーズの目的に集中し、先に飛ばない
```

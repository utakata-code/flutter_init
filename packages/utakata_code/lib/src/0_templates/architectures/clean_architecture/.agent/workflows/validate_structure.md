---
description: 命名規則・ディレクトリ構造の違反を検出
---

# ディレクトリ構造・命名規則の検証

このワークフローは、`lib/`以下の命名規則とディレクトリ構造が `arch_definition.yaml` の定義に準拠しているかを検証します。

## 手順

// turbo
1. 構造・命名規則を検証
```bash
utakata validate
```

## 検証内容

- 命名規則違反: ファイル名が `arch_definition.yaml` の `naming_rules` に準拠しているか
- 構造違反: `plan` と `scan` の差分（Missing / Extra）

## 使用タイミング

- 新しいファイルやディレクトリを作成した後
- フィーチャーを追加した後（`utakata feature add` の後）
- AIエージェントとの会話開始前（現状確認のため）
- CI 実行前

## 違反が見つかった場合

1. 命名規則違反: ファイルを `arch_definition.yaml` の命名規則に合わせてリネームする
2. Missing: `utakata feature add` で不足しているディレクトリ・ファイルを生成する
3. Extra: 不要なファイル・ディレクトリを削除または移動する
4. 修正後に再度 `utakata validate` を実行してゼロ違反を確認

## 関連ガイド

- 命名規則の定義: `arch_definition.yaml` の `naming_rules:` セクション
- 詳細ガイド: `utakata/guides/architecture/arch_summary.md`


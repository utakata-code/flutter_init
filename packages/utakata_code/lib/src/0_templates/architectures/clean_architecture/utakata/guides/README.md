---
# AI/guides/README.md
# このファイルはAIエージェントと人間の両方が参照する入口ドキュメントです
---

# AI Guides — アーキテクチャ仕様書ハブ

このディレクトリは **AIエージェントと人間開発者が共同参照する Single Source of Truth** です。

> **ミッション**: 仕様駆動開発 + AIと人間の境なき共作 + 複数人/複数AIでのプロジェクト進行を支援する

---

## ディレクトリ構成

```
AI/guides/
├── architectures/           # アーキテクチャ別ガイド（公式推奨 + ユーザー追加）
│   └── clean_architecture/  # 公式推奨: Clean Architecture
└── common/                  # アーキテクチャ非依存の共通ガイド
    ├── technology_stack.md
    ├── recommended_packages.md
    └── collaboration.md     # 複数人/複数AI 協作ルール
```

---

## アーキテクチャ選択

このプロジェクトで使用するアーキテクチャは `arch_definition.yaml` で定義されています。

```bash
# 現在のアーキテクチャを確認
cat AI/specs/feature_request.yaml | grep arch
```

### 公式推奨: Clean Architecture

- ガイド: `architectures/clean_architecture/`
- 概要: `architectures/clean_architecture/arch_summary.md`（AIが常時参照）
- 詳細: `architectures/clean_architecture/lib/` 各層ガイド

### ユーザー追加アーキテクチャ

別のアーキテクチャ（MVVM など）を使用する場合は、
`architectures/{アーキテクチャ名}/` に同じ構成でガイドを追加し、
`arch_definition.yaml` に `guides_path:` を記述してください。

---

## utakata CLI との連携

| やりたいこと | コマンド |
|---|---|
| フィーチャーを追加する | `utakata feature add <name>` |
| 計画書を生成する | `utakata plan` |
| 現在の構造をスキャン | `utakata scan` |
| 命名規則・構造を検証 | `utakata validate` |
| 計画との差分を確認 | `utakata diff` |
| 総合ステータスを確認 | `utakata status` |

---

## AI/ディレクトリの役割分担

| ディレクトリ | 性質 | 内容 |
|---|---|---|
| `AI/guides/` | **変わりにくい** | アーキテクチャルール・命名規則（合意が必要） |
| `AI/specs/` | **変わる** | アプリ要件・フィーチャー定義（開発に応じて更新） |
| `AI/snapshots/` | **自動更新** | 現在の状態（utakata が更新する） |
| `AI/logs/` | **記録** | 会話ログ・変更履歴 |

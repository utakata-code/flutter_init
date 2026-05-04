# utakata — by utakata code

> **仕様駆動開発 + AIと人間の境なき共作 + 複数人/複数AI でのプロジェクト進行をスムーズにする**

[![pub.dev](https://img.shields.io/pub/v/utakata.svg)](https://pub.dev/packages/utakata)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**泡沫Code** が開発する、Flutter アプリ開発支援ツールキットのモノレポです。

---

## このリポジトリについて

このリポジトリは、かつて **`flutter_init`** という名前の Flutter 新規プロジェクト用テンプレートとして始まりました。

当初は `.agent/` と `AI/` を中心とした「AIエージェントと人間が共同作業するための初期テンプレート」でしたが、  
開発が進む中で以下のような変遷を経て現在の形に至っています。

### 変遷の概要

| バージョン | 内容 |
|---|---|
| `flutter_init` 初期 | Flutter 新規プロジェクト用テンプレート（.agent/ + AI/）|
| `flutter_init` v2.0 | Clean Architecture 対応・スキル / ワークフロー体系を整備 |
| `utakata` v0.2.0 | テンプレートのロジックを Dart CLI ツール（pub.dev: utakata）として切り出し |
| `utakata` v0.3.0（現在） | CLI を `utakata_code` パッケージに昇格・モノレポへ統合・アーキテクチャ非依存化 |

---

## リポジトリ構造

```
utakata/
├── .agent/              # AIエージェント向けルール・ワークフロー定義
├── AI/                  # AIと人間が共同参照する仕様書ハブ
│   ├── guides/          # アーキテクチャガイド（CA公式推奨 + 拡張可能）
│   ├── specs/           # プロジェクト仕様書（プロジェクト作成時に生成）
│   └── snapshots/       # utakata CLI が自動更新する現在の状態
├── packages/
│   └── utakata_code/    # CLI ツール本体（pub.dev: utakata_code）
├── templates/           # プロジェクト生成用テンプレート群
└── doc/                 # 実装ドキュメント
```

---

## 🤖 AIエージェント連携

`utakata create` で生成されるプロジェクトには `.agent/` と `AI/` が自動的に含まれます。

### `.agent/` — AIへの指示定義
AI エージェント（Claude, Gemini 等）向けのルールとワークフロー定義。

```
.agent/
├── rules/flutter.md          # trigger: always_on（常時参照）
└── workflows/                # /validate, /scan 等のスラッシュコマンド
```

### `AI/` — Single Source of Truth
AIと人間が共同参照する仕様書ハブ。

```
AI/
├── guides/
│   ├── architectures/clean_architecture/
│   │   ├── arch_summary.md   # trigger: always_on（AIが常時参照）
│   │   └── lib/              # applyTo: で編集時に自動注入
│   └── common/collaboration.md  # 複数人/複数AI 協作ルール
├── specs/                    # アプリ仕様書・フィーチャー定義
└── snapshots/                # utakata が自動更新する構造スナップショット
```

---

## 📦 utakata CLI

```bash
# インストール
dart pub global activate utakata
```

| コマンド | 説明 |
|---|---|
| `utakata create <app_name>` | Flutter プロジェクトを作成（.agent/ と AI/ 込み） |
| `utakata feature add <name>` | フィーチャーを追加 |
| `utakata feature init` | 計画書に基づき全フィーチャーを一括生成 |
| `utakata plan` | feature_request.yaml から計画書を生成 |
| `utakata scan` | 現在の構造をスキャン |
| `utakata validate` | 命名規則・ディレクトリ構造を検証 |
| `utakata diff` | 計画との差分を確認 |
| `utakata status` | 総合ステータスを確認 |

詳細: [pub.dev/packages/utakata](https://pub.dev/packages/utakata)

---

## ライセンス

[GNU General Public License v3.0](LICENSE) — © [utakata code](https://github.com/utakata-code)
# utakata — by utakata code

> **お客様・開発者・AIエージェントが共作する、Flutter の仕様駆動開発**

[![pub.dev](https://img.shields.io/pub/v/utakata.svg)](https://pub.dev/packages/utakata)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**泡沫Code** が開発する、Flutter アプリ開発支援ツールキットのモノレポです。

[English README](README.md)

---

## このリポジトリについて

**utakata CLI**(pub.dev: [`utakata`](https://pub.dev/packages/utakata))のモノレポです。
utakata は、お客様・開発者・AIエージェントという異なるアクターが、一つの Flutter プロジェクトで安全に協働するためのプロジェクト・オーケストレーターです:

- **マスター設定(`utakata.yaml`)** — アーキテクチャ、team(誰の決定に従うか)、AI スキル、任意のリモートナレッジリポジトリ(コミット SHA を `utakata.lock` に固定)を1ファイルで宣言
- **意図レベルの計画(`doc/specs/plan.yaml`)** + 1回の走査で構造を検証(`check` / `apply`)
- **人間専用の記録系** — お客様との会話ログ・合意台帳・feature 別実装計画。AI は読めるが書けない(ホスト側の deny ルールで技術的に強制)
- **参照型ナレッジ** — ガイドは [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) で一元管理し、リリース時に同梱。プロジェクトへはコピーしない
- **Claude Code ネイティブ** — `.mcp.json`・フック・managed スキル・`CLAUDE.md`・読み取り専用 MCP サーバー(8ツール)

コマンドの詳細: [packages/utakata_code/README_ja.md](packages/utakata_code/README_ja.md)

### 変遷

| バージョン | 説明 |
|---|---|
| `flutter_init` | `.agent/` + `AI/` 中心の Flutter 新規プロジェクトテンプレート(人間とAIの共同作業) |
| `utakata` v0.2–0.3 | テンプレートロジックを Dart CLI 化、モノレポ統合、アーキテクチャ非依存化 |
| `utakata` v0.4–0.5 | マルチアーキテクチャ対応(Clean Architecture / MVVM)、動的 GUIDE 生成 |
| `utakata` **v1.0.0**(現行) | プロジェクト・オーケストレーター化: マスター設定、正準構造モデル、記録系、ナレッジ外部化、Claude Code 統合 |

---

## リポジトリ構成

```
utakata/
├── AI/                    # このリポジトリ自身の作業ドキュメント
│   ├── specs/             # 設計文書(アプリケーション仕様書・構造計画書・実装計画書)
│   └── logs/              # 開発会話ログ
├── packages/
│   └── utakata_code/      # CLI ツール本体(pub.dev: utakata)
├── v1.0.0.md              # v1.0.0 コンセプト文書
├── v1.0.0_review.md       # 実装前レビュー(日付付き追記あり)
└── v1.0.0_result.md       # 実装後の答え合わせ
```

関連リポジトリ: [utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib) — アーキテクチャナレッジライブラリ(Clean Architecture / MVVM / 独自アーキテクチャ用 `_starter` 雛形)。内容はリリース時に CLI の同梱テンプレートへ同期され、プロジェクト単位で `utakata.yaml` の `knowledge_repo` により差し替えもできます。

---

## クイックスタート

```bash
dart pub global activate utakata

utakata doc init                       # doc/ ワークスペース + utakata.yaml(契約前フェーズ)
utakata create my_app --org com.example
utakata apply --scope feature          # plan.yaml の宣言どおりに生成
utakata check                          # 不足・余分・命名違反を1回で検証
```

詳細: [packages/utakata_code/README_ja.md](packages/utakata_code/README_ja.md) · [pub.dev/packages/utakata](https://pub.dev/packages/utakata)

---

## ライセンス

デュアルライセンス: 個人・オープンソース用途は [GNU GPL v3](LICENSE)、商用利用は別途ライセンスが必要です — [@code_utakata](https://x.com/code_utakata) までご連絡ください。

© [utakata code](https://github.com/utakata-code)

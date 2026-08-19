# utakata ドキュメント

設定ファイルの書き方リファレンス。CLI に同梱されているため、
インストール済みのバージョンに対応した内容を次のコマンドでも読めます:

```sh
utakata doc show config     # utakata.yaml の書き方
utakata doc show plan       # doc/specs/plan.yaml の書き方
utakata doc show imports    # import_rules の書き方(utakata imports)
utakata doc show records    # 記録の4系統と AI に許す範囲
utakata doc show impl       # 実装計画のライフサイクル
utakata doc list            # 読めるトピック一覧
```

| ドキュメント | 対象ファイル | 内容 |
|---|---|---|
| [utakata-yaml.md](utakata-yaml.md) | `utakata.yaml` | プロジェクト全体のマスター設定(アーキテクチャ・team・skills・knowledge_repo) |
| [plan-yaml.md](plan-yaml.md) | `doc/specs/plan.yaml` | feature の意図レベル計画(entities・layers による層ごとの増減) |
| [import-rules.md](import-rules.md) | `arch_definition.yaml` の `import_rules` | import 健全性の監査規則(`utakata imports` が検証) |
| [impl-plan.md](impl-plan.md) | `doc/impl/` と `enforcement.impl_plan` | 実装計画の2軸ライフサイクル(実装 × 検証)、レーン、ゲート |
| [records.md](records.md) | `doc/records/` と `utakata.yaml` の `records` | 記録の4系統(ログ・合意・送受信原文・AI セッション)と、AI に許す書き込み範囲 |

コマンド一覧・全体像は [../README_ja.md](../README_ja.md) を参照してください。

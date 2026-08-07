# utakata ドキュメント

設定ファイルの書き方リファレンス。CLI に同梱されているため、
インストール済みのバージョンに対応した内容を次のコマンドでも読めます:

```sh
utakata doc show config     # utakata.yaml の書き方
utakata doc show plan       # doc/specs/plan.yaml の書き方
utakata doc show imports    # import_rules の書き方(utakata imports)
utakata doc list            # 読めるトピック一覧
```

| ドキュメント | 対象ファイル | 内容 |
|---|---|---|
| [utakata-yaml.md](utakata-yaml.md) | `utakata.yaml` | プロジェクト全体のマスター設定(アーキテクチャ・team・skills・knowledge_repo) |
| [plan-yaml.md](plan-yaml.md) | `doc/specs/plan.yaml` | feature の意図レベル計画(entities・layers による層ごとの増減) |
| [import-rules.md](import-rules.md) | `arch_definition.yaml` の `import_rules` | import 健全性の監査規則(`utakata imports` が検証) |

コマンド一覧・全体像は [../README_ja.md](../README_ja.md) を参照してください。

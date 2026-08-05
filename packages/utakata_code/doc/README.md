# utakata ドキュメント

設定ファイルの書き方リファレンス。CLI に同梱されているため、
インストール済みのバージョンに対応した内容を次のコマンドでも読めます:

```sh
utakata doc show config     # utakata.yaml の書き方
utakata doc show plan       # doc/specs/plan.yaml の書き方
utakata doc list            # 読めるトピック一覧
```

| ドキュメント | 対象ファイル | 内容 |
|---|---|---|
| [utakata-yaml.md](utakata-yaml.md) | `utakata.yaml` | プロジェクト全体のマスター設定(アーキテクチャ・team・skills・knowledge_repo) |
| [plan-yaml.md](plan-yaml.md) | `doc/specs/plan.yaml` | feature の意図レベル計画(entities・layers による層ごとの増減) |

コマンド一覧・全体像は [../README_ja.md](../README_ja.md) を参照してください。

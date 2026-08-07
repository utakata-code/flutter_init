# import_rules — import 健全性の監査規則

`arch_definition.yaml` の `import_rules` セクションと、それを検証する
`utakata imports` コマンド(v1.5.0〜)のリファレンス。

```sh
utakata imports              # lib/ 配下の import を監査(違反があれば exit 1)
utakata imports --json       # 機械可読出力(CI・AI エージェント向け)
utakata imports --arch mvvm  # アーキテクチャを明示(省略時は utakata.yaml / plan.yaml から解決)
```

`utakata check` が「ディレクトリ構造と命名」を検証するのに対し、`imports` は
「ファイルの中身の依存方向」を検証します。どちらも決定論的で、AI エージェントの
生成結果を客観的にゲートできます。

---

## 書式

```yaml
# arch_definition.yaml
import_rules:
  # 監査から除外するファイル(glob。コード生成物など)
  exclude:
    - "**.g.dart"
    - "**.freezed.dart"

  # 内部依存(プロジェクト内 import)のホワイトリスト
  internal:
    - dir_pattern: "1_domain/1_entities"
      allow: ["1_domain/exceptions"]          # 例外層だけ import してよい
    - dir_pattern: "3_application/2_providers"
      allow: ["1_domain", "2_infrastructure", "3_application"]  # DI 層は広く許可

  # 外部依存(package: / dart: import)のブラックリスト
  external:
    - dir_pattern: "1_domain"
      deny: ["flutter", "*riverpod*", "dio"]  # パッケージ名は glob 可
    - dir_pattern: "1_domain/exceptions"
      deny: ["dart:io"]                       # dart: URI も指定可
```

| キー | 説明 |
|---|---|
| `internal[].dir_pattern` | 発信元の層パス。`naming_rules` と同じ流儀(パスセグメント単位で照合) |
| `internal[].allow` | import してよい層パスのリスト(ホワイトリスト) |
| `external[].dir_pattern` | 対象の層パス |
| `external[].deny` | 禁止するパッケージ名 glob のリスト(ブラックリスト) |
| `exclude` | 監査対象外にするファイルパス glob |

---

## 判定の規則

- **監査対象は `lib/features/` 配下のみ**: 層構造が定義されるのはそこだけです。
  `lib/core/` や `lib/main.dart` は(層名と同名のディレクトリがあっても)
  監査されず、そこへの import も違反になりません。DI を束ねる
  composition root の「例外パターン」はここで吸収されます。
- **自層は常に許可**: `dir_pattern` に属するパス同士の import は検証しません。
  このため「同層内の相互 import 禁止」(molecules → 他の molecule 等)は
  v1.5.0 時点では表現できません。
- **最も具体的なルールが選ばれる**(internal): 同じファイルに複数の
  `dir_pattern` が該当する場合、セグメント数が最長のものを採用します
  (例: `.../1_local/exceptions/` には `1_local` ではなく
  `1_local/exceptions` のルールが適用される)。
- **external は重ねて適用される**: 層全体の禁止(`1_domain`)と
  サブディレクトリ固有の禁止(`1_domain/1_entities`)は両方有効です。
- **`package:<自パッケージ>/...` は内部依存**として相対 import と同様に
  検証されます(自パッケージ名は pubspec.yaml の `name`)。
- feature をまたぐ import も**層だけで判定**します(feature 境界は v1.5.0
  時点では監査対象外)。照合はパスセグメント単位のため、**feature や
  permission に層と同じ名前(`1_domain` 等)を付けない**でください —
  層として誤判定されます。
- **コメント・文字列リテラル内の import 行は無視**されます(字句走査)。
  条件付き import(`import 'a.dart' if (...) 'b.dart';`)は**全分岐**を
  監査します。

---

## 規則が無いアーキテクチャ

`import_rules` が未定義のアーキテクチャでは監査せず、案内だけを表示して
exit 0 します。同梱の `clean_architecture` / `mvvm` には、各層ガイドの
`allowed_imports` / `forbidden_imports` と整合する規則が定義済みです。

規則をプロジェクト独自に調整したい場合は、`utakata arch eject <id>` で
`AI/architecture/arch_definition.yaml` に書き出してから `import_rules` を
編集してください(ローカル定義が同梱定義より優先されます)。

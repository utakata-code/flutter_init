# import_rules — import 健全性の監査規則

`arch_definition.yaml` の `import_rules` セクション・`dependencies/*.yaml` の
配置宣言と、それらを検証する `utakata imports` コマンド(v1.5.0〜)のリファレンス。

```sh
utakata imports              # lib/ 配下の import を監査(違反があれば exit 1)
utakata imports --json       # 機械可読出力(CI・AI エージェント向け)
utakata imports --arch mvvm  # アーキテクチャを明示(省略時は utakata.yaml / plan.yaml から解決)
```

`utakata check` が「ディレクトリ構造と命名」を検証するのに対し、`imports` は
「ファイルの中身の依存方向」を検証します。どちらも決定論的で、AI エージェントの
生成結果を客観的にゲートできます。

---

## 内部依存 — `import_rules`(arch_definition.yaml)

**層間の依存方向は一意のグラフとして宣言します**。細かい絞り込みが要る
ディレクトリだけ `dirs:` で上書きします。

```yaml
# arch_definition.yaml
import_rules:
  # 監査から除外するファイル(glob。コード生成物など)
  exclude:
    - "**.g.dart"
    - "**.freezed.dart"

  # ── 層間依存グラフ(これが正) ──
  # 「この層はこの層たちを見てよい」。自層は常に許可。
  layers:
    1_domain: []                                  # 何にも依存しない
    2_infrastructure: [1_domain]
    3_application: [1_domain, 2_infrastructure]
    4_presentation: [1_domain, 3_application]

  # ── 細則(任意)。層既定より「絞る」場合のみ書く ──
  dirs:
    - dir_pattern: "1_domain/1_entities"
      allow: ["1_domain/exceptions"]              # 層内でも exceptions だけ
    - dir_pattern: "3_application/1_states"
      allow: ["1_domain/1_entities"]
```

### 判定の順序

1. ファイルに `dirs` の**最長一致**ルールがあればそれが正
   (例: `.../1_local/exceptions/` には `1_local` ではなく
   `1_local/exceptions` のルールが適用される)
2. なければ**層グラフ**で層単位に判定:
   宛先の層 ∈ (自層 ∪ `layers[自分の層]`) なら許可
3. どちらにも該当しなければ監査しない

グラフは「許可の上限」であって強制ではありません — 使わないエッジがあっても
構いません。ユーザー定義アーキテクチャなら `layers:` の数行だけでも監査が効きます。

---

## 外部依存 — 配置宣言(dependencies/*.yaml)

外部パッケージは deny リストではなく、**バージョンと「使ってよい層」を
1箇所で宣言**します(`dependencies/core_stack.yaml` / `recommended.yaml`)。

```yaml
# dependencies/core_stack.yaml
dependencies:
  flutter:
    sdk: flutter
    layers: [4_presentation]        # UI 層のみ
  drift:
    version: ^2.28.2
    layers: [2_infrastructure/2_data_sources/1_local]
  sqlite3_flutter_libs:
    version: ^0.5.41
    layers: []                      # どの層でも import しない(ビルド時のみ)
  freezed_annotation:
    version: ^3.0.0                 # layers 省略 = どの層でも可
```

| `layers` の書き方 | 意味 |
|---|---|
| キー省略 | 配置制約なし(どの層でも import 可) |
| `[]` | どの層でも import しない(ビルド時のみ必要な依存) |
| `[層パス, ...]` | その層でのみ import 可 |

**宣言されていないパッケージは論じません(すべて許可)** — 監査対象は
「このスタックで使うと決めたもの」だけです。`core_stack.yaml` は
`utakata create` の初期 pubspec 生成にも使われるため、バージョン管理と
配置管理が構造的に乖離しません。

旧書式 `package: ^version`(スカラ)もそのまま読めます(配置制約なし扱い)。

---

## 共通の規則

- **監査対象は `lib/features/` 配下のみ**: 層構造が定義されるのはそこだけです。
  `lib/core/` や `lib/main.dart` は(層名と同名のディレクトリがあっても)
  監査されず、そこへの import も違反になりません。DI を束ねる
  composition root の「例外パターン」はここで吸収されます。
- **自層は常に許可**: 同層内の相互 import 禁止(molecules → 他の molecule 等)は
  表現できません。
- **`package:<自パッケージ>/...` は内部依存**として相対 import と同様に
  検証されます(自パッケージ名は pubspec.yaml の `name`)。
- feature をまたぐ import も**層だけで判定**します。照合はパスセグメント単位の
  ため、**feature や permission に層と同じ名前(`1_domain` 等)を付けない**で
  ください — 層として誤判定されます。
- **コメント・文字列リテラル内の import 行は無視**されます(字句走査)。
  条件付き import(`import 'a.dart' if (...) 'b.dart';`)は**全分岐**を
  監査します。
- パターン照合はパスセグメント単位(`naming_rules` と同じ流儀)。

---

## 規則が無いアーキテクチャ / カスタマイズ

`import_rules` も配置宣言も無いアーキテクチャでは監査せず、案内だけを表示して
exit 0 します。

規則をプロジェクト独自に調整したい場合は、`utakata arch eject <id>` で
`AI/architecture/arch_definition.yaml` に書き出してから編集してください
(ローカル定義が同梱定義より優先されます)。旧 v1 書式
(`internal:` のフラットなリスト + `external:` の deny ブラックリスト)も
後方互換で読めます。

`utakata guide show <層パス>` の「依存関係の制約」節は、これらの規則から
動的に生成されます(手書きの例示との二重管理はしません)。

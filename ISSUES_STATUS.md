# Issue 状況整理(2026-08-04 時点)

対象: [utakata-code/utakata](https://github.com/utakata-code/utakata) の Open Issue 全5件(#11〜#15)
現行リリース: **v1.0.1**(pub.dev 公開済み)
検証方法: 各 Issue の主張を実際の CLI 実行とソースで再現確認した(下記の「検証結果」は推測ではなく実測)

---

## サマリー

| # | タイトル | 分類 | 再現 | 深刻度 | 推奨対応 |
|---|---|---|---|---|---|
| 14 | `utakata doc init` | バグ | ✅ 再現 | **高** | 1.0.2 で即修正(数行) |
| 11 | `utakata guide list` | バグ | ✅ 再現(コード確認) | **高** | 1.0.2 で修正(横断的に同種3箇所) |
| 13 | `utakata apply` | 設計判断 | ✅ 再現(17ファイル全て GUIDE.md) | 中 | 1.1.0 で方針転換。#15 と一体 |
| 12 | `utakata check` | 設計判断 | ✅ 再現(1 feature = 15 missing) | 中 | 1.1.0。粒度モデルの変更を伴う |
| 15 | 純粋な dart cli ツールへ | アーキテクチャ変更 | — | 中 | 1.1.0 の中核。#13 と一体で設計 |

**依存関係**: #14 と #11 は独立した小バグなので単独で先に出せる。#13 は #15(テンプレート廃止)と同じ「ナレッジをプロジェクトに置かない」方針の話なので一体で設計すべき。#12 は構造モデル(ExpectedStructure)の粒度に関わるため単独で判断可能だが影響範囲は広い。

---

## #14 `utakata doc init` — `doc/specs/plan.yaml` が作成されない

**報告**: doc/specs/plan.yaml が作成されない

**検証結果(再現)**:
```
$ utakata doc init
$ find doc -type f
doc/summary.md
(doc/specs 配下: 0 files)
```
`doc/specs/` ディレクトリは作られるが**空**。`utakata.yaml` と `doc/summary.md` だけが生成される。

**原因**: `init_doc_usecase.dart` は `doc/specs` を `_ensureDir` するだけで、`plan.yaml` を書いていない(`_defaultUtakataYaml()` / `_defaultSummaryMd()` に相当するテンプレートが plan.yaml に無い)。

**影響**: `doc init` 直後に `check` / `apply` を叩くと "plan.yaml not found" で失敗する。ユーザーは plan.yaml を手で作る必要があり、初回体験が壊れている。README のクイックスタート(`doc init` → `create` → `apply`)も、この状態では通らない。

**修正案**: `InitDocUsecase.execute()` に `doc/specs/plan.yaml` の生成を追加する。内容は `schema: 1` + `project.architecture` + 空の `features: []` + 書き方のコメント例。utakata.yaml と同じく「既に存在すれば触らない」を守る。

---

## #11 `utakata guide list` — utakata.yaml のアーキに動的にスイッチしない

**報告**: `utakata guide list` が `utakata.yaml` の指定アーキに動的にスイッチしない

**検証結果(コード確認で再現)**: `guide_command.dart` の3サブコマンドすべてが静的デフォルトを持つ。

| 箇所 | コード |
|---|---|
| `guide_command.dart:48`(list) | `argParser.addOption('arch', defaultsTo: 'clean_architecture')` |
| `guide_command.dart:75`(show) | 同上 |
| `guide_command.dart:100`(eject) | 同上 |

**原因**: v1.0.0(S1)で導入した「`utakata.yaml` → `plan.yaml` → 既定値」の解決チェーンを、`check`/`apply`/`skills sync`/`guide for` には配線したが、**`guide list/show/eject` は旧来のハードコードのまま取り残された**。mvvm プロジェクトで `guide list` すると clean_architecture のガイド一覧が出る。

**同じクラスの問題(横断調査で判明)**:

| 箇所 | 状態 |
|---|---|
| `guide_command.dart:48,75,100` | ❌ Issue #11 本体 |
| `mcp_server.dart:191`(MCP `guide_get`) | ❌ 同罪。`architecture_id` 未指定時に config を見ず `clean_architecture` 固定。同じサーバーの `guide_for_file` は config 解決済みで**不整合** |
| `feature_command.dart:56`(`feature add --arch`) | ⚠️ 静的デフォルト。plan 側フォールバックの有無を要精査 |
| `create_command.dart:37`(`create --arch`) | ✅ 問題なし(新規作成時は config が存在しないので静的デフォルトが正当) |
| `sync_skills_usecase.dart` / `guide_for_file_usecase.dart` | ✅ 正しい実装例(`config.architecture ?? plan ?? 'clean_architecture'`) |

**修正案**: `--arch` のデフォルトを `null` にし、未指定時は既存の解決チェーンに落とす。`--arch` 明示時はそれが勝つ(現行の上書き手段は維持)。MCP `guide_get` と `feature add` にも同じ扱いを適用し、解決ロジックは1箇所(共通ヘルパ)に集約して再発を防ぐ。

---

## #13 `utakata apply` — GUIDE.md が生成されてしまう

**報告**: GUID.md が生成されてしまう

**検証結果(再現)**: 1 feature を apply した結果、**生成された17ファイルが全て GUIDE.md**(実装コードは0件)。
```
lib/features/user/todo/1_domain/1_entities/GUIDE.md
lib/features/user/todo/1_domain/2_repositories/GUIDE.md
... (17 files, all GUIDE.md)
```

**経緯**: `add_feature_usecase.dart` が `GenerateGuidesUsecase` を呼び、`arch_definition.yaml` の guides 定義から各層に GUIDE.md を動的生成している。これは v0.4 時代の「プロジェクト内にガイドを置いて AI に読ませる」設計の名残。

**v1.0.0 の方針との矛盾**: v1.0.0 で「参照型ナレッジ」に移行し、`create` はナレッジツリーをコピーしなくなった(0.13.0)。ガイドは `guide show` / MCP `guide_get` で参照する建て付けになったのに、**`apply` だけが各 feature ディレクトリに GUIDE.md を撒き続けている**。結果、プロジェクトが GUIDE.md だらけになり、ナレッジの二重管理(同梱/キャッシュ版と feature 配下のコピー)が発生している。

**修正案(要判断)**:
- **A. 既定で生成しない**(推奨): `apply`/`feature add` は空のディレクトリ構造だけ作る。ガイドは `guide show`・`guide for <file>`・MCP で参照。手元に置きたい人向けに `guide eject` は既にある
- **B. オプトイン化**: `apply --with-guides` を付けた時だけ生成
- どちらでも `check` の期待構造からは GUIDE.md を外す必要がある(現在 extra 扱いにならないよう許容されているかを要確認)

**#15 との関係**: 「ナレッジをプロジェクトに置かない」という同じ方針の適用先が違うだけなので、**#15 と一体で設計するのが自然**。

---

## #12 `utakata check` — plan.yaml に書くと全層が計画済みになる

**報告**: plan.yaml に記載すると全ての層で計画されたことになってしまう。あくまでも yaml を生成し、1ファイルずつ手動で編集可能に。AI 用に CLI コマンドで追加することをサポートし、ファイル構造をサポート

**検証結果(再現)**: `features: [{name: todo, permission: user, entities: [todo]}]` の1行宣言だけで、**15ファイルが missing 判定**になる。
```
user/todo/1_domain/1_entities/todo_entity.dart
user/todo/1_domain/2_repositories/todo_repository.dart
user/todo/2_infrastructure/1_models/todo_model.dart
user/todo/2_infrastructure/2_data_sources/1_local/todo_data_source.dart
...(15件)
```

**原因**: `ExpectedStructureBuilder` が `arch_definition.yaml` の全レイヤー × 全ディレクトリを走査し、命名規則からファイル名を導出して「必須」としている(`expected_structure_builder.dart:55-85`)。つまり **feature を1つ宣言 = 4層フルセットを要求**という設計。

**これは意図的な設計だが、実運用と合っていない**: 実際の feature は「entity だけ先に作る」「remote data source は不要」「presentation は後回し」が普通で、常に全層必要とは限らない。現状は使わない層まで永久に missing 警告が出続けるか、ダミーファイルを作るしかない。

**報告者の要望(整理)**:
1. plan.yaml は「あくまで yaml を生成」= 構造の宣言に留め、全層の強制生成はしない
2. **1ファイルずつ手動で編集可能に** = 必要なファイルだけを段階的に追加できる粒度
3. AI 用に CLI コマンドで追加をサポート = `utakata add <層> <名前>` 的な、ファイル単位の追加コマンド

**修正案(要設計)**:
- plan.yaml の feature に**層/ファイル単位の宣言**を持てるようにする(例: `layers: [1_domain/1_entities, 3_application]` や `files:` の明示リスト)。未宣言の層は missing にしない
- 既定の挙動(層を書かない場合)は「全層要求」のままにするか、「entities に対応する最小セットのみ」にするかは要判断(後者の方が要望に沿う)
- ファイル単位の追加コマンド(`utakata add ...`)を新設し、plan.yaml への追記と生成を1操作で行う
- **影響範囲が大きい**(`ExpectedStructureBuilder` / `CheckUsecase` / `ApplyUsecase` / plan.yaml スキーマ)ので 1.1.0 相当

---

## #15 純粋な dart cli ツールへ — 0_templates を廃止しリモートから pull

**報告**: `packages/utakata_code/lib/src/0_templates` を廃止し、[utakata_arch_lib](https://github.com/utakata-code/utakata_arch_lib/tree/main/arches/clean_architecture) から pull するように変更。そもそも `dart activate` する際にネットワーク接続は必須かつ、arches/clean_architecture は公開リポジトリのため問題にならない

**現状**: v1.0.0 の S2/S3 で「Single Source of Truth は utakata_arch_lib」にし、リリース時に `tool/sync_arch_lib.dart` で同梱コピーを生成する方式にした。リモート fetch(`arch get` + `utakata.lock`)はオプトイン。

**規模の実測**:
- `lib/src/0_templates/`: **60ファイル / 628KB**(パッケージ全体177ファイルの1/3、圧縮後236KBの大半)
- 廃止すればパッケージは実質117ファイルの純粋な CLI になる

**報告の指摘は妥当**: `dart pub global activate` 自体がネットワークを要するので、「初回だけネットワークが要る」という条件は現状と変わらない。同梱コピーは二重管理(arch_lib を直しても CLI を再リリースするまで反映されない)でもある。

**ただし検討が必要な点**:

| 論点 | 内容 |
|---|---|
| 初回実行のオフライン性 | `activate` 時はネット必須でも、**その後の `create` 時にネットが無い**ケースは受託現場で起こりうる(クライアント環境・移動中)。`activate` 時にキャッシュを取りに行くのか、初回コマンド実行時なのかで体験が変わる |
| キャッシュの寿命 | `~/.utakata/cache/` にどう置くか。CLI バージョンとナレッジバージョンの対応をどう固定するか(現在は `utakata.lock` がプロジェクト単位) |
| 失敗時の挙動 | ネット断・GitHub 障害・リポジトリ改名時に何が起きるか。フォールバック無しなら CLI が完全に使えなくなる |
| git 依存 | 現在の fetch は `git clone` に依存。git が無い環境では動かない(tarball ダウンロードなら依存を外せる) |
| セキュリティ | 現在は `utakata.lock` の SHA 固定で改竄検知の代替にしている。デフォルト経路にする場合、SHA 固定をどう既定化するか |

**推奨アプローチ**: 廃止方針自体は v1.0.0 の設計思想の延長として正しい。ただし「同梱ゼロ」への一足飛びではなく:
1. まず **fetch を必須経路に格上げ**(`create` 時に未キャッシュなら自動 fetch)し、同梱は**フォールバック専用**に残す
2. 実案件で 1〜2 件回してオフライン問題が起きないことを確認
3. 問題なければ同梱を削除して純粋 CLI 化

この段階を踏めば、受託案件で「ネットが無くて create できない」事故を避けられる。

---

## 推奨リリース計画

### v1.0.2(バグ修正・すぐ出せる)
- **#14**: `doc init` が `doc/specs/plan.yaml` を生成する
- **#11**: `guide list/show/eject` + MCP `guide_get` + `feature add` のアーキ解決を `utakata.yaml` 起点に統一(解決ロジックを共通化)

### v1.1.0(設計変更・要判断)
- **#13 + #15**: ナレッジをプロジェクトに置かない方針の完遂。`apply` の GUIDE.md 生成停止 + 0_templates の段階的廃止(fetch 必須化 → 同梱削除)
- **#12**: plan.yaml の粒度モデル変更(層/ファイル単位の宣言)+ ファイル単位の追加コマンド新設

### 判断が必要な事項
1. **#13**: GUIDE.md は「完全に生成しない」か「オプトイン(`--with-guides`)」か
2. **#12**: 層を書かない場合の既定は「全層要求」か「最小セットのみ」か。ファイル追加コマンドの名前と粒度(`utakata add usecase get_todo` 的な形か)
3. **#15**: 同梱を即削除するか、fetch 必須化 → 実運用検証 → 削除の段階を踏むか

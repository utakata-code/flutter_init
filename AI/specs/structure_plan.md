# utakata CLI 改良 構造計画書

> 作成日: 2026-07-11
> 対象: `packages/utakata_code` v0.5.8 → v1.0.0
> 前提: [アプリケーション仕様書](application_specification.md)(以下「仕様書」)
> 凡例: 【新】新規 /【変】変更 /【継】継続 /【削】削除 /【移】移動

---

## 1. 構造方針と依存規約

- **3層維持**: `1_domain` / `2_infrastructure` / `3_application` + `0_templates`。presentation 層は作らない
- **依存方向**: `3_application → 1_domain ← 2_infrastructure`。domain は他層に依存しない
- **`dart:io` はインフラ層のデータソースのみ**が import できる(現行の `validate_usecase.dart` / `messages_resolver.dart` の直依存は解消)。custom_lint もしくは CI の import 検査で機械的に強制する
- **表示関心(i18n・Markdown レンダリング)はアプリケーション層**。エンティティの `toMarkdown()`(日本語ハードコード)は presenter へ退去
- **I/O の注入は repository インターフェースに整理**: 現行の「fs のメソッド参照を個別関数注入」の乱立をやめ、テスト時はフェイク実装1つで済む形に
- **既存の番号付きディレクトリは温存**する(全面リナンバーの churn を避ける)。新設ディレクトリの命名規則: **既存の番号付き階層の「間」に挿入する概念は無番号**(`services/` は `1_entities/` と `2_repositories/` の間の横断概念のため `exceptions/` と同様に無番号)、**既存階層と並ぶ末尾追加は番号を振る**(`3_presenters/`・`4_server/` は `1_commands/`・`2_runner/` に続く3・4番目の関心事のため番号付き)
- **infra に `1_models/` を新設**(開発者承認済み): シリアライズ形式(JSONL / YAML / frontmatter)の知識を domain から完全に隔離。スキーマ検証はモデル層で「大声で」失敗する(P6)

## 2. 目標ディレクトリ構造(lib/src 全量)

### 2.1 `1_domain/`

```
1_domain/
├── 1_entities/
│   ├── structure/                                【新】正準構造モデル(仕様書§5)
│   │   ├── structure_path.dart                   【新】正規化・direct展開の唯一の場所
│   │   ├── structure_node.dart                   【新】sealed Dir/File(kind: source|generated|ignored)
│   │   ├── structure_snapshot.dart               【新】不変スキャン結果
│   │   ├── expected_structure.dart               【新】requiredDirs/requiredFiles/allowRules
│   │   └── check_report.dart                     【新】型付き違反(旧 diff+validation 結果を統合)
│   ├── plan/
│   │   └── plan_intent.dart                      【新】意図レベル計画(schema:1, baseline フラグ)
│   ├── record/                                   【新】三者モデル(仕様書§7-8)
│   │   ├── record_id.dart                        【新】MsgId/AgrId/PlanId 値オブジェクト(parse/validate)
│   │   ├── log_entry.dart                        【新】会話メッセージ(形式非依存)
│   │   ├── agreement.dart                        【新】合意+AgreementEvent(追記イベント畳み込み)
│   │   ├── impl_plan_meta.dart                   【新】frontmatter 相当+状態遷移(canTransitionTo)
│   │   └── source_ref.dart                       【新】ID参照/ファイルパス参照/spec:F-NN の判別 union
│   ├── knowledge/
│   │   └── knowledge_item.dart                   【新】source: package|user|project の3層解決結果
│   ├── architecture_definition_entity.dart       【継】(表示ロジックがあれば presenter へ)
│   ├── architecture_diff_entity.dart             【削】v0.7(CheckReport に統合)
│   ├── core_module_entity.dart                   【継】
│   ├── feature_spec_entity.dart                  【変】未使用 isEntitySameAsFeature 削除
│   ├── guide_entity.dart                         【変】render() を guide_presenter へ移設(呼び出し元 generate_guides_usecase も同時に【変】。domain usecase はレンダリング済み文字列を presenter から受け取る形にシグネチャ変更し、domain→application 依存を発生させない)
│   ├── project_spec_entity.dart                  【変】未使用 layoutId 削除
│   ├── project_status_entity.dart                【変】toMarkdown() を status_presenter へ移設
│   ├── template_file_entity.dart                 【継】
│   └── validation_result_entity.dart             【削】v0.7(CheckReport に統合)
├── services/                                     【新】純関数サービス(状態なし・I/Oなし)
│   ├── case_converter.dart                       【新】4重複(_toSnakeCase 等)を1実装に統合
│   ├── name_rule_matcher.dart                    【新】最深 dir_pattern 優先(exceptions/ バグ解消)
│   ├── expected_structure_builder.dart           【新】plan_intent+arch定義 → ExpectedStructure
│   ├── structure_checker.dart                    【新】差分+命名の単一走査(check の心臓部)
│   └── date_resolver.dart                        【新】"6/30 17:41" → ISO 8601 補完(log 用)。**基準日時(now)を引数で受け取る純関数**とし、呼び出し元 usecase が clock を注入する(現在時刻への暗黙依存を避け純粋性を保つ)
├── 2_repositories/
│   ├── architecture_repository.dart              【継】
│   ├── template_repository.dart                  【継】
│   ├── project_repository.dart                   【変】snapshots 系メソッド削除(scan 廃止)、readCurrentStructure 削除
│   ├── structure_repository.dart                 【新】scan() → StructureSnapshot(実構造の読み取り)
│   ├── plan_repository.dart                      【新】read / adoptEdit(yaml_edit による外科的挿入)
│   ├── record_repository.dart                    【新】log append/query・agreement append/fold
│   ├── impl_plan_repository.dart                 【新】create / readMeta / updateStatus / archive
│   └── knowledge_repository.dart                 【新】3層解決・eject(単純コピー。manifest 台帳は持たない)
├── 3_usecases/
│   ├── check_usecase.dart                        【新・統合】旧 diff+validate+check+記録系整合検査
│   ├── apply_usecase.dart                        【新・統合】旧 feature init+core(ExpectedStructure の裏返し)
│   ├── adopt_plan_usecase.dart                   【新】未計画 feature の検出→追記案生成
│   ├── create_project_usecase.dart               【変】既存成果物スキップによる冪等再実行対応、テンプレ展開縮小
│   ├── add_feature_usecase.dart                  【変】実装計画ゲート+--template 適用(単一トランザクション)
│   ├── scan_project_status_usecase.dart          【変】日本語文字列判定の除去、arch 検出を1実装に
│   ├── status_usecase.dart                       【変】analyze 対象限定、diff→check 参照
│   ├── generate_guides_usecase.dart              【変】guide_entity.render() 削除に伴い、レンダリング済み文字列を presenter から受け取る形にシグネチャ変更
│   ├── list_architectures_usecase.dart / show_architecture_usecase.dart / export_architecture_usecase.dart 【継】(実名: 複数形 list_architectures)
│   ├── create_architecture_usecase.dart          【変】arch eject に改名対応(テンプレ経由化)
│   ├── add_log_entry_usecase.dart                【新】検証(未来日時・重複・reply先)→採番→append→プレビュー再生成
│   ├── query_log_usecase.dart                    【新】`log show`(--date/--thread/--tag/MSG-ID の検索)。MCP `log_query` ツールと責務共有
│   ├── render_log_preview_usecase.dart           【新】
│   ├── record_agreement_usecase.dart             【新】add/status/correct/reflect(全て追記イベント)
│   ├── list_agreements_usecase.dart              【新】`agree list [--unreflected]`(反映漏れの畳み込み判定)
│   ├── render_agreements_preview_usecase.dart    【新】`agree render`
│   ├── render_summary_usecase.dart               【新】マーカー区間の再生成
│   ├── impl_plan_usecase.dart                    【新】new/list/done/archive+ゲート判定
│   ├── guide_usecase.dart                        【新】list/show/eject(元id・versionのコメント1行を残す単純コピー。manifest/hash 照合は行わない)
│   ├── init_doc_usecase.dart                     【新】doc/ ワークスペース先行生成
│   ├── doctor_usecase.dart                       【新】診断+--migrate(旧レイアウト移行。schema 変更時の records 変換を保証)+--sync
│   ├── plan_architecture_usecase.dart            【削】v0.7(具象ツリー生成の廃止)
│   ├── scan_structure_usecase.dart               【削】v0.7(scan 廃止)
│   ├── diff_architecture_usecase.dart            【削】v0.7(check_usecase に統合)
│   ├── validate_usecase.dart                     【削】v0.7(同上。dart:io 直依存も同時に消える)
│   ├── check_structure_usecase.dart              【削】v0.7(diff への単純委譲だったもの)
│   ├── init_features_usecase.dart                【削】v0.7(apply_usecase に統合)
│   └── generate_core_usecase.dart                【削】v0.7(同上)
├── exceptions/
│   └── domain_exceptions.dart                    【変】throw 箇所ゼロの4種を削除、実際に投げる型のみ+新設(SchemaViolation, RecordConflict, GateViolation 等)
└── messages/                                     【移】3_application/messages/ へ(表示関心の帰還)
```

### 2.2 `2_infrastructure/`

```
2_infrastructure/
├── 1_models/                                     【新設】DTO 層(形式 ⇔ entity 変換+スキーマ検証)
│   ├── plan_file_model.dart                      【新】plan.yaml schema:1 検証(行番号付きエラー)
│   ├── log_entry_model.dart                      【新】JSONL 1行 ⇔ LogEntry(dart:convert)
│   ├── agreement_model.dart                      【新】JSONL 1行 ⇔ AgreementEvent
│   ├── impl_plan_front_matter_model.dart         【新】frontmatter ⇔ ImplPlanMeta(本文バイト列は不変更)
│   └── check_report_model.dart                   【新】CheckReport ⇔ --json / レポート出力
├── 2_data_sources/
│   ├── 1_local/
│   │   ├── filesystem_data_source.dart           【変】ディレクトリ・単純ファイルI/O(read/write/ensureDir/scan)を担当。スキャン時の generated 分類を一元化。**dart:io の import は本ディレクトリ(2_data_sources/)配下に限定**し、filesystem/yaml/jsonl/process/front_matter/marker の各データソースがそれぞれ責務を持つ(唯一の玄関ではなく「domain からは全て隠蔽される」という制約)
│   │   ├── yaml_data_source.dart                 【変】読み取り専用化。parse 失敗は型付き例外(catch(_) 廃止)。**serialize(自作シリアライザ)削除**
│   │   ├── yaml_edit_data_source.dart            【新】package:yaml_edit で外科的編集(plan adopt / --template 追記)
│   │   ├── jsonl_data_source.dart                【新】追記専用(flush+fsync)・行単位読取・破損行の退避
│   │   ├── front_matter_data_source.dart         【新】--- 区切りの読み書き
│   │   └── markdown_marker_data_source.dart      【新】utakata:begin/end 区間の置換(summary 用)
│   └── 2_remote/
│       └── process_data_source.dart              【変】flutter 解決の遅延化(create() の起動時実行をやめ初回使用時に)。`pub run`→`dart run` 化
└── 3_repositories/
    ├── architecture_repository_impl.dart         【変】getAll の catch(_) スキップ廃止(壊れた定義は警告付き報告)
    ├── project_repository_impl.dart              【変】snapshots 系削除、doc/ 新レイアウト対応
    ├── template_repository_impl.dart             【変】3層解決(project→~/.utakata→package)対応
    ├── structure_repository_impl.dart             【新】
    ├── plan_repository_impl.dart                  【新】
    ├── record_repository_impl.dart                【新】
    ├── impl_plan_repository_impl.dart             【新】
    └── knowledge_repository_impl.dart             【新】
```

### 2.3 `3_application/`

```
3_application/
├── 1_commands/
│   ├── base_command.dart                         【変】on Exception → 型別ハンドリング+終了コード 0/1/2/64 厳密化
│   ├── create_command.dart                       【変】既存成果物をスキップする冪等再実行に対応(ステップマニフェスト+`--resume` は実装しない。§15 棚上げ)、ケース変換を services/ へ委譲
│   ├── feature_command.dart                      【変】add のみ(init はエイリアス委譲)。--template / --no-plan。BaseCommand 継承に統一
│   ├── apply_command.dart                        【新】--scope core|feature / --dry-run
│   ├── check_command.dart                        【変】統合先(--json/--quick/--file/--ci/--docs)
│   ├── plan_command.dart                         【変】adopt サブコマンド化。旧 plan 生成は v0.7 で削除
│   ├── status_command.dart                       【変】--brief / --json / --write-report
│   ├── log_command.dart                          【新】add / show / render(v1.0 で import --file)
│   ├── agree_command.dart                        【新】add / status / correct / reflect / list / render
│   ├── impl_command.dart                         【新】new / list / done / archive
│   ├── summary_command.dart                      【新】
│   ├── guide_command.dart                        【新】list / show / eject
│   ├── doc_command.dart                          【新】init
│   ├── doctor_command.dart                       【新】--migrate / --sync
│   ├── arch_command.dart                         【変】create → eject 改名(旧名は警告付きエイリアス)
│   ├── mcp_command.dart                          【新】v1.0
│   ├── deprecated_aliases.dart                   【新】scan(no-op警告)/ diff / validate / feature init / core → 委譲+非推奨警告。v1.0 で削除
│   └── logger.dart                               【変】NO_COLOR 対応
├── 2_runner/
│   └── command_runner.dart                       【変】バージョンは version.g.dart 参照(ハードコード削除)
├── 3_presenters/                                 【新設】表示変換(i18n の実装点)
│   ├── check_report_presenter.dart               【新】違反+GUIDE 要点埋め込み(仕様書§4)
│   ├── status_presenter.dart                     【新】ProjectStatusEntity.toMarkdown の移設先(ja/en)
│   ├── log_preview_presenter.dart                【新】IDアンカー付き .md 生成
│   ├── agreement_preview_presenter.dart          【新】
│   ├── summary_presenter.dart                    【新】§10 体裁・金額集計
│   └── guide_presenter.dart                      【新】GuideEntity.render の移設先
├── 4_server/
│   └── mcp_server.dart                           【新】v1.0。stdio JSON-RPC・読み取り専用7ツール・ステートレス(呼び出しごとに usecase 実行)
└── messages/                                     【移】1_domain/messages/ から移設
    ├── cli_messages.dart / ja_messages.dart / en_messages.dart   【変】新コマンド文言を追加(実ファイル名踏襲)
    └── messages_resolver.dart                    【変】env 読みをアプリ層責務として整理
```

### 2.4 `0_templates/` とパッケージ直下

```
0_templates/
├── architectures/{clean_architecture,mvvm}/
│   ├── arch_definition.yaml                      【継】参照元(配布はしない)
│   ├── AI/architecture/**(GUIDE.md, guides/, *.tmpl)【継・非配布化】guide show / feature 生成の参照元として残す
│   ├── AI/scripts/**                             【削】v1.0(非推奨シェルの同梱終了。v0.9 までは非推奨ヘッダ付きで併生成)
│   ├── AI/snapshots/**                           【削】v0.7(スナップショット廃止)
│   ├── AI/specs/**                               【移】→ project_skeleton/doc/specs/
│   ├── AI/logs/**(conversation_log.md)           【削】v0.8(仕様書§12・未決事項4に対応。生成テンプレートから廃止)
│   └── .agent/**                                 【削】v1.0(v0.9 までは非推奨ヘッダ付きで併生成)
├── project_skeleton/                             【新】要編集ファイル一式(5ファイル)
│   ├── utakata.yaml.tmpl
│   ├── doc/specs/{application_specification.md, structure_plan.md, plan.yaml}.tmpl
│   ├── doc/summary.md.tmpl(マーカー区間入り)
│   └── doc/impl/_template.md.tmpl(実案件テンプレ§1〜§8 の正式化。「utakata diff ゼロ維持」→「utakata check ゼロ維持」へ更新)
├── claude/                                       【新】.claude/ 生成物の雛形
│   ├── settings.json.tmpl(hooks+permissions)
│   ├── skills/{utakata-spec,utakata-structure,utakata-implement,utakata-feature-plan,utakata-client-context}/SKILL.md.tmpl
│   └── agents/{structure-auditor,impl-planner}.md.tmpl
└── feature_templates/                            【新】プリセット機構の内蔵層(v1.0 時点でコンテンツは空。README のみ)

bin/utakata.dart                                  【変】手動DI更新。flutter 未検出での即 exit(1) を廃止(遅延解決)
lib/utakata.dart                                  【変】export 整理(新エンティティ追加・削除分の除去)
lib/src/version.g.dart                            【新】pubspec.yaml から生成(tool/generate_version.dart + CI 一致テスト)
tool/generate_version.dart                        【新】
pubspec.yaml                                      【変】依存追加: yaml_edit。削除: io(未使用)。dev: test 拡充
```

## 3. 生成プロジェクト側のデータ配置

仕様書§12 の通り。CLI 側の対応物:

| 生成物 | 書き込み経路(repository) | 形式 |
|--------|--------------------------|------|
| `doc/specs/plan.yaml` | plan_repository(read + yaml_edit 追記のみ) | YAML(人間主権) |
| `doc/records/log/YYYY-MM.jsonl` | record_repository(jsonl append) | JSONL |
| `doc/records/agreements.jsonl` | record_repository(jsonl append) | JSONL |
| `doc/preview/*.md` | presenter 出力(毎回全再生成・冪等) | Markdown(自動生成ヘッダ) |
| `doc/impl/PLAN-*.md` | impl_plan_repository(frontmatter のみ機械管理) | Markdown+frontmatter |
| `doc/summary.md` | markdown_marker_data_source(区間置換のみ) | Markdown(共存) |
| `doc/records/log/attachments/` | record_repository(添付ファイルのコピー) | バイナリ(任意フィールド `attachments` の実体) |
| `.utakata/create_state.json` / `cache/` | 各 usecase | JSON(gitignore) |

## 4. テスト計画

```
test/
├── unit/
│   ├── domain/services/          # case_converter(round-trip プロパティテスト)/ name_rule_matcher /
│   │                             # expected_structure_builder / structure_checker / date_resolver
│   ├── domain/entities/          # structure_path(正規化の冪等性)/ record_id / agreement(イベント畳み込み)/ impl_plan_meta(状態遷移)
│   ├── domain/usecases/          # 全ユースケース(フェイク repository 1式で駆動)— CI ゲート「usecase 追加にはテスト必須」
│   ├── infrastructure/models/    # 各モデルの parse/serialize round-trip・スキーマ違反時の型付き例外
│   └── infrastructure/data_sources/  # jsonl(破損行退避・fsync)/ yaml_edit(コメント保持)/ front_matter / marker
├── golden/
│   ├── check/                    # fixture ツリー × plan.yaml → 期待 CheckReport のテーブル駆動
│   │   └── regressions/          # ★実際に再現する3件を先に固定: files_dir_confusion / feature_prefix / validate_direct_uncompensated
│   │                             #   対処済みの2件(freezed_g_dart / exceptions_parent_rule)は正準モデルへの回帰ケース追加のみ
│   └── render/                   # preview/summary/status の出力ゴールデン
├── migration/                    # doctor --migrate: 0.5系レイアウト fixture → 新レイアウト(実案件 doc/ の匿名化コピーを fixture に)
└── e2e/                          # tmp ディレクトリでの create → apply → check → log/agree/impl の通し(flutter 呼び出しはフェイク process)
```

方針: Builder / Checker / Scanner の分離により、**ファイル I/O なしで差分ロジック全体が単体テスト可能**になっていることが v0.6 の受け入れ条件。

## 5. バージョン別の作業分解

現行コードベース(約53ファイル・4,620行・テスト1本)と同程度以下に各版の差分を収める(仕様書§14)。

### v0.6.0 — 負債返済(外部非互換なし)
1. `test/golden/check/regressions/` に**実際に再現する3件**(files_dir_confusion / feature_prefix / validate_direct_uncompensated)の回帰ケースを**現行の誤動作のまま**記録。対処済みの2件(freezed_g_dart / exceptions_parent_rule)は正しい動作のまま回帰ケースを追加
2. `1_entities/structure/` + `services/`(case_converter, name_rule_matcher, expected_structure_builder, structure_checker)を新設、ユニットテスト同時作成(この時点では diff/validate コマンドは変更しない。正準モデルは内部で並走させ、次版で載せ替える)
3. version.g.dart 生成+CI 一致テスト / catch(_) 全廃 / flutter 遅延解決 / analyze 対象限定 / messages 移設+status presenter 化 / 未使用コード削除(io 依存・死にメソッド・未使用例外)

### v0.7.0 — plan 意図レベル化+check/apply 統合
4. plan_file_model(schema:1) / plan_repository(`doc/specs/plan.yaml` 優先・旧 `feature_request.yaml` の読み取り専用フォールバック実装)/ yaml_edit_data_source
5. 旧 diff/validate usecase の内部を正準モデルへ載せ替え → 回帰ケースの期待値を「正しい動作」に反転して3件修正。`check_usecase` 統合(check_command 拡張、diff/validate をエイリアス化)/ `apply_usecase` 統合(feature init・core エイリアス化)/ `adopt_plan_usecase`
6. scan・旧 plan 生成の廃止告知(no-op)/ 自作シリアライザ削除 / create の冪等再実行(既存成果物スキップ。ステップマニフェスト+`--resume` は実装しない。§15 棚上げ)

### v0.8.0 — 記録系コア+doc/ レイアウト移行
7. record/ エンティティ(log_entry, source_ref 等)+ jsonl/front_matter/marker データソース + record_repository
8. `log_command`(add/show/render。**最小のヒューリスティック import を同梱**: 話者・日時見出しの2パターン+確認テーブル)/ `doc_command`(init)/ `utakata.yaml`
9. **doctor --migrate**: §6 の変換表全項目(AI/→doc/、feature_request.yaml→plan.yaml、実案件 doc/ の全構成物)を実装。migration テスト必須(実案件 doc/ の匿名化コピーを fixture に)。records の git 方針(commit|ignore)実装。schema 変更時の変換提供を今後の受け入れ条件とする

### v0.9.0 — 合意・実装計画・サマリー
10. agreement/impl_plan_meta エンティティ + impl_plan_repository
11. `agree_command`(add/status/correct/reflect/list/render。enforcement は `on`/`off` の2値)/ `impl_command`(new/list/done/archive)/ `summary_command`(マーカー区間生成)

### v1.0.0 — 参照化と Claude Code
12. テンプレ展開の project_skeleton 化(約106→約15ファイル、うち要編集5)/ AI/scripts・AI/logs 同梱終了(v0.7〜v0.9 の間は非推奨ヘッダ付きで併存させず、v1.0 で一括終了)
13. knowledge_repository(3層解決)/ `guide_command`(list/show/eject。単純コピー方式・manifest 台帳なし)/ arch eject 改名
14. claude/ 雛形一式+create/doctor --sync での生成 / feature add --template 機構(dry-run→単一トランザクション)/ `.agent/` 非推奨化

### v1.1.0 — AI 面の完成と安定化
15. mcp_command+mcp_server(ステートレス・読み取り専用7ツール)/ .mcp.json 生成
16. log import --file の完全版パーサ(旧 .md 一括取込)
17. 全エイリアス削除(`diff` を除く)/ `.agent/` 生成停止 / ドキュメント整備(README・CHANGELOG・移行ガイド)

## 6. `doctor --migrate` の変換仕様(概要)

| 旧(0.5系生成物・実案件運用物) | 新 |
|----|----|
| `AI/specs/feature_request.yaml` | `doc/specs/plan.yaml`(schema:1 へ変換。全 feature に `baseline: true` 付与) |
| `AI/specs/plan_architecture.yaml` | 削除(導出可能な生成物のため。snapshots と同扱い) |
| `AI/specs/*.md` | `doc/specs/` へ移動 |
| `AI/snapshots/**` | 削除(導出可能なため。バックアップ案内を表示) |
| `AI/architecture/**` | ローカルカスタムが**内蔵版と差分ありの場合のみ** `.utakata/overrides/` へ。無編集なら削除(参照化) |
| `AI/logs/conversation_log.md` | 内容があれば `doc/impl/research/` へ移設、空なら削除 |
| `doc/log/raw/*.md`(実案件) | `doc/records/log/legacy/` へ凍結移動 |
| `doc/log/impl/*.md`・`doc/log/impl/archive/`(実案件) | `doc/impl/PLAN-*.md`(front matter を新規付与。既存本文はそのまま)・`doc/impl/archive/` |
| `doc/log/post_contract_summary_*.md`(実案件) | `doc/impl/research/` へ移設(サマリー本体は手書き資料として維持。§7.3 のマーカー生成対象は `doc/summary.md` の新規区間のみで、過去サマリーは書き換えない) |
| `doc/案件整理サマリー.md`(実案件) | `doc/summary.md` へリネーム。§10 相当のセクションにマーカー `<!-- utakata:begin agreements -->` を挿入し、既存の合意記述は `agree add --from <legacy>` で `agreements.jsonl` へ個別移行(自動変換はしない。人間が確認しながら移す) |
| `doc/guides/{store,payment,infrastructure,testing,troubleshooting}/**`(実案件) | `~/.utakata/knowledge/` へ移動(案件非依存ナレッジ) |
| `doc/guides/project/**`(実案件) | `doc/knowledge/` へ移動(案件固有ナレッジ) |
| `doc/archive/**`(実案件) | `doc/archive/` のまま維持(凍結資料。パスは不変) |
| `.agent/**` | 削除(移行時に `.claude/` を生成) |

変換は dry-run 既定・実行前に全件の移動計画を提示。**移行テスト(実案件 doc/ の匿名化 fixture)を伴わない limit はリリースしない。**

## 7. リスクと対応

| # | リスク | 対応 |
|---|--------|------|
| 1 | 移行(doctor --migrate)のバグ=実案件記録の破損 | dry-run 既定・移動のみ(削除は確認後)・migration テスト必須(§4)・実行前に `git status` クリーン要求 |
| 2 | yaml_edit の編集能力限界 | adopt/template 追記は「features 配列への要素追加」等の単純操作に限定。複雑な再構成は人間に委ねる |
| 3 | ID 採番(max+1)のブランチ間衝突 | 単独運用前提を仕様書§7.4 に明記。check が重複検知。チーム運用は将来課題 |
| 4 | plan_architecture.yaml → 意図レベルへの変換で情報が落ちる | v0.7 設計時に実案件の plan で写像検証。落ちる情報(手書き `__files__` 個別指定)は allowRules で吸収されることを移行テストで確認 |
| 5 | フックの遅延がAI編集の体感を損なう | AOT snapshot 実行前提+`--quick --file` の単一ファイル粒度。実測が 100ms を超える場合は PostToolUse を非同期化 |
| 6 | pub.dev 配布サイズ(ナレッジ内蔵) | 上限接近時は初回実行時に `~/.utakata/` へ展開する方式に切替可能な構造(knowledge_repository の解決層で吸収) |
| 7 | 大規模リポジトリでスキャンが遅くなる | 設計上の拡張点: structure_repository の実装差し替えで watcher 加速器を後付け可能(インターフェース不変) |

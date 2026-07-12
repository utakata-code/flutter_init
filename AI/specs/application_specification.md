# utakata CLI 改良 アプリケーション仕様書

> 作成日: 2026-07-11
> 作成者: Claude Code(泡沫Code との協議に基づく)
> 対象: `packages/utakata_code`(pub.dev: `utakata`)v0.5.8 → v1.0.0
> 根拠資料: [現状と課題](current_state_and_issues.md) / [会話ログ](../logs/conversation_log.md)
> 姉妹文書: [構造計画書](structure_plan.md)

---

## 1. 目的とビジョン

utakata を「開発者と AI の二者共作テンプレート」から、**受託開発の現場で使える「お客様・開発者・AI の三者共作基盤」**へ改良する。

- **お客様**との会話・合意が構造化され、要件の出典として追跡できる
- **開発者(人間)**は記録と意思決定を担い、CLI が規律の検出を担う
- **AI(Claude Code)**は構造・仕様・合意・ログを「推測でなく参照」で扱い、ガードレールは仕組みで働く

方針は一貫して「**堅牢に・疎結合に**」。CLI 本体は 1_domain / 2_infrastructure / 3_application の3層を維持する(presentation 層は作らない。インフラ層にモデルを置くのは可)。

## 2. 設計原則

| # | 原則 | 帰結 |
|---|------|------|
| P1 | **ファイルシステムが唯一の真実(SSOT)** | スナップショット・サーバー状態・キャッシュは全て「破棄可能な導出物」。壊れたら再スキャンで必ず復元できる |
| P2 | **全コマンドはデーモン非依存で完結** | 常駐プロセスを前提にしない。毎回その場でスキャンする(実測: 数十ms) |
| P3 | **中間生成物の削減** | 生成された具象ツリー `plan_architecture.yaml` と `current_structure.yaml` は廃止。変換が1回減れば壊れる場所が1つ減る |
| P4 | **機械が書くのは JSON/JSONL、人間が書くのは YAML/Markdown** | 自作 YAML シリアライザは全廃。機械が YAML に触るのは「読む+外科的編集(`package:yaml_edit`)」のみ |
| P5 | **正規化は一箇所** | パス正規化・`direct` 展開・ケース変換・生成ファイル判定を単一の正準モデルに集約。plan 側と diff 側の相互補償バグを構造的に不可能にする |
| P6 | **失敗は大声で** | `catch (_)` 全廃。型付き例外。終了コード: 0=成功 / 1=検証違反 / 2=実行時エラー / 64=usage |
| P7 | **強制は「検出して教える」を基本とする** | 作業を止めるゲートはフローの結節点(コマンド実行時・CI)に限定し、日常編集は妨げない。迂回フラグは用意するが記録される |
| P8 | **記録は人間、読み取りは AI** | お客様との会話・合意の書き込み経路は人間のコマンドのみ。AI には読み取り手段だけを提供する |

## 3. 「常時監視サーバー」構想への設計回答

当初構想は「lib/ を常時監視するローカルサーバーを立て、スナップショットを廃止する」だった。**目的(常に現在の状態が分かる・スナップショット廃止)は全面採用し、手段(常駐プロセス)は不採用とする。**

- 検証の結果、`lib/` のフルスキャンは数十msで完了する。**毎回その場でスキャンする方が、常駐プロセスより「常に最新」である**(プロセス残留・状態とディスクの不整合・git ブランチ切替時の誤判定・OS 差異という障害クラスをまるごと持たずに済む)
- したがって `scan` コマンドと `current_structure.yaml` は**廃止**。`check` / `status` / `apply` は常にその場の実構造を見る
- AI 向けの常時アクセスは **`utakata mcp`(stdio 起動の MCP サーバー)**で提供する。Claude Code がプロセスを spawn/kill する「クライアント所有」モデルのため、孤児プロセスが定義上発生しない。**MCP サーバーは状態を持たない**(ツール呼び出しごとに新規スキャン)
- 将来リポジトリが巨大化して再スキャンが遅くなった場合のみ、watcher を「加速器」として後付けする(状態を持たない設計なので後付けが容易)

## 4. コマンド体系(新旧対応)

| 分類 | コマンド | 由来 | 内容 |
|------|---------|------|------|
| 生成 | `create <app> [--resume]` | 継続+拡張 | 手順マニフェスト(`.utakata/create_state.json`)を書きながら実行し、build_runner 失敗等から `--resume` で再開可能。`.claude/` と `.mcp.json` を生成。編集不要ファイルはコピーしない(§9) |
| 生成 | `doc init` | 新設 | Flutter プロジェクト作成**前**に案件ルートへ `doc/` ワークスペース+`utakata.yaml`(`project.app` 未設定状態)だけを先行作成(契約前フェーズの一級市民化)。同ディレクトリで後から `create` を実行すると `flutter create .` 相当で合流する(§17 論点1) |
| 生成 | `feature add <name> [--template <id>] [--no-plan]` | 継続+拡張 | 実装計画ゲート付き(§8)。`--template` はプリセット適用(§10) |
| 生成 | `apply [--scope core\|feature] [--dry-run]` | **統合**(旧 `feature init`+`core`) | 「期待構造にあって実体にない部分」を生成。check と同一の期待構造モデルの裏返しなので `__files__` 無視バグが構造的に消える |
| 計画 | `plan adopt` | 新設 | スキャンで見つかった未計画 feature を意図レベルの追記案として提示し、確認後 `yaml_edit` で `plan.yaml` に外科的挿入(§6) |
| 計画 | `impl new/list/done/archive <feature>` | 新設 | feature 実装計画書のライフサイクル(§8) |
| 検証 | `check [--json] [--quick] [--file <p>] [--ci] [--docs]` | **統合**(旧 `diff`+`validate`) | 1回の決定的走査で構造差分+命名違反+記録系整合を全報告。違反メッセージに GUIDE 要点を同梱(違反した瞬間に正解を提示) |
| 状態 | `status [--brief] [--json] [--write-report]` | 継続+改善 | analyze 対象を `lib/ test/` に限定(build/ ノイズ解消)。`--brief`/`--write-report`(出力先 `doc/preview/status.md`)は **analyze・プロセス呼び出しを行わない**(スキャン+記録系読み取りのみ)。analyze を含む完全実行は手動専用。レンダリングはプレゼンター層で i18n 対応 |
| 記録 | `log add/show/render` | 新設 | お客様会話の構造化記録(§7)。人間専用 |
| 記録 | `agree add/status/correct/reflect/list/render` | 新設 | 合意トラッキング(§7)。追記専用+supersede |
| 記録 | `summary` | 新設 | 案件整理サマリーのマーカー区間(合意ログ・金額集計)を台帳から再生成。手書き部と共存 |
| 知識 | `guide list/show/eject` | 新設 | 参照型ナレッジ(§9)。eject は来歴ヘッダ+manifest 記録 |
| 定義 | `arch list/show/export/eject` | 継続+改名 | `arch create` → `arch eject`(参照化に伴う意味の明確化) |
| AI | `mcp` | 新設(v1.0) | stdio MCP サーバー。全ツール読み取り専用・ステートレス(§11) |
| 診断 | `doctor [--migrate] [--sync]` | 新設 | flutter 解決・スキーマ検証・manifest 整合・`.claude/` 乖離の診断。旧レイアウトからの移行 |
| 廃止 | `scan` / 旧 `plan`(具象ツリー生成) | **廃止** | P1/P3。v0.7 で no-op エイリアス+警告、v1.0 で削除 |
| 廃止 | `validate` / `feature init` / `core` | **エイリアス化** | check / apply へ委譲+非推奨警告。v1.0 で削除 |
| 廃止 | `diff` | **エイリアス化(存続)** | `check` への委譲エイリアスとして **v1.0 以降も残す**(他の廃止コマンドと異なり削除しない)。実案件の実装計画テンプレート文言「utakata diff ゼロ維持」は §8 のテンプレート正式化時に「utakata check ゼロ維持」へ更新するが、コマンド自体の互換は保つ |

横断変更: flutter 解決の遅延化(不要コマンドで起動時に exit しない)、主要コマンドの `--json` 対応(フックと MCP の共通データ面。出力はソート済みで決定的)、全コマンドの BaseCommand 統一(feature 系・arch 系のサブコマンドが BaseCommand を継承せず try/catch がない現状を解消)。

## 5. 正準構造モデルと check(課題③の土台)

現行の `plan`(direct をネストして書く)⇔ `diff`/`validate`(読み時にフラット展開して補償する)という**相互補償で偶然成立している未テスト変換**を廃止し、単一の正準モデルに載せ替える。

```
plan.yaml(人間/AIが書く・意図レベル)        lib/(実体)
        │                                     │
        ▼ ExpectedStructureBuilder(純関数)     ▼ StructureScanner(読むだけ)
  ExpectedStructure ──────────┬────── StructureSnapshot
                              ▼
                       StructureChecker(純関数)
                              ▼
                         CheckReport
```

- `StructurePath`: lib/ 相対・POSIX 区切りに正規化。feature の同一性は `(permission, name)`。`direct` の「features 直下配置」は**正準化層の1箇所だけ**が知る
- `StructureNode`(sealed): Dir / File(kind: `source` | `generated` | `ignored`)。`*.g.dart`/`*.freezed.dart` は**スキャナが1箇所で** generated に分類し、命名検証・差分の対象外(誤検知バグ2件の恒久解消)。`__files__` という文字列規約のエンコード自体を廃止(誤認バグのクラスごと消滅)
- 命名規則の適用は**最深 `dir_pattern` 優先**(`exceptions/` に親規則が当たるバグの解消)
- 既知バグは HEAD 時点で `test/regression/known_bugs_test.dart` として実際にコードを動かして検証した。再現が確認できたのは2件:
  1. `validate` が `direct` パーミッションの補償展開を行わないため、plan と実構造が完全一致していても `missing: direct` / `extra: {featureName}` を誤検知する(diff 側は 0.5.8 で `direct` をフラット展開する補償が実装済みだが、validate 側には同じ補償がない。旧課題文書に未記載だった実挙動)
  2. `diff`/`validate` は、命名が非決定的で plan 側に `__files__` が生成されないディレクトリ(`{verb}`や`|`を含む description を持つ layer、典型的には `3_usecases/` 等)で、実際に存在する正当な実装ファイルを**常に extra として誤検知する**。plan にファイル名が1つも列挙されていないディレクトリでは、命名規則に合うファイルは元々許可されるべきだが、現行実装はそう扱わない
  
  旧課題文書が挙げていた「`*.freezed.dart`/`*.g.dart` の命名違反誤判定」「`exceptions/` サブディレクトリへの親規則適用」の2件は現行コードで再現しなかった(`filesystem_data_source.dart`/`validate_usecase.dart` で既にアドホックに対処済み)。「feature 名プレフィックス不一致」は未検証のまま残る。**再現した2件を回帰テストとして先に固定してから**このモデルで修正し、対処済みの2件は正準モデルへの集約と回帰テスト追加のみ行う
- 正準モデル・`check`/`apply` は `arch_definition.yaml` 駆動であり、`clean_architecture` に限らず `mvvm` テンプレートを含む全アーキテクチャ定義に等しく適用される。mvvm も v1.0 の参照化(§9)・回帰テスト整備(§13)の対象

## 6. plan の意図レベル化(課題③の本体)

生成された具象ツリー `plan_architecture.yaml` を廃止し、**人間/AI が書く意図レベルの `doc/specs/plan.yaml`** に一本化する。

```yaml
schema: 1
project: { architecture: clean_architecture }
features:
  - name: notification
    permission: user
    entities: [notice, notice_channel]   # → notice_entity.dart 等が決定的に導出される
    baseline: true                        # 初回 apply 時に自動付与(実装計画ゲートの免除マーカー)
```

「後からの変更に弱い」の解消は**双方向自動同期ではなく「パターン許容+片方向採択」**で行う:

1. **追加ファイルは非イベントになる**: 計画済みディレクトリ内で命名規則(allowRules)に合うファイルは、plan を触らずとも常に valid。フルパス列挙が不要になり、双方向メンテの主因が消える
2. **fs → plan は「明示的採択」のみ**: `plan adopt` が未計画 feature を検出し、追記すべき YAML 断片を提示 → 確認後に `yaml_edit` でコメント・書式を保持したまま挿入。自動書き込みはしない
3. **plan → fs は `apply` のみ**: check と同一モデルの裏返し。dry-run が既定

**v0.7 時点の後方互換読み取り**: `plan_repository` は `doc/specs/plan.yaml` が存在しない場合、旧 `AI/specs/feature_request.yaml` を読み取り専用でフォールバック解釈する(意図レベルへの最小変換をその場で行うのみで、ファイルは書き換えない)。これにより、唯一の実利用者である進行中の実案件が `doc/` レイアウト移行(v0.8 の `doctor --migrate`)を待たずに v0.7 の `check`/`apply` を採用できる(§17 未決事項参照)。

## 7. 記録系: お客様会話ログ・合意・サマリー(課題⑤)

### 7.1 会話ログ — `utakata log`

- **形式: JSONL(1メッセージ=1行)・月別ファイル** `doc/records/log/YYYY-MM.jsonl`。追記は O(1)、クラッシュ時に壊れるのは末尾1行だけ(検出・退避可能)、`dart:convert` がエスケープを保証(自作シリアライザ問題の根絶)、git diff が純粋
- **記録は人間・AI は読み取り専用**(P8)。書き込みコマンドは確認プレビュー付き
- スキーマ — **必須4+自動2、それ以外は任意**(記録が続くことを最優先):

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `id` | ✅(自動採番) | `MSG-YYYYMMDD-NNN` |
| `at` | ✅ | ISO 8601+TZ。`--at "6/30 17:41"` の年は「今日以前で最近の日付」に自動補完 |
| `speaker` | ✅ | `client` / `developer` / `system` / `third_party` |
| `body` | ✅ | 本文プレーンテキスト(複数行可・無加工。貼りたい生ログは丸ごと入れてよい) |
| `recorded_at` / `recorded_by` | ✅(自動) | 記録操作の監査情報 |
| `name` `kind` `thread` `tags` `reply_to` `attachments` `read_at` `sent_as` | 任意 | `kind` 既定 `message`。`--draft` で回答案(`kind: draft`)、送信時に `--sent` で `sent_as` 逆リンク |

```
utakata log add "本文..." -s client --at "6/30 17:41" --thread pdf_import --tag 要望
utakata log add -            # stdin から本文(コピペ最短経路)
utakata log add -i           # 対話モード
utakata log show [--date 2026-06-30 | --thread pdf_import | --tag 要望 | MSG-...]
utakata log render           # doc/preview/ に .md プレビュー再生成(自動生成ヘッダ+IDアンカー付き)
```

- 既存の生ログ(.md)は `doc/records/log/legacy/` に**凍結**(既存の行番号参照 `0630.md:L28` を生かす)。新規文書の出典参照は ID 形式のみ
- 失敗設計: 未来日時→エラー、`reply_to` 不在→エラー、完全重複→警告、末尾破損行→ `.corrupt` へ退避して案内

### 7.2 合意トラッキング — `utakata agree`

- **`doc/records/agreements.jsonl`・追記専用**。状態遷移(proposed→agreed 等)・訂正・反映記録もすべて「イベント行の追記」で表現し、現在状態は読み手が畳み込みで導出する(訂正も履歴ごと残す実案件慣習をデータ構造で強制)
- フィールド: `id`(`AGR-NNNN`) / `title` / `kind`(`client_agreement`・`internal_decision`・`tentative`・`correction`) / `status` / `amount {value, currency, payment_terms}` / `items[]` / `sources[]`(MSG ID またはファイルパス) / `corrects` / `reflected_in[]` / `backlog`
- **クライアント合意と内部決定の区別を第一級に**(実案件 §10 の最重要慣習)。契約前フェーズも同一モデル(初回契約=`AGR-0001`、出典に `doc/archive/見積もり提案書.md`)

```
utakata agree add --title "PDF取り込み追加" --kind client_agreement --amount 20000 --from MSG-20260630-001,MSG-20260702-014
  # --kind は client_agreement/internal_decision/tentative/correction の短縮形(client/internal/tentative/correction)も許容
utakata agree status AGR-0005 agreed --on 2026-07-02
utakata agree correct AGR-0002 --title "..."       # supersede(過去エントリは書き換えない)
utakata agree reflect AGR-0005 --plan PLAN-0007    # 実装計画への反映記録
utakata agree reflect AGR-0005 --spec F-15         # application_specification.md の機能項目への反映記録
utakata agree list [--unreflected]                 # plan/spec いずれにも反映されていない合意を検出(「合意の置き去り」を塞ぐ)
```

- AI の役割: 読み取り専用の立場から「この会話は合意化されていません。`utakata agree add --from MSG-... --title ...` を実行してください」と**コマンド行を提案するところまで**

### 7.3 案件整理サマリー — `utakata summary`

`doc/summary.md` の**マーカー区間だけ**を台帳から再生成し、手書き部分と共存する:

- `<!-- utakata:begin agreements -->` 〜 `<!-- utakata:end -->`: 合意ログ(§10 相当)を実案件と同じ見出し体裁で生成、出典は MSG ID+プレビューへのリンク
- 開発費区間: 基本契約+追加合意の金額を自動集計(**転記ミスの構造的排除**)
- 区間外(コンセプト等)は従来どおり手書き。`check --docs` がマーカー内の手編集を警告

### 7.4 ID・トレーサビリティ規約

- `MSG-YYYYMMDD-NNN` / `AGR-NNNN` / `PLAN-NNNN`。接頭辞が一意なので裸 ID 1トークンで相互参照できる(grep 可能)
- `spec:F-NN` — `doc/specs/application_specification.md` 内の機能項目番号(既存の F-1, F-2... 採番方式をそのまま出典参照に流用。CLI は採番せず、仕様書内の見出しをそのまま参照する)
- 採番はカウンタファイルを持たず「既存 ID の max+1」(単独運用前提。並行ブランチでの重複は `check` が検知する — 制約として明記)
- **下流が上流を参照する**(実装計画→合意→ログ)。逆リンク(`reflected_in`, `sent_as`)は CLI が付与
- ID は発行後不変。取り消しは status で表現(削除禁止)

## 8. feature 実装計画の強制(課題④)

- `impl new <feature>` → `doc/impl/PLAN-NNNN_<feature>.md` を実案件テンプレート(§1 背景〜§8 スコープ外)から生成。**frontmatter だけが機械可読**(本文は人間と AI の領域):

```yaml
---
id: PLAN-0007
feature: pdf_import
status: draft | in_progress | done | archived
origin: { agreements: [AGR-0005], specs: [F-15], messages: [MSG-20260630-001] }
basis: client_agreed | developer_judgment    # 実案件テンプレ§2「合意か当方判断か」の第一級化
verification: { static: pending, on_device: pending }
---
```

- **状態は4つ**(draft → in_progress → done → archived)。承認台帳・submit/approve 儀式は作らない(自己承認はゴム印にしかならない)
- **強制の設計(P7: 結節点でのみ止める)**:

| タイミング | 検査 | 失敗時 |
|-----------|------|--------|
| `feature add <name>`(ベースライン後) | 実装計画が存在するか | exit 1「先に `utakata impl new <name>` を実行」(`--no-plan` で明示スキップ・警告記録) |
| 初回 `apply`(一括 scaffold) | **免除**(`baseline: true` 自動付与) | — |
| `check` / CI | ①計画なし feature ②dangling ID 参照 | exit 1 |
| `impl done` | `check` 0件・`flutter analyze` 0件・`--verified`(実機確認は人間の宣言) | exit 1(未達項目を列挙) |
| フック(PostToolUse) | 警告注入のみ。**編集を deny しない** | — |

- 強制レベルは `utakata.yaml` の `enforcement.impl_plan: on(既定) | off`。`on` は「初期一括 scaffold(`baseline: true`)は免除、**中途追加 feature は計画書必須**」— 実案件で実装計画が発生したのは中途追加機能だったという実態に合わせる。3値目の `strict`(ベースライン feature にも要求)は、利用者が単独の現時点で使用実績がないため作らない(必要になったら追加)

## 9. ナレッジ2層と編集不要ファイルの保護(課題①②)

**保護方式は「配布しない=参照化」を採用する。** 別 git・submodule・読み取り専用属性・チェックサム台帳は全て不採用(保護対象をコピーしなければ、保護という問題そのものが消える)。

| 層 | 置き場所 | 扱い |
|----|---------|------|
| テンプレート由来(案件非依存) | utakata パッケージ内蔵 + `~/.utakata/`(ユーザー層: store/payment 等の個人資産) | **配布しない**。`guide list/show`・MCP `guide_get` で参照。カスタムしたい時だけ `guide eject` / `arch eject` |
| プロジェクト固有 | `doc/knowledge/` | 自由編集(保護不要) |

- 解決順は **project(`.utakata/overrides/`) → user(`~/.utakata/`) → package 内蔵**。現行のローカル優先読み込みの自然な拡張
- `eject` したファイルは**元 id・version をコメント1行に残す単純コピー**に留める(厳密な hash 照合・`.utakata/manifest.yaml` 台帳・`check --docs` による乖離検査は §15 棚上げリストの通り作らない。「配布しない」で課題①は既に解決しているため、自分のファイルを自分で監視する追加機構は見合わない)
- Claude Code の Grep 横断検索のために `.utakata/cache/knowledge/` へ実体化キャッシュを生成できる(`doctor --sync`。gitignore・再生成可能・P1 と矛盾しない)
- **効果: テンプレート展開は現行約106ファイル → 約15ファイル**(要編集: specs 2md + plan.yaml + utakata.yaml + summary.md + impl テンプレ の5ファイル。残りは `.claude/`(settings.json + スキル5 + エージェント2)+ `.mcp.json` で、これらは生成時に確認不要)。非推奨 `AI/scripts/*.sh` の同梱は v1.0 で終了(§14)
- 案件で得た知見のテンプレ側への還流(promote/sync/3-way マージ)は**作らない**。`~/.utakata/` に置けば優先解決される、という規約で十分(必要性が実証されたら追加)

## 10. feature プリセットテンプレート(課題⑦)

- `feature add auth --template auth`。テンプレートは `manifest.yaml`(plan 意図断片+依存パッケージ+ファイル群+関連ナレッジ参照)を持つディレクトリ
- 解決順: project → `~/.utakata/feature_templates/<id>/` → パッケージ内蔵
- 適用は **dry-run(衝突検査)→確認→単一トランザクション展開**。plan.yaml へ意図が `yaml_edit` で自動追記されるため**適用直後から check がクリーン**
- **v1.0 ではメカニズムのみ提供し、auth/payment のコンテンツは同梱しない**。プリセットの中身は次の実案件で同じ feature を2回書いてから、実証済みコードを元に作成する(仕組み先行でコンテンツ制作コストを未見積もりのまま抱えない)

## 11. Claude Code 統合(課題⑥)

### 11.1 生成物(`create` / 既存プロジェクトは `doctor --sync`)

```
project/
├── .mcp.json                  # { "utakata": { command: "utakata", args: ["mcp"] } }
└── .claude/
    ├── settings.json           # hooks(下表)+ permissions(doc/records/** への Edit/Write deny)
    ├── skills/
    │   ├── utakata-spec / utakata-structure / utakata-implement   # 旧 stage1-3 の薄い後継
    │   ├── utakata-feature-plan     # 実装計画書の書き方(§8 テンプレ準拠)
    │   └── utakata-client-context   # log/agree から要件根拠を引く手順
    └── agents/
        ├── structure-auditor.md     # check --json を読み違反修復を提案
        └── impl-planner.md          # 仕様+合意から実装計画書ドラフトを作成
```

- **スキルは薄く保つ**: 長文ガイドはスキルに複製せず `utakata guide show <id>` / MCP で都度取得(単一ソース原則のドキュメント版)。MCP 不通時のフォールバック(`utakata check --json` 等の Bash 経路)もスキルに明記
- `.agent/` は v0.9 まで併生成(非推奨ヘッダ付き)、v1.0 で生成停止

### 11.2 フック(遅延バジェット原則: 速い検査ほど早いフックに)

| イベント | 動作 | バジェット |
|----------|------|-----------|
| SessionStart | `utakata status --brief` を additionalContext 注入(check 概況・進行中計画・直近合意)。**`--brief` は flutter analyze・プロセス呼び出しを一切行わない**(スキャン+記録系読み取りのみ) | ~300ms(AOT バイナリ前提) |
| PreToolUse (Write/Edit) | **静的パス判定のみ**: `doc/records/**`・`doc/preview/**` → deny。**utakata を起動せず** `.claude/settings.json` の permissions ルール(シェル1行判定)で行う | <10ms(utakata 非起動) |
| PostToolUse (Write/Edit, `lib/**`) | `utakata check --quick --file <path> --json`(単一ファイル粒度、AOT バイナリ実行)。違反は理由+GUIDE 抜粋を返す | <100ms(AOT バイナリ前提。JIT/`pub run` 経由では未達) |
| Stop | `utakata status --write-report`(**analyze は含めない**。スキャン+記録系のみで `doc/preview/status.md` を更新)+ 未完了計画の**警告**(block はしない) | <2s |

- **AOT バイナリが未生成の環境**(`doctor --sync` 未実行、CI 初回等)では、フックは自動的に「スキップして警告メッセージのみ返す」フォールバックに落ちる(utakata 未インストール環境でエージェントが停止する障害モードを避ける)。
- 実装計画ゲートをフックで deny しない理由: 「1行だけ直して」の15分作業がブロックされるとフックごと無効化され、強制層全体が死ぬ。強制は CLI コマンドと check(CI)に置く(P7)。
- **analyze を含む完全な `status`(analyze 対象 `lib/ test/`)は手動実行専用**とし、フック経由では実行しない(§14 の性能要件参照)。

### 11.3 `utakata mcp`(v1.0)

stdio 起動・Claude Code がライフサイクル所有・**ステートレス**(ツール呼び出しごとに新規スキャン)。公開ツールは全て読み取り専用: `structure_get` / `check_run` / `plan_get` / `log_query` / `agreements_query` / `guide_get` / `impl_plan_status`。**書き込みツールは提供しない**(P8 の技術的強制)。

## 12. 生成プロジェクトの標準レイアウト

```
project/
├── utakata.yaml               # プロジェクト設定(architecture / parties / enforcement / records.git / lang)
├── doc/                       # 案件ワークスペース(旧 AI/ は廃止し統合)
│   ├── specs/                 # [要編集] application_specification.md, structure_plan.md, plan.yaml
│   ├── records/               # [機械管理・AI書込禁止・gitignore しない] log/YYYY-MM.jsonl, log/legacy/, log/attachments/, agreements.jsonl
│   ├── preview/                # [自動生成・gitignore] log_*.md, agreements.md, status.md。出典参照は MSG/AGR ID の裸表記(プレビューへのリンクは張らない。リモート閲覧での参照切れを避ける)
│   ├── summary.md             # [手書き+マーカー生成区間] 案件整理サマリー
│   ├── impl/                  # [要編集] PLAN-*.md, archive/, research/
│   ├── knowledge/             # [自由編集] プロジェクト固有ナレッジ
│   └── archive/               # [凍結] 契約前資料(見積もり提案書等)
├── .claude/  .mcp.json        # Claude Code 統合(§11)
├── .utakata/
│   ├── overrides/             # eject された定義(git 管理)
│   └── cache/ create_state.json   # (gitignore)
└── lib/ ...                   # Flutter 本体
```

- `doc/preview/` は**再生成可能な導出物のためgitignore**(P1)。`utakata log render`/`status --write-report` 等でいつでも復元できる。プレビュー生成のソート順は `at` 昇順、同時刻は `id` 昇順で決定的にする
- `.utakata/manifest.yaml` と `locks/` は不採用(前者は eject の単純コピー化(§9)により不要、後者は多重起動対策の必要な操作が現時点でないため。必要になれば追加する)

- 旧 `AI/logs/conversation_log.md`(開発者⇔AI 会話ログ)は生成テンプレートから**廃止**(実案件で未使用。Claude Code のセッション履歴と `doc/impl/research/` が代替)
- 旧レイアウト(AI/ ディレクトリ、feature_request.yaml、snapshots)からは `doctor --migrate` で一括移行

## 13. 非機能要件

| 項目 | 要件 |
|------|------|
| 終了コード | 0=成功 / 1=検証違反 / 2=実行時エラー / 64=usage(CI が「壊れた」と「違反」を区別できる) |
| 決定性 | 全出力はソート済み・同一入力で同一出力。`--json` は機械可読の第一級経路 |
| 性能 | `check` はプロジェクト1万ファイル規模で 200ms 以内(スキャン実測数十ms+余裕) |
| i18n | 新コマンドの文言も既存 `messages/`(ja/en)経由。`project_status` の日本語ハードコードは解消。ja を一次言語とし en はベストエフォート |
| テスト | 全ユースケースにユニットテスト必須(CI ゲート)。既知バグ(§5, 3件再現+2件対処済み)はゴールデン回帰ケースとして永続化。`doctor --migrate` にも移行テスト必須。**各版の受け入れ確認は `example/example_app`(テンプレート実物+実案件 doc/ コピー)上で実施**し、`doctor --migrate` は同ディレクトリの実案件 doc/ コピーで検証する |
| 後方互換 | 各スキーマに `schema: 1`。機能追加時の**凍結宣言は第三者利用者が現れてから**(利用者1名の段階で将来の自分に負債を固定しない)。ただし records(log/agree/impl frontmatter)は自分自身の実案件データが v0.8 から乗るため、schema 変更時に `doctor --migrate` が旧→新変換を提供することは v0.8 の受け入れ条件とする(凍結はしないが移行は保証する) |
| 配布 | Dart CLI(pub.dev)。`dart pub global activate` は VM(JIT)snapshot であり起動だけで100ms超かかる。フック用途では `doctor --sync` が `dart compile exe` でローカル AOT バイナリを生成し PATH に配置する(pub.dev 配布とは別経路)。この AOT バイナリが前提にない場合、§11.2 のフック遅延バジェットは満たされない |

## 14. ロードマップ(各段が単独で出荷可能)

現行コードベースは約53ファイル・4,620行・テスト1本。各段はこれと同程度以下の差分に収める(1版で現行全体を超える差分を積まない)。

| 版 | テーマ | 内容 |
|----|--------|------|
| **v0.6.0** | 負債返済(外部非互換なし) | ケース変換1実装化 / version.g.dart / catch(_) 全廃 / flutter 遅延解決 / analyze 対象限定 / status i18n / 未使用コード削除 / テスト基盤。**実際に再現する既知バグ3件**(`__files__` 誤認・feature名プレフィックス誤検知・`validate` の direct 未補償)を回帰テスト化してから修正。対処済みの2件(freezed/g 誤判定・exceptions/ 親規則適用)は回帰テスト追加のみ |
| **v0.7.0** | plan 意図レベル化+check/apply 統合 | 正準構造モデル / plan.yaml(schema:1、**旧 feature_request.yaml の読み取り専用フォールバック**で既存案件が移行を待たず利用可能) / check 統合(diff・validate はエイリアス) / apply 新設(feature init・core はエイリアス) / plan adopt / scan・旧 plan 廃止告知 / 自作 YAML シリアライザ削除 / create の冪等再実行(既存成果物スキップ) |
| **v0.8.0** | 記録系コア+doc/ レイアウト移行 | log add・show・render(**最小のヒューリスティック import を同梱** — legacy ログに触れる `doctor --migrate` の一部として) / doc init / utakata.yaml / **doc/ 新レイアウト+doctor --migrate**(実案件 doc/ 全構成物の移行を含む。構造計画書§6) / records の git 方針実装 |
| **v0.9.0** | 合意・実装計画・サマリー | agree 一式(enforcement は on/off の2値) / impl 一式 / summary(マーカー区間生成) |
| **v1.0.0** | 参照化と Claude Code | テンプレ展開の縮小 / guide list・show・eject / ナレッジ3層解決 / .claude/ 生成(スキル・エージェント・フック) / --template 機構 / .agent/ 非推奨化(AI/scripts 同梱終了もここで統一) |
| **v1.1.0** | AI 面の完成と安定化 | mcp(ステートレス stdio) / log import --file の完全版パーサ / 全エイリアス削除(`diff` を除く) / .agent/ 生成停止 / ドキュメント整備 |

順序の根拠: テストで固めた正準モデル(0.6)なしに plan 再定義(0.7)へ進むと相互補償バグを新実装に持ち越す。v0.7 は feature_request.yaml 互換読み取りにより既存案件がレイアウト移行なしで使い始められる(§6)。**トレードオフの明示**: v0.6/v0.7 はユーザー可視価値(お客様会話の構造化)を生まないリファクタであり、案件都合で v0.7 完了時点までしか進められなかった場合、記録系の恩恵は得られない。この順序は「相互補償バグを記録系の実装に持ち越さない」ことを優先した判断であり、中断リスクを許容できない場合は v0.6→v0.8(記録系)→v0.7(plan 意図化)の順に入れ替える選択肢もある(§17 論点)。

## 15. 意図的に作らないもの(棚上げリスト)

必要性が実証されるまで着手しない。「欲しくなったら足せる」構造(ステートレス・疎結合)を保つことが本仕様の投資である。

- 常駐監視デーモン / `utakata watch`(フォアグラウンド監視) — check の毎回スキャンで足りる(§3 で論証済み。手段不採用は §17 論点6で開発者の承認事項とする)
- `log import --clipboard`(チャット画面コピペパーサ) — stdin で足りる。外部 UI 変更に脆い
- `trace`(参照チェーン表示) — 数十件規模のデータは grep で追える
- `deliver`(納品ゲート) — 「コードに反映しようがない合意」で常時赤になる。チェックリスト生成のみ将来検討
- 承認台帳・ハッシュ照合・phase 状態機械 — 承認者=被承認者の単独運用では儀式にしかならない
- knowledge promote / sync / 3-way マージ / JSON Schema 評価器の自作
- eject の来歴ヘッダ厳密照合(hash+manifest による乖離検査) — 「配布しない」で課題①は既に解決済みであり、自分が eject した自分のファイルを監視する追加の儀式は見合わない。v1.0 の eject は「元 id・version をコメント1行に残すだけの単純コピー」に留める
- feature プリセットの同梱コンテンツ(auth/payment) — 実案件で2回書いてから
- スキーマ凍結宣言 / Windows CI / 新機能の i18n 完全対応 / studio 連携の具体設計
- 既存アプリへの導入(モード2/3) — v1.0 では新規 create 前提。v1.1 以降の主要テーマ候補

## 16. 課題トレーサビリティ

| 課題([現状と課題](current_state_and_issues.md)) | 本仕様の対応 |
|------|------|
| ① 編集する/しないファイルの区別 | §9 参照化(コピーしない)+eject+manifest |
| ② ナレッジとロジックの分離 | §9 2層+3層解決(project→user→package) |
| ③ スナップショットの弱さ / 監視サーバー | §3 設計回答+§5 正準モデル+§6 意図レベル化(scan 廃止) |
| ④ feature 実装計画の強制 | §8(additions_only 既定・検出ベース) |
| ⑤ お客様会話の構造化 | §7(JSONL+人間記録・AI 読み取り専用) |
| ⑥ Claude Code 前提の統合 | §11(スキル・エージェント・フック・MCP) |
| ⑦ feature プリセット | §10(機構のみ v0.9、コンテンツは実証後) |
| 3.2 テンプレートと実運用の乖離 | §7 契約前フェーズ・合意 / §12 doc/ 統合 / §11 .agent/ 廃止 |
| 3.3 既知バグ・技術的負債 | §5・§13・v0.6(全項目を織り込み) |

## 17. 未決事項(開発者の判断が必要)

| # | 論点 | 推奨案 |
|---|------|--------|
| 1 | **お客様会話ログを git に含めるか**(PII・秘匿性。全設計の前提) | 非公開リポジトリ前提で commit(バックアップ・履歴の利益)。`utakata.yaml` の `records.git: commit \| ignore` で案件ごとに選択可。public リモート検出時は `doctor`/`check` が警告 |
| 2 | 実装計画の強制既定 | `additions_only`(§8 の通り) |
| 3 | mcp の投入時期 | v1.0(それまで AI は `--json` を Bash で叩く。フォールバック経路が先に安定する) |
| 4 | 旧 `AI/logs/conversation_log.md` の扱い | 生成テンプレートから廃止(§12)。既存プロジェクトは doctor --migrate が `doc/impl/research/` へ移設 |
| 5 | en メッセージの投資度合い | 新機能は ja 先行・en は主要メッセージのみ(pub.dev 公開パッケージとしての体裁維持) |
| 6 | **監視サーバー構想(常時監視するローカルサーバー)の手段不採用**(§3) | §3 の論証(スキャンが数十msで常駐に見合わない)を承認するか。当初構想からの転換のため明示確認が必要 |
| 7 | **`doc init` のルート規約と `create` との合流手順** | doc init は案件ルートに utakata.yaml(project.app 未設定)を作り、create は同ディレクトリで `flutter create .` 相当を行う(§4)。v0.8 着手前に確定要 |
| 8 | **ロードマップの順序**(v0.7 の構造リファクタ先行 vs v0.8 の記録系先行) | 現行案は正準モデル確立を優先(§14 根拠欄)。案件都合で中断リスクを重視するなら記録系を先に持ってくる入れ替えも可 |
| 9 | records(log/agree/impl frontmatter)の schema バージョン変更時の移行保証 | 「後方互換の凍結宣言はしない」(§13)が、schema フィールドを持つ記録データは v0.8 から自分自身の実案件に乗る。`doctor --migrate` が schema 変更時の旧→新変換を必ず提供することを v0.8 の受け入れ条件とする(凍結はしないが移行は保証する、という中間の立場) |

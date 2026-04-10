# AI/ ディレクトリ構造の再設計

> ステータス: **Step 1-3 実装完了 → Step 4（スクリプトYAML対応）は architecture_data_format.md と合流**
> 前提: `TODO/instructions_and_scripts_refactor.md` Phase A・B 完了後
> 関連: `TODO/architecture_data_format.md`（YAML パイプラインはこの再設計の後に実装）

---

## 1. 決定事項

### 採用案: 案C（目的別ディレクトリ）

```
AI/
├── guides/           # AIが「ルールを確認する」ために読む — 静的リファレンス
│   ├── lib/          #   27個の *_guide.md（各層の実装ルール）
│   ├── directory_structure_and_naming_rules.md
│   ├── technology_stack.md
│   └── recommended_packages.md
│
├── specs/            # AIが「何を作るか」を確認・記載する — Stage成果物
│   ├── application_specification.md   # Stage 1 成果物
│   ├── structure_plan.md              # Stage 2 成果物
│   └── feature_request.yaml           # AI入力（Stage 2）
│
├── snapshots/        # スクリプトが「現状を記録する」ために書く — 全てYAML
│   ├── plan_architecture.yaml         # 計画上の構造（generate_plan.sh 生成）
│   ├── actual_architecture.yaml       # 実際の構造（snapshot.sh 生成）
│   ├── project_status.yaml            # プロジェクト状態 ← .md→.yaml変換
│   ├── change_history.yaml            # 変更履歴 ← .md→.yaml変換
│   ├── structure_violations.yaml      # 構造違反結果 ← .md→.yaml変換
│   └── preview/                       # 人間用プレビュー（YAMLから自動生成）
│       ├── plan_architecture.md       #   計画の可読版
│       ├── actual_architecture.md     #   実際の構造の可読版
│       ├── project_status.md          #   プロジェクト状態の可読版
│       ├── change_history.md          #   変更履歴の可読版
│       └── structure_violations.md    #   構造違反の可読版
│
├── logs/             # 会話記録（将来的に分割・JSON化を検討）
│   └── conversation_log.md
│
└── scripts/          # ツール（リファクタリング済み）
    ├── setup/
    ├── generate/
    ├── status/
    ├── validate/
    └── build/
```

### 設計原則

| ディレクトリ | 誰が | 何のために | フォーマット |
|-------------|------|-----------|------------|
| `guides/` | 人間/AI が読む | ルール・制約を確認 | .md（静的） |
| `specs/` | AI が書く | プロジェクトの仕様を定義 | .md + .yaml |
| `snapshots/` | スクリプトが書く | 現在の状態を記録 | .yaml（機械処理用） |
| `snapshots/preview/` | スクリプトが生成 | 人間が状態を確認 | .md（YAML→MD自動変換） |
| `logs/` | AI/ワークフローが書く | 会話の履歴を蓄積 | .md（将来JSON化検討） |
| `scripts/` | 人間/AI が実行 | 自動化ツール | .sh |

### YAML統一の狙い

1. **機械処理に最適**: `yq` で読み書き可能、スクリプト間で共通フォーマット
2. **SSOT**: YAML が正（Single Source of Truth）、preview/ の .md は参照用の派生物
3. **preview/ は自動生成**: `.gitignore` に含めるか、生成コマンドで即座に作り直せる
4. **差分検知が容易**: `diff plan_architecture.yaml actual_architecture.yaml` がそのまま使える

---

## 2. 旧構成 → 新構成の対応表

```
旧                                    →  新
──────────────────────────────────────────────────────────────
AI/architecture/                      →  AI/guides/
  lib/                                →    lib/（27個の *_guide.md）
  directory_structure_and_naming_rules.md → 維持
  technology_stack.md                  →    維持
  recommended_packages.md             →    維持

AI/document/                          →  AI/specs/
  application_specification.md        →    維持
  structure_plan.md                   →    維持
  current_structure.md                →  【廃止】actual_architecture.yaml に置換

AI/logs/                              →  分割
  project_status.md                   →  AI/snapshots/project_status.yaml（YAML化）
  change_history.md                   →  AI/snapshots/change_history.yaml（YAML化）
  structure_violations.md             →  AI/snapshots/structure_violations.yaml（YAML化）
  conversation_log.md                 →  AI/logs/conversation_log.md（維持）

（新規作成）
  AI/specs/feature_request.yaml       →  AI入力用テンプレート
  AI/snapshots/plan_architecture.yaml →  generate_plan.sh の出力
  AI/snapshots/actual_architecture.yaml → snapshot.sh の出力
  AI/snapshots/preview/*.md           →  YAMLからの自動生成プレビュー
```

---

## 3. YAML化するファイルの設計メモ

### project_status.yaml

現在の `project_status.md`（174行）は大半がテンプレート。YAML化で本質的なデータのみ保持する。

```yaml
# project_status.yaml（イメージ）
project:
  name: ""
  mode: null  # 1 | 2 | 3
  started_at: null
  last_worked_at: null

stage:
  current: null  # stage1 | stage2 | stage3
  stage1: { status: "not_started" }
  stage2: { status: "not_started" }
  stage3: { status: "not_started" }

flutter:
  pubspec_exists: false
  lib_exists: false
  initialized: false

core:
  routing: false
  theme: false
  api: false
  env: false
  database: false
  exceptions: false

entry_points:
  main_dart: false
  app_dart: false

documents:
  specification: "not_created"  # not_created | template_only | created
  structure_plan: "not_created"

features:
  count: 0

updated_at: "2026-04-10T15:00:00+09:00"
updated_by: "update_status.sh"
```

### structure_violations.yaml

現在のファイルはルール定義のコピー（L11-92）が含まれ冗長。違反結果のみに簡素化する。

```yaml
# structure_violations.yaml（イメージ）
last_checked: "2026-04-10T15:00:00+09:00"
violation_count: 0
violations: []
  # - path: "lib/features/user/memo/wrong_dir/"
  #   type: "invalid_directory"
  #   message: "許可されていないディレクトリ"
  #   suggestion: "1_domain/ 配下に配置してください"
```

### change_history.yaml

```yaml
# change_history.yaml（イメージ）
last_detected: null
summary:
  total: 0
  created: 0
  modified: 0
  deleted: 0
  directories_created: 0
changes: []
  # - timestamp: "2026-04-10T15:00:00+09:00"
  #   type: "created"
  #   path: "lib/features/user/memo/1_domain/1_entities/memo_entity.dart"
```

### preview/ の生成

各YAMLファイルを読み、人間が読みやすい Markdown テーブルやツリーに変換するスクリプト。

```bash
# preview 生成コマンド（将来の generate_preview.sh）
yq '.violations[]' snapshots/structure_violations.yaml | ...  → preview/structure_violations.md
yq '.structure' snapshots/plan_architecture.yaml | ...         → preview/plan_architecture.md
```

---

## 4. conversation_log.md の将来方針

### 当面
- `AI/logs/conversation_log.md` として現状維持

### 将来検討（優先度: 低）

| 案 | 方法 | 採用判断 |
|----|------|---------|
| **JSON分割** | `AI/logs/conversations/{date}_{id}.json` | 蓄積量が問題になったら |
| **サマリーMD** | JSON から自動生成する `conversation_summary.md` | JSON化と同時に |
| **外部委託** | Antigravity 等の外部ツールに任せ自前廃止 | テンプレートの自己完結性と要相談 |

→ 現時点では方針だけ記録し、実装は膨らんでからで良い

---

## 5. 実装手順

### Step 1: guides/ リネーム ✅
- [x] `AI/architecture/` → `AI/guides/` に `git mv`
- [x] 全参照パスの更新（53箇所、14ファイル）
- [x] 検証: 旧パス残存なし確認済み

### Step 2: specs/ リネーム ✅
- [x] `AI/document/` → `AI/specs/` に `git mv`
- [x] `current_structure.md` を削除
- [x] 全参照パスの更新（19ファイル）
- [x] 検証: 旧パス残存なし確認済み

### Step 3: snapshots/ 新設 + logs/ 分割 ✅
- [x] `AI/snapshots/` ディレクトリ作成
- [x] `AI/snapshots/preview/` ディレクトリ作成
- [x] `project_status.yaml` 作成（YAML化）
- [x] `change_history.yaml` 作成（YAML化）
- [x] `structure_violations.yaml` 作成（YAML化）
- [x] 旧 .md ファイル削除（`git rm -f`）
- [x] `AI/logs/` には `conversation_log.md` のみ残存
- [x] 全参照パスの更新
- [x] README.md のツリー構造・テーブル更新
- [x] 検証: 旧パス残存なし確認済み

### Step 4: スクリプトの YAML 出力対応 ✅
- [x] `update_status.sh`: 全面書き換え → `project_status.yaml` + `preview/project_status.md`
- [x] `detect_changes.sh`: 全面書き換え → `change_history.yaml` + `preview/change_history.md`
- [x] `validate_structure.sh`: 出力部分書き換え → `structure_violations.yaml` + `preview/structure_violations.md`
- [x] `snapshot.sh`: 全面書き換え → `actual_architecture.yaml` + `preview/actual_architecture.md`
- [x] 各スクリプトに preview/ への .md 出力機能を追加
- [x] bash 3.x 互換性修正（validate_structure.sh の declare -A を除去）

### Step 5: 検証 ✅
- [x] 全スクリプトの動作確認
- [x] preview/ が正しく生成されることを確認（YAML + MD のペア 4組）
- [x] lib/ 未存在時の空レポート生成を確認

---

## 6. 制約・注意事項

- `architecture/` → `guides/` は参照箇所が最多（guide内の相対パス、27個のファイル間リンク）
- Step 1-3 のリネームを先に完了し、Step 4 のスクリプト書き換えは別作業にする
- `yq` が必要（`brew install yq` 済み）
- preview/ は `.gitignore` に入れて再生成前提にするか、git管理するか要決定

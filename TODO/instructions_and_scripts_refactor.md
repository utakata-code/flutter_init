# AI/instructions 削除 & AI/scripts リファクタリング計画

> ステータス: **未実施**
> 前提: `TODO/repository_restructure.md` Phase 1〜3 完了後

---

## Phase A: AI/instructions/ の削除とモード2・3のTODO化

### 背景
`AI/instructions/existing_app/` は既存アプリ開発モード（モード2・3）用の手順書だが、現時点では新規アプリ開発（モード1）に集中するため、一旦TODOとして保留する。

### 削除対象

```
AI/instructions/                         # ディレクトリごと削除
├── existing_app/
│   ├── with_rules/                      # モード2: 4ファイル
│   │   ├── index.md
│   │   ├── feature_update.md
│   │   ├── reverse_generate.md
│   │   └── validation.md
│   └── without_rules/                   # モード3: 4ファイル
│       ├── index.md
│       ├── migration_guide.md
│       ├── refactor_plan.md
│       └── validation.md
```

### 参照更新が必要なファイル

| ファイル | 変更内容 |
|---------|---------|
| `.agent/rules/flutter.md` | モード2・3 の参照パスを「TODO（未実装）」に変更 |
| `.agent/skills/flutter-development-guide/SKILL.md` | モード2・3 を「TODO（未実装）」に変更 |
| `.agent/skills/flutter-development-guide/resources/mode_selection.md` | 既存アプリ参照パスを削除、`new_app/` の古い残骸も整理 |
| `README.md` | モード2・3 を「TODO（将来実装予定）」と明記 |

### 実施手順

- [ ] `AI/instructions/` を削除
- [ ] `.agent/rules/flutter.md` を更新（モード2・3 → TODO表記）
- [ ] `.agent/skills/flutter-development-guide/SKILL.md` を更新
- [ ] `.agent/skills/flutter-development-guide/resources/mode_selection.md` を更新（古い残骸も整理）
- [ ] `README.md` を更新
- [ ] `TODO/repository_restructure.md` に「既存アプリモードは将来TODO」を追記

---

## Phase B: AI/scripts/ のリファクタリング

### 背景
現在11本のスクリプトが `AI/scripts/bash/` にフラットに配置されており：
- `status.sh`（481行）が4つの無関係なコマンドを1ファイルに混載
- 初期化・生成・検証・ビルドの分類がなく見通しが悪い
- `bash/` のみなので中間ディレクトリが無意味

### 現状 → 新構成の対応表

```
現在                              →  新構成
─────────────────────────────────────────────────────────────
AI/scripts/bash/                  →  AI/scripts/

  init_project.sh                 →  setup/init_project.sh
  add_dependencies.sh             →  setup/add_dependencies.sh

  generate_core.sh                →  generate/generate_core.sh
  generate_feature.sh             →  generate/generate_feature.sh
  generate_native.sh              →  generate/generate_native.sh
  init_core_exceptions.sh         →  generate/init_core_exceptions.sh

  status.sh (481行)               →  status/check_status.sh    (cmd_check 部分)
                                  →  status/update_status.sh   (cmd_update 部分)
                                  →  status/snapshot.sh        (cmd_snapshot 部分)
  detect_changes.sh               →  status/detect_changes.sh

  validate_structure.sh           →  validate/validate_structure.sh
  find_unused_files.sh            →  validate/find_unused_files.sh

  build_native_ios.sh             →  build/build_native_ios.sh
```

### 新構成

```
AI/scripts/
├── setup/                         # プロジェクト初期化
│   ├── init_project.sh            #   flutter create + 初期セットアップ
│   └── add_dependencies.sh        #   pubspec.yaml に依存追加
│
├── generate/                      # コード生成
│   ├── generate_core.sh           #   lib/core/ 基盤生成
│   ├── generate_feature.sh        #   フィーチャーディレクトリ生成
│   ├── generate_native.sh         #   ネイティブプラットフォーム関連
│   └── init_core_exceptions.sh    #   例外クラス生成
│   # 将来追加: generate_plan.sh   #   feature_request.yaml → plan_architecture.yaml
│
├── status/                        # ステータス管理
│   ├── check_status.sh            #   プロジェクト状態チェック（表示のみ）
│   ├── update_status.sh           #   project_status.md 更新
│   ├── snapshot.sh                #   current_structure.md スナップショット生成
│   └── detect_changes.sh          #   変更検出 → change_history.md
│   # 将来追加: snapshot --format yaml 対応
│
├── validate/                      # 品質検証
│   ├── validate_structure.sh      #   ディレクトリ構造検証
│   └── find_unused_files.sh       #   未使用ファイル検出
│   # 将来追加: validate_plan.sh   #   plan_architecture.yaml バリデーション
│
└── build/                         # ビルド
    └── build_native_ios.sh        #   iOSネイティブビルド
```

### status.sh の分割方針

現在の `status.sh`（481行）内の4つのコマンドを独立スクリプトに分割する。

| 現在 | 行範囲 | 分割先 | 共有部分 |
|------|--------|--------|---------|
| `cmd_check` | L105-229 | `check_status.sh` | 共通関数（L60-99）を各ファイルに含める |
| `cmd_update` | L235-328 | `update_status.sh` | 同上 |
| `cmd_snapshot` | L334-424 | `snapshot.sh` | 独立（共通関数不要） |
| `cmd_report` | L430-455 | 削除 → workflowで3スクリプトを順次呼び出し |

**`report` コマンドの扱い**: `cmd_report` は check + update + snapshot を呼ぶだけなので、workflow（`/status_report`）で3スクリプトを順次呼び出す形に変更。スクリプト側に `report` サブコマンドは不要。

### 共通関数の扱い

`check_exists`, `check_dir_with_msg`, `check_file_with_msg`, `get_document_status` の4関数は `check_status.sh` と `update_status.sh` の両方で使用されている。

**方針**: 各ファイルに直接コピーする（11行程度の関数なので、共通ライブラリまで作る必要はない）

### 参照更新が必要なファイル

| ファイル | 現在のパス | 新パスへの更新 |
|---------|----------|--------------|
| `.agent/workflows/check_status.md` | `AI/scripts/bash/status.sh check` | `AI/scripts/status/check_status.sh` |
| `.agent/workflows/update_status.md` | `AI/scripts/bash/status.sh update` | `AI/scripts/status/update_status.sh` |
| `.agent/workflows/generate_structure_snapshot.md` | `AI/scripts/bash/status.sh snapshot` | `AI/scripts/status/snapshot.sh` |
| `.agent/workflows/status_report.md` | `AI/scripts/bash/status.sh report` | 3スクリプトの順次実行に変更 |
| `.agent/workflows/validate_structure.md` | `AI/scripts/bash/validate_structure.sh` | `AI/scripts/validate/validate_structure.sh` |
| `.agent/workflows/detect_changes.md` | `AI/scripts/bash/detect_changes.sh` | `AI/scripts/status/detect_changes.sh` |
| `.agent/workflows/flutter_analyze.md` | 変更なし（`flutter analyze` 直接呼び出し） |
| `.agent/workflows/log_conversation.md` | 確認必要 |
| `README.md` | 全スクリプトパス更新 |
| `.agent/skills/flutter-stage3-implementation/SKILL.md` | 初期化コマンドのパス更新 |
| `AI/logs/project_status.md` | 参考コマンド欄のパス更新 |
| `AI/logs/change_history.md` | 変更検出コマンドのパス更新 |
| `AI/document/current_structure.md` | 生成コマンドのパス更新 |

### 各スクリプト内の相互参照

```bash
# 確認が必要な内部参照パターン
status.sh  → PROJECT_ROOT を基準に STATUS_FILE, STRUCTURE_FILE を参照
detect_changes.sh → PROJECT_ROOT/AI/logs/change_history.md を参照
validate_structure.sh → PROJECT_ROOT/AI/logs/structure_violations.md を参照
```

→ `SCRIPT_DIR` から `PROJECT_ROOT` を算出するロジックは、ディレクトリ階層が変わるため全スクリプトで更新が必要：
- 現在: `PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"` （bash/ → scripts/ → AI/ → root）
- 新:  `PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"` ではなく、 `PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"` （status/ → scripts/ → AI/ → root）

→ 階層数は同じ（3段上がる）なので `PROJECT_ROOT` の算出ロジックは変更不要。

### 実施手順

#### B-1: status.sh の分割
- [ ] `AI/scripts/status/check_status.sh` を作成（cmd_check + 共通関数）
- [ ] `AI/scripts/status/update_status.sh` を作成（cmd_update + 共通関数）
- [ ] `AI/scripts/status/snapshot.sh` を作成（cmd_snapshot）
- [ ] 各ファイルに実行権限を付与

#### B-2: 既存スクリプトの移動
- [ ] `AI/scripts/bash/` から各サブディレクトリへ `git mv`
  - `init_project.sh`, `add_dependencies.sh` → `setup/`
  - `generate_core.sh`, `generate_feature.sh`, `generate_native.sh`, `init_core_exceptions.sh` → `generate/`
  - `detect_changes.sh` → `status/`
  - `validate_structure.sh`, `find_unused_files.sh` → `validate/`
  - `build_native_ios.sh` → `build/`
- [ ] `AI/scripts/bash/status.sh` を削除
- [ ] `AI/scripts/bash/` ディレクトリを削除（.keep があれば一緒に）

#### B-3: 参照の一括更新
- [ ] `.agent/workflows/` の全ファイル（7ファイル）
- [ ] `README.md`
- [ ] `.agent/skills/flutter-stage3-implementation/SKILL.md`
- [ ] `AI/logs/project_status.md`
- [ ] `AI/logs/change_history.md`
- [ ] `AI/document/current_structure.md`

#### B-4: 検証
- [ ] 全スクリプトが正しいパスから実行可能か確認
- [ ] `SCRIPT_DIR` / `PROJECT_ROOT` の算出が正しいか確認
- [ ] workflows のスラッシュコマンドが動作するか確認

---

## architecture_data_format.md との接続

Phase B 完了後、`TODO/architecture_data_format.md` で計画している以下のスクリプトが自然に配置できるようになる：

| 新規スクリプト | 配置先 | 役割 |
|-------------|-------|------|
| `generate_plan.sh` | `AI/scripts/generate/` | feature_request.yaml → plan_architecture.yaml 変換 |
| `validate_plan.sh` | `AI/scripts/validate/` | plan_architecture.yaml のバリデーション |
| `snapshot.sh --format yaml` 拡張 | `AI/scripts/status/` | actual_architecture.yaml 出力 |
| `diff_plan_actual.sh` | `AI/scripts/validate/` | plan vs actual 差分検知 |

---

## 実施順序

1. **Phase A**（AI/instructions/ 削除）を先に実施 — 影響範囲が狭く単純
2. **Phase B**（AI/scripts/ リファクタリング）を実施 — 参照更新が多いため慎重に
3. Phase B 完了後 → `TODO/architecture_data_format.md` Phase 4 へ移行可能

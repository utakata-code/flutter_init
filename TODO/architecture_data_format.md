# 構造計画の統一データフォーマット化計画

> ステータス: **実装準備完了 → Step A から着手可能**
> 前提完了: `TODO/ai_directory_restructure.md` Step 1-3、`yq` インストール済み

プロジェクトのディレクトリ構造の計画（Stage 2）において、AIによるフォーマット揺れやルール違反を仕組みレベルで完全に排除し、厳密なデータファイル（YAML）として管理するためのアーキテクチャ案です。

## 1. 決定事項

1. **データ形式**: **YAML** を使用する。
2. **ファイル配置**:
   - `AI/specs/feature_request.yaml`: AI入力（フィーチャー要件定義）
   - `AI/snapshots/plan_architecture.yaml`: 計画上のディレクトリ構造（自動生成）
   - `AI/snapshots/actual_architecture.yaml`: 現在の実際のディレクトリ状況（自動生成）
3. **ツール**: `yq` v4.52+ を使用（`brew install yq` 済み）

---

## 2. 全体像: AIが直接YAMLを書かないパイプライン

```
┌─────────────────────────────────────────────────────────────────┐
│  AI の役割: 「何を作りたいか」だけを書く                            │
│  ───────────────────────────────────────────────────────────── │
│  feature_request.yaml （AI書き込み用の最小入力ファイル）             │
│    → フィーチャー名、権限、必要なレイヤー、ファイル概要のみ          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  generate_plan.sh （変換スクリプト）                                │
│  ───────────────────────────────────────────────────────────── │
│  1. feature_request.yaml を読み込む                               │
│  2. AI/guides/directory_structure_and_naming_rules.md のルールに   │
│     基づき完全なディレクトリツリーを「機械的に」展開する              │
│  3. 命名規則バリデーション（validate_structure.sh と同等のロジック）   │
│  4. 違反があれば → エラーログを出力し、AIにフィードバック            │
│  5. 違反なければ → plan_architecture.yaml を生成                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  plan_architecture.yaml （自動生成される最終成果物）                │
│  ───────────────────────────────────────────────────────────── │
│  全フィーチャーの4層構造を網羅した完全なYAML                       │
│  → ビューアで可視化 / actual_architecture.yaml との差分検知        │
└─────────────────────────────────────────────────────────────────┘
```

### ポイント: AIが触るのは `feature_request.yaml` だけ

AIが自由に書くのは「フィーチャーの要件要約」だけであり、ディレクトリの階層展開・命名規則の適用は全てスクリプトが担当する。これにより:
- AIがルールを「覚える」必要がなくなる（ルールはスクリプトにハードコード）
- YAMLのインデントや階層を崩すリスクがゼロになる
- `AI/guides/directory_structure_and_naming_rules.md` の内容変更がスクリプト1箇所の修正で全体に反映される

---

## 3. feature_request.yaml の設計（AIの入力フォーマット）

AIが書くべき最小限の情報のみを含むファイル。配置先: `AI/specs/feature_request.yaml`

```yaml
# AI/specs/feature_request.yaml
# AI書き込み用 — フィーチャーの要件定義のみを記載する
# AI/scripts/generate/generate_plan.sh に渡すと AI/snapshots/plan_architecture.yaml が生成される

project:
  name: "my_app"
  version: "1.0.0"

features:
  # ── メモ機能 ──
  - name: memo                    # フィーチャー名（snake_case）
    permission: user              # admin / user / shared / direct
    description: "メモの作成・編集・削除・一覧表示"
    entities:
      - memo                      # → memo_entity.dart が生成される
    usecases:
      - get_memo                  # → get_memo_usecase.dart
      - create_memo               # → create_memo_usecase.dart
      - update_memo
      - delete_memo
    data_sources:
      local: true                 # 1_local/ を生成するか
      remote: false               # 2_remote/ を生成するか
    pages:
      - memo_list                 # → memo_list_page.dart
      - memo_detail               # → memo_detail_page.dart
    widgets:
      atoms:
        - memo_status_badge       # → memo_status_badge_atom.dart
      molecules:
        - memo_card               # → memo_card_molecule.dart
      organisms:
        - memo_list               # → memo_list_organism.dart

  # ── 認証機能 ──
  - name: auth
    permission: shared
    description: "ログイン・ログアウト・セッション管理"
    entities:
      - user
    usecases:
      - login
      - logout
    data_sources:
      local: true
      remote: true
    pages:
      - login
    widgets:
      atoms: []
      molecules:
        - login_form
      organisms: []

# ── Core層の追加設定（オプション） ──
core:
  routing:
    files:
      - app_router               # → app_router.dart
    paths:
      - memo_paths               # → memo_paths.dart
      - auth_paths               # → auth_paths.dart
  theme:
    files:
      - app_theme
  database:
    tables:
      - memos                    # → memos_table.dart
      - users                    # → users_table.dart
```

### 設計の意図

| 項目 | AIが書くもの | スクリプトが展開するもの |
|------|------------|----------------------|
| `entities: [memo]` | 名前だけ | `1_domain/1_entities/memo_entity.dart` のパス・サフィックス |
| `usecases: [get_memo]` | 動詞_名詞 | `1_domain/3_usecases/get_memo_usecase.dart` |
| `pages: [memo_list]` | ページ名 | `4_presentation/2_pages/memo_list_page.dart` |
| `widgets.atoms: [memo_status_badge]` | コンポーネント名 | `4_presentation/1_widgets/1_atoms/memo_status_badge_atom.dart` |
| `data_sources.local: true` | bool | `2_infrastructure/2_data_sources/1_local/memo_local_data_source.dart` |
| `permission: user` | 文字列 | `lib/features/user/memo/...` のパス構造 |

→ **AIは名前と要/不要の判断だけを行い、ルールに基づくパス生成は一切しない。**

---

## 4. plan_architecture.yaml の出力イメージ（生成される成果物）

`AI/scripts/generate/generate_plan.sh` が自動生成する最終フォーマット。配置先: `AI/snapshots/plan_architecture.yaml`

```yaml
# AI/snapshots/plan_architecture.yaml
# 自動生成 — 手動編集しないでください
# 生成元: AI/specs/feature_request.yaml
# 生成日時: 2026-04-10T13:30:00+09:00

project:
  name: "my_app"
  version: "1.0.0"

structure:
  lib:
    main.dart:
      description: "アプリケーションのエントリポイント"
    app.dart:
      description: "最上位ウィジェット（MaterialApp）"

    core:
      routing:
        app_router.dart:
          description: "GoRouterによる画面遷移定義"
        path:
          memo_paths.dart:
            description: "メモ機能のパス定義"
          auth_paths.dart:
            description: "認証機能のパス定義"
      theme:
        app_theme.dart:
          description: "アプリケーションテーマ"
      database:
        database.dart:
          description: "データベース接続設定"
        table:
          memos_table.dart:
            description: "memosテーブル定義"
          users_table.dart:
            description: "usersテーブル定義"

    features:
      user:
        memo:
          _meta:
            description: "メモの作成・編集・削除・一覧表示"
            permission: user
          1_domain:
            1_entities:
              memo_entity.dart:
                description: "メモエンティティ（@freezed）"
            2_repositories:
              memo_repository.dart:
                description: "メモリポジトリインターフェース"
            3_usecases:
              get_memo_usecase.dart:
                description: "メモ取得ユースケース"
              create_memo_usecase.dart:
                description: "メモ作成ユースケース"
              update_memo_usecase.dart:
                description: "メモ更新ユースケース"
              delete_memo_usecase.dart:
                description: "メモ削除ユースケース"
          2_infrastructure:
            1_models:
              memo_model.dart:
                description: "メモDriftモデル"
            2_data_sources:
              1_local:
                memo_local_data_source.dart:
                  description: "メモローカルデータソース"
            3_repositories:
              memo_repository_impl.dart:
                description: "メモリポジトリ実装"
          3_application:
            1_states:
              memo_state.dart:
                description: "メモ状態クラス（@freezed）"
            2_providers:
              memo_providers.dart:
                description: "メモDIプロバイダー"
            3_notifiers:
              memo_notifier.dart:
                description: "メモNotifier（@riverpod）"
          4_presentation:
            1_widgets:
              1_atoms:
                memo_status_badge_atom.dart:
                  description: "メモステータスバッジ"
              2_molecules:
                memo_card_molecule.dart:
                  description: "メモカードコンポーネント"
              3_organisms:
                memo_list_organism.dart:
                  description: "メモ一覧コンポーネント"
            2_pages:
              memo_list_page.dart:
                description: "メモ一覧ページ"
              memo_detail_page.dart:
                description: "メモ詳細ページ"
```

---

## 5. generate_plan.sh の処理フロー（詳細）

```
入力: feature_request.yaml
 │
 ├─ Step 1: YAML パース
 │   yq（軽量YAMLプロセッサ）で feature_request.yaml を読み込む
 │
 ├─ Step 2: バリデーション（入力の検証）
 │   ├─ permission が admin/user/shared/direct のいずれかか
 │   ├─ name が snake_case か
 │   ├─ entities / usecases の名前が snake_case か
 │   ├─ pages / widgets の名前が snake_case か
 │   └─ 違反があれば → エラーログ出力 + 終了（YAMLは生成しない）
 │
 ├─ Step 3: ディレクトリツリーの展開
 │   feature_request の各フィーチャーに対して:
 │     features/{permission}/{name}/
 │       ├─ 1_domain/
 │       │   ├─ 1_entities/{entity}_entity.dart     ← entities[] から
 │       │   ├─ 2_repositories/{entity}_repository.dart  ← entities[] から自動導出
 │       │   ├─ 3_usecases/{usecase}_usecase.dart   ← usecases[] から
 │       │   └─ exceptions/                          ← 常に生成
 │       ├─ 2_infrastructure/
 │       │   ├─ 1_models/{entity}_model.dart        ← entities[] から自動導出
 │       │   ├─ 2_data_sources/
 │       │   │   ├─ 1_local/{entity}_local_data_source.dart  ← local: true の場合
 │       │   │   └─ 2_remote/{entity}_remote_data_source.dart ← remote: true の場合
 │       │   └─ 3_repositories/{entity}_repository_impl.dart ← entities[] から自動導出
 │       ├─ 3_application/
 │       │   ├─ 1_states/{entity}_state.dart        ← entities[] から自動導出
 │       │   ├─ 2_providers/{entity}_providers.dart  ← entities[] から自動導出
 │       │   └─ 3_notifiers/{entity}_notifier.dart   ← entities[] から自動導出
 │       └─ 4_presentation/
 │           ├─ 1_widgets/
 │           │   ├─ 1_atoms/{name}_atom.dart         ← widgets.atoms[] から
 │           │   ├─ 2_molecules/{name}_molecule.dart  ← widgets.molecules[] から
 │           │   └─ 3_organisms/{name}_organism.dart  ← widgets.organisms[] から
 │           └─ 2_pages/{name}_page.dart              ← pages[] から
 │
 ├─ Step 4: 最終バリデーション（validate_structure.sh と同じロジック）
 │   生成YAMLの全パスを走査し、命名規則・ディレクトリ構成を再チェック
 │
 └─ Step 5: 出力
     → plan_architecture.yaml を書き出し
```

### 自動導出のルール（重要）

AIが `entities: [memo]` と書くだけで、以下が**全て機械的に**決まる：

**Domain / Infrastructure 層: entity 名から導出**

| 自動導出されるファイル | 導出元 | ルール |
|---|---|---|
| `memo_entity.dart` | entities[] | `{entity}_entity.dart` |
| `memo_repository.dart` | entities[] | `{entity}_repository.dart` |
| `memo_model.dart` | entities[] | `{entity}_model.dart` |
| `memo_local_data_source.dart` | entities[] + local:true | `{entity}_local_data_source.dart` |
| `memo_repository_impl.dart` | entities[] | `{entity}_repository_impl.dart` |

**Application 層: feature 名から導出**

| 自動導出されるファイル | 導出元 | ルール |
|---|---|---|
| `memo_state.dart` | feature.name | `{feature}_state.dart` |
| `memo_providers.dart` | feature.name | `{feature}_providers.dart` |
| `memo_notifier.dart` | feature.name | `{feature}_notifier.dart` |

→ **Entity名から5ファイル、Feature名から3ファイルが導出される。** AIが覚えるルールはゼロ。

> **注意**: `auth` フィーチャーに entity `user` がある場合:
> - Domain: `user_entity.dart` / `user_repository.dart`（entity名ベース）
> - Application: `auth_state.dart` / `auth_notifier.dart`（feature名ベース）

---

## 6. actual_architecture.yaml — 計画との差分検知

`plan_architecture.yaml`（計画）と対になるファイル。`lib/` を走査して現在の実際の構造を同じ YAML フォーマットで記録する。

両者を比較することで：
- 📋 **計画にあるが実装されていないファイル** → 未実装の検出
- ⚠️ **計画にないが存在するファイル** → 無計画なファイルの検出
- ✅ **一致しているファイル** → 実装完了の確認

実装詳細は §8 Step C を参照。

---

## 7. validate_structure.sh との関係

| 検証の種類 | 担当 | タイミング |
|---|---|---|
| **計画の検証**（feature_request → plan_architecture） | `AI/scripts/generate/generate_plan.sh` 内のバリデーション | 計画生成時（Stage 2） |
| **実装の検証**（実際の lib/ がルールに準拠しているか） | `AI/scripts/validate/validate_structure.sh`（既存） | 実装中・実装後（Stage 3） |
| **計画 vs 実装の差分** | `diff plan vs actual`（新規） | 実装中 – 進捗確認として |

→ `validate_structure.sh` は「実在するファイルの検証」、`generate_plan.sh` は「計画段階の検証」と役割が分離してきれいに共存する。将来的にバリデーションロジックを共通の関数/ファイルに切り出して両方から参照する形にもできる。

---

## 8. 実装ロードマップ

> 前提完了: `yq` インストール済み、`AI/snapshots/` + `AI/snapshots/preview/` 作成済み

### 統一方針: 全スクリプトが YAML + preview MD を同時出力

各スクリプトは以下の2ファイルを**常にセットで**生成する：

```
出力パターン:
  AI/snapshots/{name}.yaml         ← SSOT（yq で読み書き可能）
  AI/snapshots/preview/{name}.md   ← 人間用（YAML から自動変換）
```

---

### Step A: feature_request.yaml テンプレート作成 ✅
- [x] `AI/specs/feature_request.yaml` のテンプレートを作成
- [x] 必須フィールド / オプションフィールドの定義・ドキュメント化

### Step B: generate_plan.sh 新規作成 ✅
- [x] `AI/scripts/generate/generate_plan.sh` を新規作成
- [x] 入力: `AI/specs/feature_request.yaml`
- [x] 出力:
  - `AI/snapshots/plan_architecture.yaml`（YAML）
  - `AI/snapshots/preview/plan_architecture.md`（MD）
- [x] `yq` で入力パース → 命名規則バリデーション → ツリー展開 → 出力
- [x] `AI/guides/directory_structure_and_naming_rules.md` のルールをエンコード
- [x] 動作確認: サンプルデータで YAML + MD 正常生成

### Step C: snapshot.sh 書き換え ✅
- [x] `AI/scripts/status/snapshot.sh` を全面書き換え
- [x] 出力:
  - `AI/snapshots/actual_architecture.yaml`（YAML）
  - `AI/snapshots/preview/actual_architecture.md`（MD）
- [x] 旧 `current_structure.md` 出力コードを完全に削除
- [x] lib/ 未存在時の空スナップショット対応
- [x] 動作確認: 空リポジトリで正常生成

### Step D: update_status.sh 書き換え ✅
- [x] `AI/scripts/status/update_status.sh` を全面書き換え
- [x] 出力:
  - `AI/snapshots/project_status.yaml`（YAML）
  - `AI/snapshots/preview/project_status.md`（MD）
- [x] 旧 `project_status.md` への sed 書き換えロジックを完全に削除
- [x] 動作確認: 正常生成

### Step E: detect_changes.sh 書き換え ✅
- [x] `AI/scripts/status/detect_changes.sh` を全面書き換え
- [x] 出力:
  - `AI/snapshots/change_history.yaml`（YAML）
  - `AI/snapshots/preview/change_history.md`（MD）
- [x] 動作確認: Git変更検出 + YAML/MD正常生成

### Step F: validate_structure.sh 書き換え ✅
- [x] `AI/scripts/validate/validate_structure.sh` を書き換え
- [x] 出力:
  - `AI/snapshots/structure_violations.yaml`（YAML）
  - `AI/snapshots/preview/structure_violations.md`（MD）
- [x] 旧 `structure_violations.md` への追記ロジックを完全に削除
- [x] bash 3.x 互換性修正（declare -A → 文字列マッチ）
- [x] lib/ 未存在時の空レポート生成対応
- [x] 動作確認: 正常生成

### Step G: 差分検知ツール ✅
- [x] `AI/scripts/generate/diff_architecture.sh` を新規作成
- [x] `plan_architecture.yaml` と `actual_architecture.yaml` の差分表示
- [x] 未実装 / 無計画 / 実装済みの3分類
- [x] 進捗率の計算 + プログレスバー表示
- [x] 出力: `architecture_diff.yaml` + `preview/architecture_diff.md`
- [x] 動作確認: テストデータで 63% 進捗を正しく検出

### Step H: ビューア（将来）
- CLIツールでのツリー表示
- Web UIでのグラフィカル表示

---

## 9. 実装順序と依存関係

```
Step A → Step B → Step G
                     ↑
Step C ──────────────┘

Step D, E, F は独立して並行実装可能
```

- **A → B** は直列依存（テンプレートがないと generate_plan.sh が作れない）
- **C** は B と無関係に実装可能（lib/ を走査するだけ）
- **D, E, F** は B, C と無関係に実装可能（既存スクリプトの出力先変更のみ）
- **G** は B + C 完了後に実装（plan と actual の両方が必要）

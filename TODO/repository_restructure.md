# テンプレートリポジトリ全体構造のリストラクチャリング

> 実施日: 2026-04-10
> ステータス: **Phase 1〜3 完了**

## 背景

このリポジトリ（仕様駆動開発テンプレート）は、Anthropicがエージェントスキルズを発表する**以前**から開発されていた。当初の設計思想は：

- `.agent/rules/flutter.md` を最小限のシステムプロンプトとし
- 各階層の `instructions.md` へルーティングする（メタプロンプティング）

しかし、エージェントスキルズの登場に合わせて `.agent/skills/` を追加した結果、**責務境界が曖昧になった**。本リストラクチャリングで、当初のメタプロンプティング設計を復元しつつ、スキルズのプロセス制御機能だけを活かす整理を行った。

---

## 実施内容

### Phase 1: instructions.md → *_guide.md リネーム（完了）

27個の `instructions.md` を `{責務名}_guide.md` にリネームした。

```
AI/architecture/lib/
├── entry_point_guide.md                            # main.dart/app.dart ガイド
├── core/
│   ├── core_architecture.md                        # 変更なし
│   ├── api/api_guide.md
│   ├── database/database_guide.md
│   ├── database/table/table_guide.md
│   ├── database/migration/migration_guide.md
│   ├── env/env_guide.md
│   ├── exceptions/exceptions_guide.md
│   ├── routing/routing_guide.md
│   ├── routing/path/path_guide.md
│   └── theme/theme_guide.md
└── features/
    ├── features_architecture.md                    # 変更なし
    ├── 1_domain/
    │   ├── 1_entities/entity_guide.md
    │   ├── 2_repositories/repository_guide.md
    │   ├── 3_usecases/usecase_guide.md
    │   └── exceptions/domain_exception_guide.md
    ├── 2_infrastructure/
    │   ├── 1_models/model_guide.md
    │   ├── 2_data_sources/
    │   │   ├── 1_local/local_data_source_guide.md
    │   │   ├── 1_local/exceptions/local_exception_guide.md
    │   │   ├── 2_remote/remote_data_source_guide.md
    │   │   └── 2_remote/exceptions/remote_exception_guide.md
    │   └── 3_repositories/repository_impl_guide.md
    ├── 3_application/
    │   ├── 1_states/state_guide.md
    │   ├── 2_providers/provider_guide.md
    │   └── 3_notifiers/notifier_guide.md
    └── 4_presentation/
        ├── 1_widgets/1_atoms/atom_guide.md
        ├── 1_widgets/2_molecules/molecule_guide.md
        ├── 1_widgets/3_organisms/organism_guide.md
        └── 2_pages/page_guide.md
```

**命名ルール**: `{責務名}_guide.md`
- ファイル名だけで内容が分かる
- `*_guide.md` で一括grep可能

**参照更新したファイル**:
- `AI/architecture/directory_structure_and_naming_rules.md` — 13箇所
- `AI/architecture/lib/entry_point_guide.md` — 7箇所
- `AI/architecture/lib/core/core_architecture.md` — 2箇所

### Phase 2: スキルの整理 9 → 4（完了）

#### 分析結果

| カテゴリ | スキル | 判定 | 理由 |
|---------|--------|------|------|
| **プロセス制御** | `development-guide`, `stage1`, `stage2`, `stage3` | **維持** | 開発フローの順序制御。guide.mdでは代替不可 |
| **guide.mdの要約版** | `layer-implementation` | **削除** | 中身が「参照: instructions.md」だけ。stage3に統合 |
| **スクリプトラッパー** | `feature-generator`, `structure-validator`, `project-status` | **削除** | workflowsと完全重複 |
| **レビューガイド** | `code-reviewer` | **削除** | workflowsまたはrulesに移動可能 |

#### 削除したスキル（5つ）
- `flutter-layer-implementation/` — 内容を stage3 に統合
- `flutter-feature-generator/` — `generate_feature.sh` のラッパーに過ぎなかった
- `flutter-structure-validator/` — `validate_structure.sh` のラッパーに過ぎなかった
- `flutter-project-status/` — `status.sh` のラッパーに過ぎなかった
- `flutter-code-reviewer/` — workflowsで十分

#### 削除したスクリプト（3つ）
スキル内の `scripts/` フォルダにあった `AI/scripts/bash/` の薄いラッパー：
- `flutter-stage1-specification/scripts/status_update.sh` → `status.sh update` のラッパー
- `flutter-stage2-structure/scripts/status_check.sh` → `status.sh check` のラッパー
- `flutter-stage3-implementation/scripts/flutter_analyze.sh` → `flutter analyze` のラッパー

#### stage3 の書き換え
`flutter-stage3-implementation/SKILL.md` を全面書き換えし、各レイヤーで対応する `*_guide.md` を**直接参照**する構造にした。

```
Stage3 SKILL.md の新しい役割:
  「Domain層 Entity を実装するフェーズに入った」
  → AI に entity_guide.md を読ませる
  → 命名規則・実装パターンに自動的に準拠するコードが出る

  = 当初のメタプロンプティング設計をスキルズ上で復元
```

### Phase 3: 整合性の確認（完了）

**参照更新したファイル**:
- `README.md` — スキル一覧テーブル（9→4）、ツリー構造
- `.agent/skills/flutter-development-guide/SKILL.md` — 関連スキルテーブル
- `AI/document/structure_plan.md` — layer-implementation 参照削除

**確認結果**:
- `instructions.md` 残存: **0件**（TODO内の履歴記述のみ）
- 削除スキルへの参照残存: **0件**（TODO内の履歴記述のみ）
- スキル内 resources/ の重複: **なし**（プロセス手順の補足資料で性質が異なる）

---

## 実施後の構造

```
flutter_init/
├── .agent/
│   ├── rules/
│   │   └── flutter.md                # モード選択ルール
│   ├── skills/                       # 4つのプロセス制御スキル
│   │   ├── flutter-development-guide/    # 全体フロー指揮者
│   │   ├── flutter-stage1-specification/ # Stage1 プロセス制御
│   │   ├── flutter-stage2-structure/     # Stage2 プロセス制御
│   │   └── flutter-stage3-implementation/ # Stage3 プロセス制御 → *_guide.md を直接参照
│   └── workflows/                    # 8つのスラッシュコマンド（変更なし）
│
├── AI/
│   ├── architecture/
│   │   ├── directory_structure_and_naming_rules.md
│   │   ├── technology_stack.md
│   │   ├── recommended_packages.md
│   │   └── lib/                      # 27個の *_guide.md（メタプロンプティングの本体）
│   ├── document/                     # 仕様書・構造計画書テンプレート
│   ├── instructions/                 # 既存アプリ開発モード用手順
│   ├── logs/                         # ステータス・ログ
│   └── scripts/bash/                 # シェルスクリプト11本（スクリプトの唯一の配置場所）
│
├── TODO/
│   ├── architecture_data_format.md   # YAML統一フォーマット計画
│   └── repository_restructure.md     # 本ファイル
├── TODO.md                           # パッケージ化計画
├── README.md
├── LICENSE
└── .gitignore
```

---

## 設計原則（確立されたもの）

| 原則 | 説明 |
|------|------|
| **スキル = プロセス制御のみ** | スキルは「いつ・何を・どの順番で」の指揮者。具体的な実装ルールは持たない |
| **guide.md = 実装ルールの SSOT** | 27個の `*_guide.md` が各階層の実装パターン・命名規則の「Single Source of Truth」 |
| **workflows = スクリプトの正規入口** | スキル側からスクリプトを呼ぶラッパーは作らない |
| **scripts/ は一箇所に集約** | `AI/scripts/bash/` のみ。スキル内にスクリプトを配置しない |

---

## 今後の計画（未実施）

### Phase 4: architecture_data_format.md の実装
→ `TODO/architecture_data_format.md` に詳細記載済み
- `feature_request.yaml` スキーマ確定
- `generate_plan.sh` 変換スクリプト作成
- `status.sh snapshot --format yaml` 拡張
- plan vs actual の差分検知

### Phase 5: パッケージ化
→ `TODO.md` に詳細記載済み
- `flutter_init_annotation` / `flutter_init_gen` パッケージ作成
- build_runner ベースの全層自動生成

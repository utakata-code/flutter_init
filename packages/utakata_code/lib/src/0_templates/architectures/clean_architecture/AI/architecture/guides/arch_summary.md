---
trigger: always_on
---

# アーキテクチャ要約 — Clean Architecture（4層）

> このファイルはAIエージェントが**常時参照**するアーキテクチャ最小仕様です。
> 詳細なガイドは `AI/guides/architecture/lib/` を参照してください。

---

## 採用アーキテクチャ

**Clean Architecture — 4層構造**（このプロジェクトの公式推奨）

```
lib/features/{permission}/{feature_name}/
├── 1_domain/           # ドメイン層: ビジネスロジックの核心
├── 2_infrastructure/   # インフラ層: 外部データアクセスの実装
├── 3_application/      # アプリケーション層: 状態管理・Riverpod
└── 4_presentation/     # プレゼンテーション層: UI
```

---

## 各層の責務（1行要約）

| 層 | 責務 |
|---|---|
| `1_domain/` | エンティティ・リポジトリI/F・ユースケースを定義する（外部依存ゼロ） |
| `2_infrastructure/` | DB/API/ローカルストレージへのアクセスを実装する |
| `3_application/` | Riverpod で状態を管理し、ユースケースを呼び出す |
| `4_presentation/` | Widget でUIを構築し、状態を表示する |

---

## 絶対禁止事項

- `1_domain/` に `dart:io` / `package:http` / `package:drift` などの外部依存を書かない
- `1_domain/` にUIロジック（`BuildContext` 等）を書かない
- `4_presentation/` にビジネスロジックを書かない
- `4_presentation/` から Repository を直接呼ばない（必ず Notifier 経由）
- コード変更時に `AI/specs/application_specification.md` の更新を省略しない

---

## 命名規則（重要）

| ディレクトリ | ファイル名パターン |
|---|---|
| `1_domain/1_entities/` | `{name}_entity.dart` |
| `1_domain/2_repositories/` | `{name}_repository.dart` |
| `1_domain/3_usecases/` | `{verb}_{name}_usecase.dart` |
| `1_domain/exceptions/` | `{name}_exceptions.dart` |
| `2_infrastructure/1_models/` | `{name}_model.dart` |
| `2_infrastructure/2_data_sources/1_local/` | `{name}_local_data_source.dart` |
| `2_infrastructure/2_data_sources/2_remote/` | `{name}_remote_data_source.dart` |
| `2_infrastructure/3_repositories/` | `{name}_repository_impl.dart` |
| `3_application/1_states/` | `{name}_state.dart` |
| `3_application/2_providers/` | `{name}_providers.dart` |
| `3_application/3_notifiers/` | `{name}_notifier.dart` |
| `4_presentation/2_pages/` | `{name}_page.dart` |
| `4_presentation/1_widgets/1_atoms/` | `{name}_atom.dart` |
| `4_presentation/1_widgets/2_molecules/` | `{name}_molecule.dart` |
| `4_presentation/1_widgets/3_organisms/` | `{name}_organism.dart` |

---

## utakata CLI との連携

```bash
# 命名規則・構造違反を検出（コード変更後は必ず実行）
utakata validate

# フィーチャーを追加（手動でディレクトリを作らない）
utakata feature add <name> [--permission user|admin|shared|direct]

# 計画書を生成
utakata plan

# 現在の構造をスキャン
utakata scan
```

---

## 詳細ガイドの場所

- 各層の実装ルール: `AI/guides/architecture/lib/`
- ディレクトリ構造・命名規則の完全版: `AI/guides/architecture/directory_structure_and_naming_rules.md`
- 推奨パッケージ: `AI/guides/architecture/dependencies/`
- 協作ルール: `AI/guides/common/collaboration.md`

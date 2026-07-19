---
trigger: always_on
---

# アーキテクチャ要約 — MVVM（3層）

> このファイルはAIエージェントが**常時参照**するアーキテクチャ最小仕様です。
> 詳細なガイドは `AI/architecture/guides/` および各層の `GUIDE.md` を参照してください。

---

## 採用アーキテクチャ

**MVVM — 3層構造**（小〜中規模プロジェクト向け推奨）

```
lib/features/{permission}/{feature_name}/
├── 1_model/        # Model層: データ定義・リポジトリ・サービス
├── 2_viewmodel/    # ViewModel層: 状態管理・ビジネスロジック
└── 3_view/         # View層: UI（Screen / Widget）
```

---

## 各層の責務（1行要約）

| 層 | 責務 |
|---|---|
| `1_model/` | エンティティ・リポジトリI/F・サービスを定義する（外部UI依存ゼロ） |
| `2_viewmodel/` | Riverpod Notifier で状態を管理し、Service を呼び出す |
| `3_view/` | Widget / Screen でUIを構築し、状態を表示する |

---

## 絶対禁止事項

- `1_model/` に Flutter SDK（`BuildContext` 等）を import しない
- `1_model/` に状態管理ライブラリ（Riverpod）を import しない
- `3_view/` にビジネスロジックを書かない
- `3_view/` から Repository / Service を直接呼ばない（必ず Notifier 経由）
- `2_viewmodel/` から Flutter ウィジェットを import しない
- コード変更時に `AI/specs/application_specification.md` の更新を省略しない

---

## 命名規則（重要）

| ディレクトリ | ファイル名パターン |
|---|---|
| `1_model/1_entities/` | `{name}_entity.dart` |
| `1_model/2_repositories/` | `{name}_repository.dart` |
| `1_model/3_services/` | `{name}_service.dart` |
| `1_model/exceptions/` | `{name}_exception.dart` |
| `2_viewmodel/1_states/` | `{feature}_state.dart` |
| `2_viewmodel/2_notifiers/` | `{feature}_notifier.dart` |
| `3_view/1_widgets/` | `{name}_widget.dart` |
| `3_view/2_screens/` | `{feature}_screen.dart` |

---

## Clean Architecture との対比

| MVVM (3層) | Clean Architecture (4層) |
|---|---|
| `1_model/1_entities` | `1_domain/1_entities` |
| `1_model/2_repositories` | `1_domain/2_repositories` |
| `1_model/3_services` | `1_domain/3_usecases` |
| `1_model/exceptions` | `1_domain/exceptions` |
| （なし — Model 層に統合） | `2_infrastructure/` |
| `2_viewmodel/1_states` | `3_application/1_states` |
| `2_viewmodel/2_notifiers` | `3_application/3_notifiers` |
| `3_view/1_widgets` | `4_presentation/1_widgets` |
| `3_view/2_screens` | `4_presentation/2_pages` |

---

## utakata CLI との連携

```bash
# 命名規則・構造違反を検出（コード変更後は必ず実行）
utakata check

# フィーチャーを追加（手動でディレクトリを作らない）
utakata feature add <name> [--permission user|admin|shared|direct]

# 計画書を生成
utakata plan

# 現在の構造をスキャン
utakata check
```

---

## 詳細ガイドの場所

- 各層の実装ルール: `AI/architecture/features/` 配下の `GUIDE.md`
- ディレクトリ構造・命名規則の完全版: `AI/architecture/guides/directory_structure_and_naming_rules.md`
- 推奨パッケージ: `AI/architecture/guides/dependencies/`
- 協作ルール: `AI/architecture/guides/common/collaboration.md`

# サンプル構造計画書（参考例）

## メタ情報
- プロジェクト名: TaskManager App
- バージョン: v1.0
- 最終更新日: 2026-01-25
- 作成者: 泡沫Code

## 構造ポリシー
- クリーンアーキテクチャの構造に厳密準拠
- 新しいフォルダの作成禁止
- 命名規則の遵守（snake_case）

## 目的と範囲
- 対象フィーチャー: task_management
- 対象レイヤー: Domain / Infrastructure / Application / Presentation

## ディレクトリ構造

```
lib/
  core/
    routing/
      app_router.dart
    routing/path/
      task_path.dart
    theme/
      app_theme.dart
    database/
      app_database.dart
    database/table/
      task_table.dart
  features/
    user/
      task_management/
        1_domain/
          1_entities/
            task_entity.dart
            category_entity.dart
          2_repositories/
            task_repository.dart
          3_usecases/
            create_task_usecase.dart
            get_tasks_usecase.dart
            update_task_usecase.dart
            delete_task_usecase.dart
        2_infrastructure/
          1_models/
            task_model.dart
          2_data_sources/
            1_local/
              task_local_data_source.dart
              task_local_data_source_impl.dart
          3_repositories/
            task_repository_impl.dart
        3_application/
          1_states/
            task_state.dart
          2_providers/
            task_providers.dart
          3_notifiers/
            task_notifier.dart
        4_presentation/
          2_pages/
            task_list_page.dart
            task_detail_page.dart
            task_create_page.dart
          1_widgets/
            1_atoms/
              task_checkbox.dart
            2_molecules/
              task_list_item.dart
            3_organisms/
              task_list.dart
```

## ファイル定義表

| パス | ファイル名 | 役割 |
|-----|----------|------|
| `1_domain/1_entities/` | `task_entity.dart` | タスクエンティティ（Freezed） |
| `1_domain/2_repositories/` | `task_repository.dart` | リポジトリインターフェース |
| `1_domain/3_usecases/` | `create_task_usecase.dart` | タスク作成ユースケース |
| `2_infrastructure/1_models/` | `task_model.dart` | DBモデル（Drift用） |
| `3_application/3_notifiers/` | `task_notifier.dart` | タスク状態管理（@riverpod） |
| `4_presentation/2_pages/` | `task_list_page.dart` | タスク一覧ページ |

## ルーティング計画

| ルート名 | パス | ページ |
|---------|-----|--------|
| home | `/` | `TaskListPage` |
| taskDetail | `/tasks/:id` | `TaskDetailPage` |
| taskCreate | `/tasks/new` | `TaskCreatePage` |

## 実装順序
1. Domain層（エンティティ → リポジトリIF → ユースケース）
2. Infrastructure層（モデル → データソース → リポジトリ実装）
3. Application層（状態 → プロバイダ → ノティファイア）
4. Presentation層（ウィジェット → ページ）

## 更新履歴
- 2026-01-25: 初版作成

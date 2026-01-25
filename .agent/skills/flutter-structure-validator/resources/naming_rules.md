# 命名規則

## ディレクトリ命名

| 対象 | 規則 | 例 |
|-----|------|-----|
| フィーチャー名 | snake_case | `user_profile/`, `task_management/` |
| 層ディレクトリ | 番号_名前 | `1_domain/`, `2_infrastructure/` |
| サブディレクトリ | 番号_名前 or 名前 | `1_entities/`, `exceptions/` |

## ファイル命名

### Domain層
| ファイル種別 | サフィックス | 例 |
|------------|------------|-----|
| エンティティ | `_entity.dart` | `task_entity.dart` |
| リポジトリIF | `_repository.dart` | `task_repository.dart` |
| ユースケース | `_usecase.dart` | `create_task_usecase.dart` |
| 例外 | `_exception.dart` | `task_not_found_exception.dart` |

### Infrastructure層
| ファイル種別 | サフィックス | 例 |
|------------|------------|-----|
| モデル | `_model.dart` | `task_model.dart` |
| データソースIF | `_data_source.dart` | `task_local_data_source.dart` |
| データソース実装 | `_data_source_impl.dart` | `task_local_data_source_impl.dart` |
| リポジトリ実装 | `_repository_impl.dart` | `task_repository_impl.dart` |

### Application層
| ファイル種別 | サフィックス | 例 |
|------------|------------|-----|
| 状態 | `_state.dart` | `task_state.dart` |
| プロバイダ | `_providers.dart` | `task_providers.dart` |
| ノティファイア | `_notifier.dart` | `task_notifier.dart` |

### Presentation層
| ファイル種別 | サフィックス | 例 |
|------------|------------|-----|
| ページ | `_page.dart` | `task_list_page.dart` |
| ウィジェット | 機能名.dart | `task_checkbox.dart` |

## クラス命名

| 対象 | 規則 | 例 |
|-----|------|-----|
| クラス | PascalCase | `TaskEntity`, `TaskRepository` |
| 抽象クラス | PascalCase | `TaskDataSource` |
| 実装クラス | PascalCase + Impl | `TaskRepositoryImpl` |
| 例外クラス | PascalCase + Exception | `TaskNotFoundException` |

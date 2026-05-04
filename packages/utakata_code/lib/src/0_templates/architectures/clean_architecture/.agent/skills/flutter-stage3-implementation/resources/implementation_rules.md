# 実装ルール

## コード生成遵守事項

```
✅ 仕様書の要件に準拠
✅ 構造計画書の役割定義に準拠
✅ utakata/guides/technology_stack.md のライブラリを使用
✅ utakata/guides/lib/features/features_architecture.md のアーキテクチャ・命名規則に準拠
✅ Notifier は @riverpod アノテーションを使用
✅ Presentation層は HookWidget / HookConsumerWidget を使用
❌ StatefulWidget の使用禁止
```

## 命名規則

| 対象 | 規則 | 例 |
|-----|------|-----|
| ファイル名 | snake_case | `task_entity.dart` |
| クラス名 | PascalCase | `TaskEntity` |
| 変数名 | camelCase | `taskList` |
| 定数 | camelCase or SCREAMING_SNAKE | `maxLength`, `MAX_LENGTH` |
| プロバイダ | camelCase + Provider | `taskNotifierProvider` |

## ファイル命名パターン

| レイヤー | サフィックス | 例 |
|---------|------------|-----|
| Entity | `_entity.dart` | `task_entity.dart` |
| Repository (IF) | `_repository.dart` | `task_repository.dart` |
| Repository (Impl) | `_repository_impl.dart` | `task_repository_impl.dart` |
| UseCase | `_usecase.dart` | `create_task_usecase.dart` |
| Model | `_model.dart` | `task_model.dart` |
| DataSource | `_data_source.dart` | `task_local_data_source.dart` |
| DataSource (Impl) | `_data_source_impl.dart` | `task_local_data_source_impl.dart` |
| State | `_state.dart` | `task_state.dart` |
| Provider | `_providers.dart` | `task_providers.dart` |
| Notifier | `_notifier.dart` | `task_notifier.dart` |
| Page | `_page.dart` | `task_list_page.dart` |
| Widget | 機能名.dart | `task_checkbox.dart` |

## 禁止事項

```
❌ 構造計画書にないファイルの作成
❌ 新しいディレクトリの作成
❌ StatefulWidget の使用
❌ グローバル変数の使用
❌ Domain層での外部ライブラリ依存
```

## 推奨事項

```
✅ 単一責任の原則に従う
✅ テスタブルなコードを書く
✅ コメントを日本語で記述
✅ 各レイヤー完了後に flutter analyze を実行
```

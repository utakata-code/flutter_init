# サンプル構造計画書（参考例）

## メタ情報
- プロジェクト名: MemoApp
- バージョン: v1.0
- 最終更新日: 2026-01-25
- 作成者: 泡沫Code

## 構造ポリシー
- MVVM アーキテクチャの構造に厳密準拠
- 新しいフォルダの作成禁止
- 命名規則の遵守（snake_case）

## 目的と範囲
- 対象フィーチャー: memo
- 対象レイヤー: Model / ViewModel / View

## ディレクトリ構造

```
lib/
  core/
    routing/
      app_router.dart
    theme/
      app_theme.dart
    di/
      providers.dart
    api/
      api_client.dart
  features/
    user/
      memo/
        1_model/
          1_entities/
            memo_entity.dart
            category_entity.dart
          2_repositories/
            memo_repository.dart
            memo_repository_impl.dart
          3_services/
            memo_service.dart
          exceptions/
            memo_exception.dart
        2_viewmodel/
          1_states/
            memo_state.dart
          2_notifiers/
            memo_notifier.dart
        3_view/
          1_widgets/
            memo_card_widget.dart
          2_screens/
            memo_list_screen.dart
            memo_detail_screen.dart
            memo_create_screen.dart
```

## ファイル定義表

| パス | ファイル名 | 役割 |
|-----|----------|------|
| `1_model/1_entities/` | `memo_entity.dart` | メモエンティティ（Freezed） |
| `1_model/2_repositories/` | `memo_repository.dart` | リポジトリインターフェース |
| `1_model/2_repositories/` | `memo_repository_impl.dart` | リポジトリ実装 |
| `1_model/3_services/` | `memo_service.dart` | メモビジネスロジック |
| `2_viewmodel/1_states/` | `memo_state.dart` | メモ状態定義（Freezed） |
| `2_viewmodel/2_notifiers/` | `memo_notifier.dart` | メモ状態管理（Notifier） |
| `3_view/2_screens/` | `memo_list_screen.dart` | メモ一覧画面 |

## ルーティング計画

| ルート名 | パス | スクリーン |
|---------|-----|-----------|
| home | `/` | `MemoListScreen` |
| memoDetail | `/memos/:id` | `MemoDetailScreen` |
| memoCreate | `/memos/new` | `MemoCreateScreen` |

## 実装順序
1. Model層（エンティティ → リポジトリI/F・実装 → サービス）
2. ViewModel層（状態 → ノティファイア）
3. View層（ウィジェット → 画面）

## 更新履歴
- 2026-01-25: 初版作成

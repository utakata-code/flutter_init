# 実装ルール

## コード生成遵守事項

```
✅ 仕様書の要件に準拠
✅ 構造計画書の役割定義に準拠
✅ AI/architecture/guides/dependencies/core_stack.md のライブラリを使用
✅ AI/architecture/guides/README.md のアーキテクチャ・命名規則に準拠
✅ Notifier は Riverpod Notifier / AsyncNotifier を使用
✅ View層は HookWidget / HookConsumerWidget / ConsumerWidget を使用
❌ StatefulWidget の使用禁止
```

## 命名規則

| 対象 | 規則 | 例 |
|-----|------|-----|
| ファイル名 | snake_case | `memo_entity.dart` |
| クラス名 | PascalCase | `MemoEntity` |
| 変数名 | camelCase | `memoList` |
| 定数 | camelCase or SCREAMING_SNAKE | `maxLength`, `MAX_LENGTH` |
| プロバイダ | camelCase + Provider | `memoNotifierProvider` |

## ファイル命名パターン

| レイヤー | サフィックス | 例 |
|---------|------------|-----|
| Entity | `_entity.dart` | `memo_entity.dart` |
| Repository (IF) | `_repository.dart` | `memo_repository.dart` |
| Repository (Impl) | `_repository_impl.dart` | `memo_repository_impl.dart` |
| Service | `_service.dart` | `memo_service.dart` |
| Exception | `_exception.dart` | `memo_exception.dart` |
| State | `_state.dart` | `memo_state.dart` |
| Notifier | `_notifier.dart` | `memo_notifier.dart` |
| Screen | `_screen.dart` | `memo_list_screen.dart` |
| Widget | `_widget.dart` | `memo_card_widget.dart` |

## 禁止事項

```
❌ 構造計画書にないファイルの作成
❌ 新しいディレクトリの作成
❌ StatefulWidget の使用
❌ グローバル変数の使用
❌ Model層での外部UIライブラリ依存
```

## 推奨事項

```
✅ 単一責任の原則に従う
✅ テスタブルなコードを書く
✅ コメントを日本語で記述
✅ 各レイヤー完了後に flutter analyze を実行
```

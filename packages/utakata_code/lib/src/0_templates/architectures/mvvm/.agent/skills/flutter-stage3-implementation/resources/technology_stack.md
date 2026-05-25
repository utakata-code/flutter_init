# 技術スタック参照

## 主要ライブラリ

| カテゴリ | ライブラリ | 役割 |
|---------|-----------|------|
| 状態管理 | hooks_riverpod | DIコンテナ、状態管理 |
| データモデル | freezed | イミュータブルクラス生成 |
| 画面遷移 | go_router | 型安全なルーティング |
| HTTP通信 | dio | HTTPクライアント |
| UI補助 | flutter_hooks | フック機能 |

## 依存パッケージ (pubspec.yaml)

### dependencies
```yaml
hooks_riverpod: ^2.6.1
flutter_hooks: ^0.20.5
freezed_annotation: ^3.0.0
json_annotation: ^4.9.0
go_router: ^15.1.3
dio: ^5.4.0
shared_preferences: ^2.5.5
logger: ^2.6.2
intl: ^0.20.2
```

### dev_dependencies
```yaml
build_runner: ^2.4.8
freezed: ^3.0.0
json_serializable: ^6.8.0
```

## コード生成コマンド

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 使用パターン

### Freezedエンティティ
```dart
@freezed
abstract class MemoEntity with _$MemoEntity {
  const factory MemoEntity({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
  }) = _MemoEntity;

  factory MemoEntity.fromJson(Map<String, dynamic> json) =>
      _$MemoEntityFromJson(json);
}
```

### Riverpod Notifier
```dart
@riverpod
class MemoNotifier extends _$MemoNotifier {
  @override
  MemoState build() {
    return const MemoState.initial();
  }

  Future<void> loadMemos() async {
    state = const MemoState.loading();
    final memos = await ref.read(memoServiceProvider).fetchAll();
    state = MemoState.loaded(memos: memos);
  }
}
```

### ConsumerWidget
```dart
class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoNotifierProvider);
    // ...
  }
}
```

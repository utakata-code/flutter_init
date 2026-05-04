# 技術スタック参照

## 主要ライブラリ

| カテゴリ | ライブラリ | 役割 |
|---------|-----------|------|
| 状態管理 | riverpod, hooks_riverpod | DIコンテナ、状態管理 |
| データモデル | freezed | イミュータブルクラス生成 |
| 画面遷移 | go_router | 型安全なルーティング |
| ローカルDB | drift | 型安全なローカルDB |
| UI補助 | flutter_hooks | フック機能 |

## 依存パッケージ (pubspec.yaml)

### dependencies
```yaml
riverpod: ^2.4.0
hooks_riverpod: ^2.4.0
flutter_hooks: ^0.20.0
freezed_annotation: ^3.1.0
json_annotation: ^4.8.0
go_router: ^12.0.0
drift: ^2.14.0
sqlite3_flutter_libs: ^0.5.0
path_provider: ^2.1.0
path: ^1.8.0
```

### dev_dependencies
```yaml
build_runner: ^2.4.0
freezed: ^3.2.3
json_serializable: ^6.7.0
drift_dev: ^2.14.0
riverpod_generator: ^2.4.0
```

## コード生成コマンド

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 使用パターン

### Freezedエンティティ
```dart
@freezed
class TaskEntity with _$TaskEntity {
  const factory TaskEntity({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isCompleted,
  }) = _TaskEntity;
}
```

### Riverpod Notifier
```dart
@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  FutureOr<List<TaskEntity>> build() async {
    return await ref.read(getTasksUseCaseProvider).execute();
  }
}
```

### HookConsumerWidget
```dart
class TaskListPage extends HookConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskNotifierProvider);
    // ...
  }
}
```

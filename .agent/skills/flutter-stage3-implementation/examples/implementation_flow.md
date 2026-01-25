# 実装フローサンプル

## フィーチャー: タスク管理機能の実装例

### 1. Domain層

#### 1-1. エンティティ (`1_domain/1_entities/task_entity.dart`)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_entity.freezed.dart';

/// タスクエンティティ
/// タスクのビジネスロジックで使用するデータ構造
@freezed
class TaskEntity with _$TaskEntity {
  const factory TaskEntity({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isCompleted,
    required DateTime createdAt,
  }) = _TaskEntity;
}
```

#### 1-2. リポジトリIF (`1_domain/2_repositories/task_repository.dart`)
```dart
import '../1_entities/task_entity.dart';

/// タスクリポジトリインターフェース
abstract class TaskRepository {
  Future<List<TaskEntity>> getAll();
  Future<TaskEntity?> getById(String id);
  Future<void> create(TaskEntity task);
  Future<void> update(TaskEntity task);
  Future<void> delete(String id);
}
```

### 2. Infrastructure層

#### 2-1. リポジトリ実装 (`2_infrastructure/3_repositories/task_repository_impl.dart`)
```dart
import '../../1_domain/1_entities/task_entity.dart';
import '../../1_domain/2_repositories/task_repository.dart';
import '../2_data_sources/1_local/task_local_data_source.dart';

/// タスクリポジトリ実装
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;

  TaskRepositoryImpl(this._localDataSource);

  @override
  Future<List<TaskEntity>> getAll() async {
    return await _localDataSource.getAll();
  }
  // ... 他のメソッド
}
```

### 3. Application層

#### 3-1. ノティファイア (`3_application/3_notifiers/task_notifier.dart`)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../1_domain/1_entities/task_entity.dart';
import '../2_providers/task_providers.dart';

part 'task_notifier.g.dart';

/// タスク状態管理ノティファイア
@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  FutureOr<List<TaskEntity>> build() async {
    final useCase = ref.read(getTasksUseCaseProvider);
    return await useCase.execute();
  }

  /// タスクを追加
  Future<void> addTask(TaskEntity task) async {
    final useCase = ref.read(createTaskUseCaseProvider);
    await useCase.execute(task);
    ref.invalidateSelf();
  }
}
```

### 4. Presentation層

#### 4-1. ページ (`4_presentation/2_pages/task_list_page.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../3_application/3_notifiers/task_notifier.dart';

/// タスク一覧ページ
class TaskListPage extends HookConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('タスク一覧')),
      body: tasksAsync.when(
        data: (tasks) => ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(tasks[index].title),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
```

## 実装完了後

```bash
# コード生成
dart run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze

# ステータス更新
/status report
```

# Presentation層実装ガイド

## 概要
Presentation層はUI表示を担当します。
Application層のNotifierを介して状態を取得・更新します。

## ディレクトリ構成

```
4_presentation/
├── 2_pages/           # ページ
└── 1_widgets/
    ├── 1_atoms/       # 最小単位ウィジェット
    ├── 2_molecules/   # 複合ウィジェット
    └── 3_organisms/   # 機能ウィジェット
```

## ウィジェット階層（Atomic Design）

| レベル | 説明 | 例 |
|-------|------|-----|
| Atoms | 最小単位、それ以上分解不可 | ボタン、テキスト、アイコン |
| Molecules | 複数のAtomsの組み合わせ | リストアイテム、フォームフィールド |
| Organisms | 複数のMoleculesの組み合わせ、機能を持つ | リスト、フォーム全体 |
| Pages | 画面全体 | 一覧ページ、詳細ページ |

## 重要ルール

```
❌ StatefulWidget の使用禁止
✅ HookWidget を使用（状態なし）
✅ HookConsumerWidget を使用（Riverpod連携）
```

## 1. ページ (`2_pages/`)

### 目的
画面全体の構成

### 実装パターン
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../3_application/3_notifiers/task_notifier.dart';
import '../1_widgets/3_organisms/task_list.dart';

/// タスク一覧ページ
class TaskListPage extends HookConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ノティファイアの状態を監視
    final tasksAsync = ref.watch(taskNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク一覧'),
      ),
      body: tasksAsync.when(
        data: (tasks) => TaskList(tasks: tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    // タスク作成ダイアログ
  }
}
```

## 2. Atoms (`1_widgets/1_atoms/`)

### 実装パターン
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// タスク完了チェックボックス
class TaskCheckbox extends HookWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const TaskCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      onChanged: onChanged,
    );
  }
}
```

## 3. Molecules (`1_widgets/2_molecules/`)

### 実装パターン
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../1_domain/1_entities/task_entity.dart';
import '../1_atoms/task_checkbox.dart';

/// タスクリストアイテム
class TaskListItem extends HookWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final ValueChanged<bool?> onCheckChanged;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: TaskCheckbox(
        isChecked: task.isCompleted,
        onChanged: onCheckChanged,
      ),
      title: Text(task.title),
      subtitle: task.description != null ? Text(task.description!) : null,
      onTap: onTap,
    );
  }
}
```

## 4. Organisms (`1_widgets/3_organisms/`)

### 実装パターン
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../1_domain/1_entities/task_entity.dart';
import '../../../3_application/3_notifiers/task_notifier.dart';
import '../2_molecules/task_list_item.dart';

/// タスクリスト
class TaskList extends HookConsumerWidget {
  final List<TaskEntity> tasks;

  const TaskList({super.key, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const Center(child: Text('タスクがありません'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          onTap: () => _navigateToDetail(context, task),
          onCheckChanged: (value) => _toggleComplete(ref, task.id),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, TaskEntity task) {
    // 詳細画面へ遷移
  }

  void _toggleComplete(WidgetRef ref, String taskId) {
    ref.read(taskNotifierProvider.notifier).toggleComplete(taskId);
  }
}
```

## Hooksの活用

```dart
// ローカル状態
final counter = useState(0);

// テキストコントローラー
final controller = useTextEditingController();

// フォーカス
final focusNode = useFocusNode();

// 副作用
useEffect(() {
  // 初期化処理
  return () {
    // クリーンアップ
  };
}, []);
```

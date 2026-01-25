# Domain層実装ガイド

## 概要
Domain層はビジネスロジックの中心で、外部ライブラリに依存しない純粋な層です。

## ディレクトリ構成

```
1_domain/
├── 1_entities/       # エンティティ定義
├── 2_repositories/   # リポジトリインターフェース
├── 3_usecases/       # ユースケース
└── exceptions/       # ドメイン例外
```

## 1. エンティティ (`1_entities/`)

### 目的
ビジネスで扱うデータ構造を定義

### 実装パターン
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_entity.freezed.dart';

/// タスクエンティティ
/// ビジネスロジックで使用するタスクのデータ構造
@freezed
class TaskEntity with _$TaskEntity {
  const factory TaskEntity({
    /// タスクID（UUID）
    required String id,
    /// タスクタイトル
    required String title,
    /// タスク説明（任意）
    String? description,
    /// 完了状態
    @Default(false) bool isCompleted,
    /// 作成日時
    required DateTime createdAt,
  }) = _TaskEntity;
}
```

### ルール
- Freezedを使用してイミュータブルに
- 外部ライブラリ（Drift等）に依存しない
- 日本語でコメントを記述

## 2. リポジトリIF (`2_repositories/`)

### 目的
データアクセスの抽象化

### 実装パターン
```dart
import '../1_entities/task_entity.dart';

/// タスクリポジトリインターフェース
/// データソースに依存しないデータアクセスの抽象化
abstract class TaskRepository {
  /// すべてのタスクを取得
  Future<List<TaskEntity>> getAll();

  /// IDでタスクを取得
  Future<TaskEntity?> getById(String id);

  /// タスクを作成
  Future<void> create(TaskEntity task);

  /// タスクを更新
  Future<void> update(TaskEntity task);

  /// タスクを削除
  Future<void> delete(String id);
}
```

### ルール
- 抽象クラスとして定義
- 実装詳細を含めない
- エンティティを返す

## 3. ユースケース (`3_usecases/`)

### 目的
単一のビジネス操作をカプセル化

### 実装パターン
```dart
import '../1_entities/task_entity.dart';
import '../2_repositories/task_repository.dart';

/// タスク取得ユースケース
class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  /// すべてのタスクを取得する
  Future<List<TaskEntity>> execute() async {
    return await _repository.getAll();
  }
}
```

### 命名規則
- 動詞 + 名詞 + UseCase
- 例: `CreateTaskUseCase`, `GetTasksUseCase`, `UpdateTaskUseCase`

## 4. 例外 (`exceptions/`)

### 実装パターン
```dart
/// タスクが見つからない例外
class TaskNotFoundException implements Exception {
  final String taskId;
  
  TaskNotFoundException(this.taskId);

  @override
  String toString() => 'TaskNotFoundException: Task with id $taskId not found';
}
```

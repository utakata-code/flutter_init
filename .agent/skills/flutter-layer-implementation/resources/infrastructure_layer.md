# Infrastructure層実装ガイド

## 概要
Infrastructure層はデータアクセスと外部システム連携を担当します。
Domain層のインターフェースを実装します。

## ディレクトリ構成

```
2_infrastructure/
├── 1_models/              # データモデル
├── 2_data_sources/
│   ├── 1_local/           # ローカルデータソース
│   │   └── exceptions/
│   └── 2_remote/          # リモートデータソース
│       └── exceptions/
└── 3_repositories/        # リポジトリ実装
```

## 1. モデル (`1_models/`)

### 目的
データベースやAPIのデータ構造を定義

### 実装パターン（Drift用）
```dart
import 'package:drift/drift.dart';

/// タスクテーブル定義
class TaskModels extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### エンティティへの変換
```dart
extension TaskModelMapper on TaskModel {
  /// モデルからエンティティへ変換
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      createdAt: createdAt,
    );
  }
}
```

## 2. データソース (`2_data_sources/`)

### ローカルデータソース (`1_local/`)

#### インターフェース
```dart
import '../../1_domain/1_entities/task_entity.dart';

/// タスクローカルデータソースインターフェース
abstract class TaskLocalDataSource {
  Future<List<TaskEntity>> getAll();
  Future<TaskEntity?> getById(String id);
  Future<void> insert(TaskEntity task);
  Future<void> update(TaskEntity task);
  Future<void> delete(String id);
}
```

#### 実装
```dart
import 'package:drift/drift.dart';
import '../../../../../core/database/app_database.dart';
import '../../1_domain/1_entities/task_entity.dart';
import 'task_local_data_source.dart';

/// タスクローカルデータソース実装
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase _database;

  TaskLocalDataSourceImpl(this._database);

  @override
  Future<List<TaskEntity>> getAll() async {
    final models = await _database.select(_database.taskModels).get();
    return models.map((m) => m.toEntity()).toList();
  }
  // ... 他のメソッド
}
```

## 3. リポジトリ実装 (`3_repositories/`)

### 目的
Domain層のリポジトリインターフェースを実装

### 実装パターン
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

  @override
  Future<TaskEntity?> getById(String id) async {
    return await _localDataSource.getById(id);
  }

  @override
  Future<void> create(TaskEntity task) async {
    await _localDataSource.insert(task);
  }

  @override
  Future<void> update(TaskEntity task) async {
    await _localDataSource.update(task);
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }
}
```

### ルール
- Domain層のインターフェースを実装（`implements`）
- データソースへの委譲
- 例外のハンドリング

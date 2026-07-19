# Service Layer — サービス層ガイド (MVVM)

> `lib/features/{perm}/{feature}/1_model/3_services/`

## 責務

**ビジネスロジック**を集約する。Clean Architecture における UseCase に相当する役割。
リポジトリを通じてデータにアクセスし、複数のリポジトリ間の協調や、ドメイン固有の処理を実行する。

## ルール

- リポジトリのインターフェース（抽象クラス）に依存する（実装クラスへの直接依存は禁止）
- 1つのサービスに複数のメソッドを持たせてよい（UseCase と異なりサービス単位でまとめる）
- 状態管理ライブラリ（Riverpod 等）に依存しない
- Flutter SDK に依存しない

## 命名規則

`{対象名}_service.dart` — 例: `memo_service.dart`

## 実装例

```dart
import '../1_entities/memo_entity.dart';
import '../2_repositories/memo_repository.dart';

class MemoService {
  final MemoRepository _repository;

  const MemoService({required MemoRepository repository})
      : _repository = repository;

  Future<List<MemoEntity>> fetchAll() async {
    return _repository.fetchAll();
  }

  Future<void> create({
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final memo = MemoEntity(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(memo);
  }
}
```

## 許可される import

- `import '../1_entities/some_entity.dart';`
- `import '../2_repositories/some_repository.dart';`
- `import '../exceptions/some_exception.dart';`

## 禁止される import

- `import 'package:flutter/material.dart';`
- `import 'package:riverpod/riverpod.dart';`
- ViewModel / View 層のファイル

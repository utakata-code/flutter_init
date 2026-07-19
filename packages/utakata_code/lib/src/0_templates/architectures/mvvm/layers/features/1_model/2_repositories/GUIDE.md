# Repository Layer — リポジトリ層ガイド (MVVM)

> `lib/features/{perm}/{feature}/1_model/2_repositories/`

## 責務

データアクセスの**抽象インターフェース**を定義する。
ViewModel / Service 層がデータの取得先（ローカル or リモート）を意識せずに利用できるようにする。

## ルール

- `abstract interface class` で定義する（具象クラスは禁止）
- 戻り値はドメインエンティティ（`{name}_entity.dart`）を使用する
- 同一ディレクトリに実装クラス（`{name}_repository_impl.dart`）を配置する
- 外部ライブラリ（Dio, Drift 等）に依存しない

## 命名規則

`{対象名}_repository.dart` — 例: `memo_repository.dart`

## 実装例

```dart
import '../1_entities/memo_entity.dart';

abstract interface class MemoRepository {
  Future<List<MemoEntity>> fetchAll();
  Future<MemoEntity?> getById(String id);
  Future<void> save(MemoEntity memo);
  Future<void> delete(String id);
}
```

## 許可される import

- `import '../1_entities/some_entity.dart';`
- `import '../exceptions/some_exception.dart';`

## 禁止される import

- `import 'package:flutter/material.dart';`
- `import 'package:dio/dio.dart';`
- `import 'package:drift/drift.dart';`

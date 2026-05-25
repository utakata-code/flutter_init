# Entity Layer — エンティティ層ガイド (MVVM)

> `lib/features/{perm}/{feature}/1_model/1_entities/`

## 責務

ビジネスオブジェクトを不変（immutable）なデータクラスとして定義する。
アプリケーション全体のデータ構造の**唯一の真実の源**（Single Source of Truth）。

## ルール

- `freezed` を使用して不変性を保証する
- ビジネスロジックを持たない純粋なデータクラスとして定義する
- 外部ライブラリ（Flutter, Dio, Drift 等）に依存しない
- `fromJson` / `toJson` は必要に応じて `json_serializable` で生成する

## 命名規則

`{対象名}_entity.dart` — 例: `memo_entity.dart`

## 実装例

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_entity.freezed.dart';
part 'memo_entity.g.dart';

@freezed
abstract class MemoEntity with _$MemoEntity {
  const factory MemoEntity({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoEntity;

  factory MemoEntity.fromJson(Map<String, dynamic> json) =>
      _$MemoEntityFromJson(json);
}
```

## 許可される import

- `import 'dart:core';`
- `import 'package:freezed_annotation/freezed_annotation.dart';`
- `import 'package:json_annotation/json_annotation.dart';`
- 同一ディレクトリ内の他エンティティ

## 禁止される import

- `import 'package:flutter/material.dart';`
- `import 'package:riverpod/riverpod.dart';`
- `import 'package:dio/dio.dart';`
- Infrastructure 層のファイル

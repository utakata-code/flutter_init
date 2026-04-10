---
applyTo: 'lib/features/**/1_domain/1_entities/**'
---

# Entity Layer Instructions - エンティティ層

## 概要
エンティティはビジネスロジックの中核となるオブジェクトです。アプリケーションのビジネスルールやドメインロジックを表現します。

## 役割と責務

### ✅ すべきこと
- **ビジネスオブジェクトの定義**: アプリケーションで扱う中核的なデータ構造
- **ビジネスルールの実装**: ドメイン固有のバリデーションやビジネスロジック
- **不変性の保証**: オブジェクトの整合性を維持
- **純粋なDartコード**: 外部ライブラリに依存しない実装

### ❌ してはいけないこと
- **UIフレームワークへの依存**: Flutterウィジェットのimport禁止
- **データベースアクセス**: 永続化に関する処理の記述
- **HTTP通信**: 外部APIへのアクセス処理
- **状態管理ライブラリへの依存**: Riverpodなどのimport禁止

## 実装ガイドライン

### 1. Freezedパッケージの使用
Freezed v3以降では、ファクトリーコンストラクターを用いるデータクラス定義において、ベースクラスにabstractもしくはsealedを付与することが推奨・必要です。これにより、コード生成（copyWith、等価比較、パターンマッチングなど）が正しく機能し、ユニオン型（複数のfactory）を安全に表現できます。
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    DateTime? createdAt,
  }) = _UserEntity;

  // JSONシリアライズが必要な場合のみ追加
  factory UserEntity.fromJson(Map<String, dynamic> json) => 
      _$UserEntityFromJson(json);
}
```

### 2. ビジネスロジックの実装
```dart
@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._(); // メソッド定義用のプライベートコンストラクター
  
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    required UserRole role,
  }) = _UserEntity;

  // ビジネスロジック：管理者かどうかの判定
  bool get isAdmin => role == UserRole.admin;
  
  // ビジネスロジック：ユーザー名のバリデーション
  bool get hasValidName => name.isNotEmpty && name.length >= 2;
  
  // ビジネスロジック：メールアドレスのバリデーション
  bool get hasValidEmail => email.contains('@') && email.contains('.');
}
```

### 3. Enumの活用
```dart
enum UserRole {
  user,
  admin,
  moderator;
  
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'ユーザー';
      case UserRole.admin:
        return '管理者';
      case UserRole.moderator:
        return 'モデレーター';
    }
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{対象名}_entity.dart`
- **例**: `user_entity.dart`, `product_entity.dart`, `order_entity.dart`

### クラス名
- **命名形式**: `{対象名}Entity`
- **例**: `UserEntity`, `ProductEntity`, `OrderEntity`

### プロパティ名
- **camelCase**を使用
- **例**: `userId`, `createdAt`, `updatedAt`

## ベストプラクティス

### 1. 不変性の保証
```dart
// ✅ Good: Freezedによる不変オブジェクト
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
  }) = _UserEntity;
}

// ❌ Bad: 可変なプロパティ
class UserEntity {
  String id;
  String name;
  
  UserEntity({required this.id, required this.name});
}
```

### 2. バリデーションロジック
```dart
@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._();
  
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
  }) = _UserEntity;

  // バリデーションメソッド
  List<String> validate() {
    final errors = <String>[];
    
    if (name.isEmpty) {
      errors.add('名前は必須です');
    }
    
    if (!email.contains('@')) {
      errors.add('有効なメールアドレスを入力してください');
    }
    
    return errors;
  }
  
  bool get isValid => validate().isEmpty;
}
```

### 3. ファクトリーコンストラクターの活用
```dart
@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._();
  
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) = _UserEntity;

  // 新規ユーザー作成用のファクトリー
  factory UserEntity.create({
    required String name,
    required String email,
  }) {
    return UserEntity(
      id: const Uuid().v4(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
  }
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:core';

// ✅ Freezed（コード生成）
import 'package:freezed_annotation/freezed_annotation.dart';

// ✅ JSON Annotation（必要な場合のみ）
import 'package:json_annotation/json_annotation.dart';

// ✅ 同一層内の他のエンティティ
import '../other_entity.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ 状態管理
import 'package:riverpod/riverpod.dart';

// ❌ HTTP通信
import 'package:dio/dio.dart';

// ❌ データベース
import 'package:drift/drift.dart';

// ❌ 他の層への依存
import '../../infrastructure/models/user_model.dart';
```

## テスト指針

### 1. ユニットテストの作成
```dart
// test/domain/entities/user_entity_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserEntity', () {
    test('should create valid user entity', () {
      // Given
      const user = UserEntity(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      // Then
      expect(user.id, '1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.isValid, true);
    });

    test('should validate email format', () {
      // Given
      const invalidUser = UserEntity(
        id: '1',
        name: 'John Doe',
        email: 'invalid-email',
      );

      // Then
      expect(invalidUser.isValid, false);
    });
  });
}
```

## 注意事項

1. **純粋性の維持**: エンティティは純粋なDartコードとして実装し、外部依存を最小限に抑える
2. **ビジネスロジックの集約**: ドメイン固有のルールやバリデーションはエンティティに集約
3. **不変性**: 一度作成されたエンティティは変更されない設計を心がける
4. **テスタビリティ**: 複雑なビジネスロジックには必ずユニットテストを作成

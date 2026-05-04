---
applyTo: 'lib/features/**/2_infrastructure/1_models/**'
---

# Model Layer Instructions - モデル層

## 概要
モデル層は、外部データソース（API、データベース）とドメインエンティティの間の変換を担当します。データの永続化、シリアライゼーション、デシリアライゼーションを担当する重要な層です。

## 役割と責務

### ✅ すべきこと
- **データ変換**: 外部データ形式とドメインエンティティ間の変換
- **シリアライゼーション**: オブジェクトをJSON、XMLなどの形式に変換
- **デシリアライゼーション**: 外部データからオブジェクトを構築
- **データベーススキーマ対応**: Driftやその他のDBスキーマとの整合性保持
- **APIレスポンス対応**: RESTfulAPIのレスポンス形式への対応

### ❌ してはいけないこと
- **ビジネスロジックの実装**: ドメインロジックやビジネスルールの記述
- **UIロジックの実装**: プレゼンテーション層のロジックの混入
- **データアクセス処理**: 直接的なHTTPリクエストやSQL実行
- **状態管理**: アプリケーションの状態管理や UI状態の保持

## 実装ガイドライン

### 1. 基本的なAPIレスポンスモデル
```dart
// models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../1_entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
  });

  /// JSONからUserModelを生成
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);

  /// UserModelをJSONに変換
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// ドメインエンティティに変換
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl,
    );
  }

  /// ドメインエンティティからモデルを生成
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      createdAt: entity.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      profileImageUrl: entity.profileImageUrl,
    );
  }
}
```

### 2. ネストしたオブジェクトを含むモデル
```dart
// models/order_model.dart
@JsonSerializable()
class OrderModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'order_items')
  final List<OrderItemModel> orderItems;
  final OrderStatus status;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderItems,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => 
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      userId: userId,
      orderItems: orderItems.map((item) => item.toEntity()).toList(),
      status: status,
      totalAmount: Money(totalAmount),
      createdAt: createdAt,
    );
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      userId: entity.userId,
      orderItems: entity.orderItems
          .map((item) => OrderItemModel.fromEntity(item))
          .toList(),
      status: entity.status,
      totalAmount: entity.totalAmount.value,
      createdAt: entity.createdAt,
    );
  }
}

@JsonSerializable()
class OrderItemModel {
  @JsonKey(name: 'product_id')
  final String productId;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;

  const OrderItemModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => 
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      productId: productId,
      quantity: quantity,
      unitPrice: Money(unitPrice),
    );
  }

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      productId: entity.productId,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice.value,
    );
  }
}
```

### 3. Drift用のモデル（データベース）
Drift向けのDBモデルでも、キャッシュやバックアップ、デバッグ用途でJSON入出力を行えるように、`@JsonSerializable` を付与しておくことを推奨します。
```dart
// models/user_db_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

part 'user_db_model.g.dart';

@JsonSerializable()
class UserDbModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImageUrl;

  const UserDbModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
  });

  /// JSONからUserDbModelを生成（JSONシリアライズ対応）
  factory UserDbModel.fromJson(Map<String, dynamic> json) =>
      _$UserDbModelFromJson(json);

  /// UserDbModelをJSONに変換（JSONシリアライズ対応）
  Map<String, dynamic> toJson() => _$UserDbModelToJson(this);

  /// DriftのUserデータからモデルを生成
  factory UserDbModel.fromDriftUser(User user) {
    return UserDbModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      profileImageUrl: user.profileImageUrl,
    );
  }

  /// モデルをDriftのCompanionに変換
  UsersCompanion toDriftCompanion() {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      role: Value(role),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      profileImageUrl: Value(profileImageUrl),
    );
  }

  /// ドメインエンティティに変換
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl,
    );
  }

  /// ドメインエンティティからDBモデルを生成
  factory UserDbModel.fromEntity(UserEntity entity) {
    return UserDbModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      role: entity.role ?? 'user', // デフォルト値
      createdAt: entity.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      profileImageUrl: entity.profileImageUrl,
    );
  }

  /// Driftテーブル定義は app_database.dart で管理
  /// 例:
  /// class Users extends Table {
  ///   TextColumn get id => text()();
  ///   TextColumn get name => text()();
  ///   TextColumn get email => text().unique()();
  ///   TextColumn get role => text()();
  ///   DateTimeColumn get createdAt => dateTime()();
  ///   DateTimeColumn get updatedAt => dateTime()();
  ///   TextColumn get profileImageUrl => text().nullable()();
  ///   
  ///   @override
  ///   Set<Column> get primaryKey => {id};
  /// }
}
```

補足: `json_serializable` を用いたコード生成を有効にするため、以下のコマンドを実行してください。
```
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. エラーレスポンス用のモデル
```dart
// models/api_error_model.dart
@JsonSerializable()
class ApiErrorModel {
  final String message;
  final String? code;
  final Map<String, List<String>>? errors;
  final int? statusCode;

  const ApiErrorModel({
    required this.message,
    this.code,
    this.errors,
    this.statusCode,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) => 
      _$ApiErrorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorModelToJson(this);

  /// ドメイン例外に変換
  DomainException toDomainException() {
    switch (statusCode) {
      case 400:
        return ValidationException(message, errors);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      default:
        return ServerException(message, statusCode);
    }
  }
}
```

### 5. カスタムシリアライザー
```dart
// models/money_model.dart
class MoneyConverter implements JsonConverter<Money, double> {
  const MoneyConverter();

  @override
  Money fromJson(double json) => Money(json);

  @override
  double toJson(Money object) => object.value;
}

// 使用例
@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  @MoneyConverter()
  final Money price;

  // ...
}
```

## 命名規則

### ファイル名
- **API用**: `{対象名}_model.dart`
- **DB用**: `{対象名}_db_model.dart`
- **特殊用途**: `{対象名}_{用途}_model.dart`

### クラス名
- **API用**: `{対象名}Model`
- **DB用**: `{対象名}DbModel`
- **例**: `UserModel`, `UserDbModel`, `ApiErrorModel`

### メソッド名
- **変換メソッド**: `toEntity()`, `fromEntity()`, `toJson()`, `fromJson()`, `toMap()`, `fromMap()`
- **例外変換**: `toDomainException()`

## ベストプラクティス

### 1. Null安全性の考慮
```dart
@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String? email; // nullable
  @JsonKey(name: 'profile_image')
  final String? profileImageUrl;
  
  // デフォルト値の提供
  @JsonKey(defaultValue: false)
  final bool isActive;
  
  // カスタムデシリアライザー
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;

  static DateTime? _dateTimeFromJson(String? json) {
    return json != null ? DateTime.tryParse(json) : null;
  }

  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}
```

### 2. バリデーション付きモデル
```dart
class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) {
      throw ModelValidationException('ID cannot be empty');
    }
    if (name.isEmpty) {
      throw ModelValidationException('Name cannot be empty');
    }
    if (!email.contains('@')) {
      throw ModelValidationException('Invalid email format');
    }
  }
}
```

### 3. 継承とポリモーフィズム
```dart
// 基底クラス
@JsonSerializable()
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
}

// 継承クラス
@JsonSerializable()
class UserModel extends BaseModel {
  final String name;
  final String email;

  const UserModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:convert';

// ✅ JSON Annotation
import 'package:json_annotation/json_annotation.dart';

// ✅ ドメインエンティティ
import '../../1_domain/1_entities/user_entity.dart';

// ✅ ドメイン例外
import '../../1_domain/exceptions/domain_exceptions.dart';

// ✅ 値オブジェクト
import '../../1_domain/value_objects/money.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ HTTP通信ライブラリ
import 'package:dio/dio.dart';

// ❌ データベースライブラリ
import 'package:drift/drift.dart';

// ❌ 状態管理
import 'package:riverpod/riverpod.dart';

// ❌ プレゼンテーション層
import '../../4_presentation/pages/user_page.dart';
```

## テスト指針

### 1. シリアライゼーションテスト
```dart
// test/infrastructure/models/user_model_test.dart
void main() {
  group('UserModel', () {
    test('should serialize to JSON correctly', () {
      // Given
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      // When
      final json = user.toJson();

      // Then
      expect(json, {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'created_at': '2023-01-01T00:00:00.000',
        'updated_at': '2023-01-02T00:00:00.000',
      });
    });

    test('should deserialize from JSON correctly', () {
      // Given
      final json = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-01-02T00:00:00.000Z',
      };

      // When
      final user = UserModel.fromJson(json);

      // Then
      expect(user.id, '1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('should convert to entity correctly', () {
      // Given
      final model = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      // When
      final entity = model.toEntity();

      // Then
      expect(entity.id, '1');
      expect(entity.name, 'John Doe');
      expect(entity.email, 'john@example.com');
    });
  });
}
```

## 注意事項

1. **単一責任の原則**: 1つのモデルは1つのデータ形式との変換のみを担当
2. **不変性**: モデルオブジェクトは作成後に変更されない設計
3. **型安全性**: 可能な限り厳密な型定義を行い、実行時エラーを防ぐ
4. **パフォーマンス**: 大量データの変換時のメモリ使用量とパフォーマンスを考慮
5. **バージョン互換性**: APIの変更に対する後方互換性を考慮した設計

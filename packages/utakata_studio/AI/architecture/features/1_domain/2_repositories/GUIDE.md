---
applyTo: 'lib/features/**/1_domain/2_repositories/**'
---

# Repository Interface Layer Instructions - リポジトリインターフェース層

## 概要
リポジトリインターフェースは、ドメイン層とインフラストラクチャ層を分離するための抽象化レイヤーです。データアクセスの契約を定義し、依存性の逆転原則を実現します。

## 役割と責務

### ✅ すべきこと
- **データアクセスの抽象化**: 具体的な実装に依存しないインターフェースの定義
- **ドメインロジックの表現**: ビジネス要件に基づくメソッドシグネチャの定義
- **依存性の逆転**: 上位層（ドメイン）が下位層（インフラ）に依存しない設計
- **エンティティの使用**: ドメインオブジェクト（Entity）を入出力として使用

### ❌ してはいけないこと
- **具体的な実装の記述**: データベースやAPIの具体的なアクセス処理
- **UIフレームワークへの依存**: Flutterウィジェットのimport禁止
- **外部ライブラリへの依存**: HTTP、データベースクライアントのimport禁止
- **モデルクラスの使用**: インフラ層のModelクラスの直接使用禁止

## 実装ガイドライン

### 1. 基本的なインターフェース定義
```dart
// repositories/user_repository.dart
import '../1_entities/user_entity.dart';

abstract class UserRepository {
  // 単一ユーザーの取得
  Future<UserEntity?> getUser(String id);
  
  // 複数ユーザーの取得
  Future<List<UserEntity>> getUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  });
  
  // ユーザーの作成
  Future<UserEntity> createUser(UserEntity user);
  
  // ユーザーの更新
  Future<UserEntity> updateUser(UserEntity user);
  
  // ユーザーの削除
  Future<void> deleteUser(String id);
  
  // ユーザーの存在確認
  Future<bool> userExists(String id);
}
```

### 2. 検索・フィルタリング機能
```dart
abstract class ProductRepository {
  // カテゴリ別商品取得
  Future<List<ProductEntity>> getProductsByCategory(String categoryId);
  
  // 価格範囲での検索
  Future<List<ProductEntity>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
  });
  
  // 複合条件での検索
  Future<List<ProductEntity>> searchProducts({
    String? keyword,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductStatus? status,
    int? limit,
    int? offset,
  });
}
```

### 3. バッチ操作
```dart
abstract class OrderRepository {
  // 複数注文の一括作成
  Future<List<OrderEntity>> createOrders(List<OrderEntity> orders);
  
  // 複数注文の一括更新
  Future<List<OrderEntity>> updateOrders(List<OrderEntity> orders);
  
  // 条件による一括削除
  Future<int> deleteOrdersByStatus(OrderStatus status);
  
  // トランザクション処理
  Future<T> transaction<T>(Future<T> Function() action);
}
```

### 4. ストリーム対応（リアルタイム更新）
```dart
abstract class ChatRepository {
  // メッセージのリアルタイム監視
  Stream<List<MessageEntity>> watchMessages(String chatRoomId);
  
  // ユーザーの在線状態監視
  Stream<UserPresenceEntity> watchUserPresence(String userId);
  
  // 新着通知の監視
  Stream<NotificationEntity> watchNotifications(String userId);
}
```

## 命名規則

### ファイル名
- **命名形式**: `{対象名}_repository.dart`
- **例**: `user_repository.dart`, `product_repository.dart`, `order_repository.dart`

### クラス名
- **命名形式**: `{対象名}Repository`
- **例**: `UserRepository`, `ProductRepository`, `OrderRepository`

### メソッド名
- **取得系**: `get{対象名}`, `find{対象名}`, `search{対象名}`
- **作成系**: `create{対象名}`, `add{対象名}`
- **更新系**: `update{対象名}`, `modify{対象名}`
- **削除系**: `delete{対象名}`, `remove{対象名}`
- **存在確認**: `{対象名}Exists`, `has{対象名}`
- **監視系**: `watch{対象名}`, `listen{対象名}`

## ベストプラクティス

### 1. エラーハンドリングの考慮
```dart
abstract class UserRepository {
  /// ユーザーを取得します
  /// 
  /// [id] ユーザーID
  /// 
  /// Returns: ユーザーエンティティ。見つからない場合はnull
  /// 
  /// Throws:
  /// - [NetworkException] ネットワークエラーの場合
  /// - [DatabaseException] データベースエラーの場合
  Future<UserEntity?> getUser(String id);
  
  /// ユーザーを作成します
  /// 
  /// [user] 作成するユーザーエンティティ
  /// 
  /// Returns: 作成されたユーザーエンティティ（IDなどが付与される）
  /// 
  /// Throws:
  /// - [ValidationException] バリデーションエラーの場合
  /// - [ConflictException] 既に存在するユーザーの場合
  Future<UserEntity> createUser(UserEntity user);
}
```

### 2. ページネーション対応
```dart
// shared/value_objects/pagination.dart
@freezed
class Pagination with _$Pagination {
  const factory Pagination({
    required int limit,
    required int offset,
    int? total,
  }) = _Pagination;
}

@freezed
class PaginatedResult<T> with _$PaginatedResult<T> {
  const factory PaginatedResult({
    required List<T> items,
    required Pagination pagination,
    required bool hasNext,
  }) = _PaginatedResult<T>;
}

// repository interface
abstract class ProductRepository {
  Future<PaginatedResult<ProductEntity>> getProducts({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  });
}
```

### 3. フィルター・ソート条件の型安全性
```dart
// shared/value_objects/sort.dart
enum SortOrder { asc, desc }

@freezed
class SortCondition with _$SortCondition {
  const factory SortCondition({
    required String field,
    required SortOrder order,
  }) = _SortCondition;
}

// repository interface
abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts({
    List<SortCondition>? sortConditions,
    Map<String, dynamic>? filters,
  });
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:async';

// ✅ 同一層内のエンティティ
import '../1_entities/user_entity.dart';
import '../1_entities/product_entity.dart';

// ✅ 共通の値オブジェクト
import '../../shared/value_objects/pagination.dart';

// ✅ 例外クラス（ドメイン固有）
import '../exceptions/domain_exceptions.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ HTTP通信
import 'package:dio/dio.dart';

// ❌ データベース
import 'package:drift/drift.dart';

// ❌ インフラ層への依存
import '../../2_infrastructure/models/user_model.dart';

// ❌ アプリケーション層への依存
import '../../3_application/states/user_state.dart';
```

## インターフェース設計パターン

### 1. CRUDパターン
```dart
abstract class BaseRepository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<T> update(T entity);
  Future<void> delete(ID id);
}

abstract class UserRepository extends BaseRepository<UserEntity, String> {
  // ユーザー固有のメソッドを追加
  Future<UserEntity?> findByEmail(String email);
  Future<List<UserEntity>> findByRole(UserRole role);
}
```

### 2. 仕様パターン（Specification Pattern）
```dart
// shared/specifications/specification.dart
abstract class Specification<T> {
  bool isSatisfiedBy(T candidate);
}

abstract class UserRepository {
  Future<List<UserEntity>> findBySpecification(
    Specification<UserEntity> specification,
  );
}
```

### 3. リポジトリファクトリーパターン
```dart
abstract class RepositoryFactory {
  UserRepository createUserRepository();
  ProductRepository createProductRepository();
  OrderRepository createOrderRepository();
}
```

## テスト指針

### 1. モックリポジトリの作成
```dart
// test/domain/repositories/mock_user_repository.dart
class MockUserRepository extends Mock implements UserRepository {}

// テストでの使用例
void main() {
  group('UserRepository', () {
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
    });

    test('should return user when getUser is called with valid id', () async {
      // Given
      const userId = '1';
      const expectedUser = UserEntity(
        id: userId,
        name: 'Test User',
        email: 'test@example.com',
      );
      
      when(() => mockRepository.getUser(userId))
          .thenAnswer((_) async => expectedUser);

      // When
      final result = await mockRepository.getUser(userId);

      // Then
      expect(result, expectedUser);
      verify(() => mockRepository.getUser(userId)).called(1);
    });
  });
}
```

## 注意事項

1. **抽象化の適切なレベル**: 過度に抽象化せず、ビジネス要件に基づいた適切なレベルでの抽象化
2. **インターフェースの安定性**: 一度定義したインターフェースは可能な限り変更を避ける
3. **ドキュメンテーション**: 各メソッドの動作、パラメータ、戻り値、例外について詳細に記述
4. **テスタビリティ**: モックが容易に作成できるようなシンプルなインターフェース設計

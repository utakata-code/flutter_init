---
applyTo: 'lib/features/**/1_domain/3_usecases/**'
---

# Use Case Layer Instructions - ユースケース層

## 概要
ユースケースは、アプリケーションの具体的なビジネスロジックを実装する層です。エンティティとリポジトリを組み合わせて、1つの特定のビジネス操作を実行します。

## 役割と責務

### ✅ すべきこと
- **単一責任の実行**: 1つのユースケースは1つの明確なビジネス操作を担当
- **ビジネスロジックの実装**: エンティティとリポジトリを使用したワークフローの実行
- **入力検証**: ユースケース実行前の適切なバリデーション
- **エラーハンドリング**: ビジネスルールに違反した場合の適切な例外処理
- **トランザクション管理**: 複数のリポジトリ操作を含む場合の一貫性保証

### ❌ してはいけないこと
- **UIロジックの実装**: プレゼンテーション層のロジックの混入
- **データアクセスの直接実装**: リポジトリを介さない直接的なデータアクセス
- **状態管理**: UIの状態管理やライフサイクル管理
- **外部サービスへの直接依存**: HTTPクライアントやデータベースの直接使用

## 実装ガイドライン

### 1. 基本的なユースケースの実装
```dart
// usecases/get_user_usecase.dart
import '../1_entities/user_entity.dart';
import '../2_repositories/user_repository.dart';

class GetUserUseCase {
  final UserRepository _userRepository;

  GetUserUseCase(this._userRepository);

  /// ユーザーIDを指定してユーザー情報を取得する
  /// 
  /// [userId] 取得対象のユーザーID
  /// 
  /// Returns: ユーザーエンティティ
  /// 
  /// Throws:
  /// - [ArgumentException] userIdが無効な場合
  /// - [UserNotFoundException] ユーザーが見つからない場合
  Future<UserEntity> call(String userId) async {
    // 入力検証
    if (userId.isEmpty) {
      throw ArgumentException('User ID cannot be empty');
    }

    // リポジトリからユーザーを取得
    final user = await _userRepository.getUser(userId);
    
    if (user == null) {
      throw UserNotFoundException('User not found: $userId');
    }

    return user;
  }
}
```

### 2. 複合的なビジネスロジックを持つユースケース
```dart
// usecases/create_user_usecase.dart
class CreateUserUseCase {
  final UserRepository _userRepository;
  final EmailService _emailService; // ドメインサービス

  CreateUserUseCase(this._userRepository, this._emailService);

  /// 新しいユーザーを作成し、ウェルカムメールを送信する
  Future<UserEntity> call(CreateUserParams params) async {
    // 1. 入力検証
    _validateParams(params);

    // 2. ビジネスルール検証
    await _validateBusinessRules(params);

    // 3. ユーザーエンティティの作成
    final newUser = UserEntity.create(
      name: params.name,
      email: params.email,
      role: params.role ?? UserRole.user,
    );

    // 4. バリデーション
    if (!newUser.isValid) {
      throw ValidationException('Invalid user data');
    }

    // 5. ユーザーの永続化
    final savedUser = await _userRepository.createUser(newUser);

    // 6. ウェルカムメール送信（副作用）
    await _emailService.sendWelcomeEmail(savedUser.email);

    return savedUser;
  }

  void _validateParams(CreateUserParams params) {
    if (params.name.isEmpty) {
      throw ArgumentException('Name is required');
    }
    if (params.email.isEmpty) {
      throw ArgumentException('Email is required');
    }
  }

  Future<void> _validateBusinessRules(CreateUserParams params) async {
    // メールアドレスの重複チェック
    final existingUser = await _userRepository.findByEmail(params.email);
    if (existingUser != null) {
      throw ConflictException('Email already exists: ${params.email}');
    }
  }
}

// パラメータクラス
@freezed
class CreateUserParams with _$CreateUserParams {
  const factory CreateUserParams({
    required String name,
    required String email,
    UserRole? role,
  }) = _CreateUserParams;
}
```

### 3. トランザクションを伴うユースケース
```dart
// usecases/transfer_funds_usecase.dart
class TransferFundsUseCase {
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;

  TransferFundsUseCase(this._accountRepository, this._transactionRepository);

  /// 口座間で資金移動を実行する
  Future<TransactionEntity> call(TransferFundsParams params) async {
    // 入力検証
    _validateParams(params);

    // トランザクション内で実行
    return await _accountRepository.transaction(() async {
      // 1. 送金元口座の取得と検証
      final fromAccount = await _accountRepository.getAccount(params.fromAccountId);
      if (fromAccount == null) {
        throw AccountNotFoundException('From account not found');
      }

      // 2. 送金先口座の取得と検証
      final toAccount = await _accountRepository.getAccount(params.toAccountId);
      if (toAccount == null) {
        throw AccountNotFoundException('To account not found');
      }

      // 3. ビジネスルール検証
      if (!fromAccount.canWithdraw(params.amount)) {
        throw InsufficientFundsException('Insufficient balance');
      }

      // 4. 口座残高の更新
      final updatedFromAccount = fromAccount.withdraw(params.amount);
      final updatedToAccount = toAccount.deposit(params.amount);

      await _accountRepository.updateAccount(updatedFromAccount);
      await _accountRepository.updateAccount(updatedToAccount);

      // 5. 取引履歴の記録
      final transaction = TransactionEntity.create(
        fromAccountId: params.fromAccountId,
        toAccountId: params.toAccountId,
        amount: params.amount,
        type: TransactionType.transfer,
      );

      return await _transactionRepository.createTransaction(transaction);
    });
  }

  void _validateParams(TransferFundsParams params) {
    if (params.amount <= 0) {
      throw ArgumentException('Amount must be positive');
    }
    if (params.fromAccountId == params.toAccountId) {
      throw ArgumentException('Cannot transfer to the same account');
    }
  }
}
```

### 4. 検索・フィルタリングのユースケース
```dart
// usecases/search_products_usecase.dart
class SearchProductsUseCase {
  final ProductRepository _productRepository;

  SearchProductsUseCase(this._productRepository);

  /// 商品を検索する
  Future<PaginatedResult<ProductEntity>> call(SearchProductsParams params) async {
    // 入力検証
    _validateParams(params);

    // デフォルト値の設定
    final searchParams = params.copyWith(
      limit: params.limit ?? 20,
      offset: params.offset ?? 0,
    );

    // 検索実行
    return await _productRepository.searchProducts(
      keyword: searchParams.keyword,
      categoryId: searchParams.categoryId,
      minPrice: searchParams.minPrice,
      maxPrice: searchParams.maxPrice,
      status: searchParams.status,
      limit: searchParams.limit!,
      offset: searchParams.offset!,
    );
  }

  void _validateParams(SearchProductsParams params) {
    if (params.limit != null && params.limit! <= 0) {
      throw ArgumentException('Limit must be positive');
    }
    if (params.offset != null && params.offset! < 0) {
      throw ArgumentException('Offset must be non-negative');
    }
    if (params.minPrice != null && params.minPrice! < 0) {
      throw ArgumentException('Min price must be non-negative');
    }
    if (params.maxPrice != null && params.maxPrice! < 0) {
      throw ArgumentException('Max price must be non-negative');
    }
    if (params.minPrice != null && 
        params.maxPrice != null && 
        params.minPrice! > params.maxPrice!) {
      throw ArgumentException('Min price cannot be greater than max price');
    }
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{動詞}_{対象名}_usecase.dart`
- **例**: `get_user_usecase.dart`, `create_product_usecase.dart`, `update_order_usecase.dart`

### クラス名
- **命名形式**: `{動詞}{対象名}UseCase`
- **例**: `GetUserUseCase`, `CreateProductUseCase`, `UpdateOrderUseCase`

### メソッド名
- **実行メソッド**: `call()` または `execute()`
- **バリデーション**: `_validate{対象}()`, `_validateParams()`
- **ビジネスルール**: `_check{ルール名}()`, `_ensure{条件}()`

## ベストプラクティス

### 1. パラメータオブジェクトの使用
```dart
// ✅ Good: パラメータオブジェクトを使用
@freezed
class UpdateUserParams with _$UpdateUserParams {
  const factory UpdateUserParams({
    required String userId,
    String? name,
    String? email,
    UserRole? role,
  }) = _UpdateUserParams;
}

class UpdateUserUseCase {
  Future<UserEntity> call(UpdateUserParams params) async {
    // 実装
  }
}

// ❌ Bad: 多数のパラメータを直接受け取る
class UpdateUserUseCase {
  Future<UserEntity> call(
    String userId, 
    String? name, 
    String? email, 
    UserRole? role,
  ) async {
    // 実装
  }
}
```

### 2. 例外処理の統一
```dart
// shared/exceptions/domain_exceptions.dart
abstract class DomainException implements Exception {
  String get message;
}

class ArgumentException extends DomainException {
  @override
  final String message;
  ArgumentException(this.message);
}

class BusinessRuleViolationException extends DomainException {
  @override
  final String message;
  BusinessRuleViolationException(this.message);
}

class NotFoundException extends DomainException {
  @override
  final String message;
  NotFoundException(this.message);
}
```

### 3. ログ出力（必要に応じて）
```dart
class CreateUserUseCase {
  final UserRepository _userRepository;
  final Logger _logger;

  CreateUserUseCase(this._userRepository, this._logger);

  Future<UserEntity> call(CreateUserParams params) async {
    _logger.info('Creating user: ${params.email}');
    
    try {
      final user = await _createUser(params);
      _logger.info('User created successfully: ${user.id}');
      return user;
    } catch (e) {
      _logger.error('Failed to create user: ${params.email}', error: e);
      rethrow;
    }
  }
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:async';

// ✅ 同一層内の他のコンポーネント
import '../1_entities/user_entity.dart';
import '../2_repositories/user_repository.dart';

// ✅ 共通の例外クラス
import '../exceptions/domain_exceptions.dart';

// ✅ ドメインサービス
import '../services/email_service.dart';

// ✅ 値オブジェクト
import '../value_objects/money.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ 状態管理
import 'package:riverpod/riverpod.dart';

// ❌ インフラ層への依存
import '../../2_infrastructure/models/user_model.dart';

// ❌ アプリケーション層への依存
import '../../3_application/states/user_state.dart';

// ❌ プレゼンテーション層への依存
import '../../4_presentation/pages/user_page.dart';
```

## テスト指針

### 1. ユニットテストの作成
```dart
// test/domain/usecases/get_user_usecase_test.dart
void main() {
  group('GetUserUseCase', () {
    late MockUserRepository mockRepository;
    late GetUserUseCase useCase;

    setUp(() {
      mockRepository = MockUserRepository();
      useCase = GetUserUseCase(mockRepository);
    });

    test('should return user when repository returns valid user', () async {
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
      final result = await useCase.call(userId);

      // Then
      expect(result, expectedUser);
      verify(() => mockRepository.getUser(userId)).called(1);
    });

    test('should throw ArgumentException when userId is empty', () async {
      // When & Then
      expect(
        () => useCase.call(''),
        throwsA(isA<ArgumentException>()),
      );
    });

    test('should throw UserNotFoundException when user is not found', () async {
      // Given
      const userId = 'nonexistent';
      
      when(() => mockRepository.getUser(userId))
          .thenAnswer((_) async => null);

      // When & Then
      expect(
        () => useCase.call(userId),
        throwsA(isA<UserNotFoundException>()),
      );
    });
  });
}
```

## 注意事項

1. **単一責任の原則**: 1つのユースケースは1つの明確なビジネス操作のみを担当
2. **副作用の管理**: 外部システムへの影響（メール送信、通知など）は明確に識別し適切に処理
3. **エラーハンドリング**: ビジネスルールに基づいた適切な例外処理の実装
4. **テスタビリティ**: 依存関係注入により容易にモック化できる設計
5. **ドキュメンテーション**: 複雑なビジネスロジックには詳細なコメントを記述

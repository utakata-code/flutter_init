---
applyTo: 'lib/features/**/1_domain/exceptions/**'
---

# Domain Exception Layer Instructions - ドメイン例外層

## 概要
ドメイン例外層は、ビジネスロジックに関連する例外を定義します。ドメイン固有のエラー状況やビジネスルール違反を表現する例外クラスを実装します。

## 役割と責務

### ✅ すべきこと
- **ビジネス例外の定義**: ドメイン固有のエラー状況を表現
- **ビジネスルール違反の表現**: ドメインルールに反する状況の例外化
- **意味のあるエラーメッセージ**: ビジネス観点での分かりやすいメッセージ
- **例外の階層化**: 関連する例外の適切な継承関係
- **純粋なDartコード**: 外部ライブラリに依存しない実装

### ❌ してはいけないこと
- **インフラ固有の例外**: データベースやネットワークエラーの直接的な表現
- **UIフレームワークへの依存**: Flutterウィジェットのimport禁止
- **技術的詳細の露出**: 実装詳細に依存したエラーメッセージ
- **状態管理ライブラリへの依存**: Riverpodなどのimport禁止

## 実装ガイドライン

### 1. 基底例外クラス
```dart
// domain_exception.dart
abstract class DomainException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const DomainException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'DomainException: $message';
}
```

### 2. 具体的なドメイン例外
```dart
// user_domain_exceptions.dart
class UserNotFoundException extends DomainException {
  const UserNotFoundException(String userId) 
    : super('ユーザーが見つかりません: $userId', code: 'USER_NOT_FOUND');
}

class InvalidUserDataException extends DomainException {
  const InvalidUserDataException(String reason) 
    : super('無効なユーザーデータ: $reason', code: 'INVALID_USER_DATA');
}

class UserAlreadyExistsException extends DomainException {
  const UserAlreadyExistsException(String email) 
    : super('ユーザーは既に存在します: $email', code: 'USER_ALREADY_EXISTS');
}

class UserPermissionDeniedException extends DomainException {
  const UserPermissionDeniedException(String action) 
    : super('権限がありません: $action', code: 'PERMISSION_DENIED');
}
```

### 3. ビジネスルール例外
```dart
// business_rule_exceptions.dart
class BusinessRuleViolationException extends DomainException {
  const BusinessRuleViolationException(String rule) 
    : super('ビジネスルール違反: $rule', code: 'BUSINESS_RULE_VIOLATION');
}

class InvalidOperationException extends DomainException {
  const InvalidOperationException(String operation, String reason) 
    : super('無効な操作: $operation - $reason', code: 'INVALID_OPERATION');
}

class ResourceLimitExceededException extends DomainException {
  const ResourceLimitExceededException(String resource, int limit) 
    : super('リソース制限を超過: $resource (制限: $limit)', code: 'RESOURCE_LIMIT_EXCEEDED');
}
```

### 4. バリデーション例外
```dart
// validation_exceptions.dart
class ValidationException extends DomainException {
  final Map<String, List<String>> fieldErrors;
  
  const ValidationException(String message, this.fieldErrors, {String? code}) 
    : super(message, code: code ?? 'VALIDATION_ERROR');
  
  factory ValidationException.singleField(String field, String error) {
    return ValidationException(
      'バリデーションエラー: $field',
      {field: [error]},
    );
  }
  
  factory ValidationException.multipleFields(Map<String, List<String>> errors) {
    return ValidationException(
      '複数のバリデーションエラーが発生しました',
      errors,
    );
  }
}

class RequiredFieldException extends ValidationException {
  RequiredFieldException(String fieldName) 
    : super(
        '必須フィールドが入力されていません: $fieldName',
        {fieldName: ['必須フィールドです']},
        code: 'REQUIRED_FIELD',
      );
}

class InvalidFormatException extends ValidationException {
  InvalidFormatException(String fieldName, String expectedFormat) 
    : super(
        '形式が正しくありません: $fieldName (期待される形式: $expectedFormat)',
        {fieldName: ['形式が正しくありません']},
        code: 'INVALID_FORMAT',
      );
}
```

## 命名規則

### ファイル名
- **パターン**: `{domain_name}_domain_exceptions.dart`
- **例**: `user_domain_exceptions.dart`, `order_domain_exceptions.dart`

### クラス名
- **パターン**: `{具体的な状況}Exception`
- **例**: `UserNotFoundException`, `InvalidEmailFormatException`

### エラーコード
- **パターン**: `UPPER_SNAKE_CASE`
- **例**: `USER_NOT_FOUND`, `INVALID_EMAIL_FORMAT`

## ベストプラクティス

### 1. 意味のあるメッセージ
```dart
// ❌ 悪い例
class UserException extends DomainException {
  const UserException() : super('エラーが発生しました');
}

// ✅ 良い例
class UserNotFoundException extends DomainException {
  const UserNotFoundException(String userId) 
    : super('指定されたユーザー（ID: $userId）が見つかりません', code: 'USER_NOT_FOUND');
}
```

### 2. 適切な階層化
```dart
// 基底クラス
abstract class UserDomainException extends DomainException {
  const UserDomainException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

// 具体的な例外
class UserNotFoundException extends UserDomainException {
  const UserNotFoundException(String userId) 
    : super('ユーザーが見つかりません: $userId', code: 'USER_NOT_FOUND');
}

class UserValidationException extends UserDomainException {
  const UserValidationException(String message) 
    : super(message, code: 'USER_VALIDATION_ERROR');
}
```

### 3. コンテキスト情報の提供
```dart
class InsufficientBalanceException extends DomainException {
  final double currentBalance;
  final double requiredAmount;
  
  const InsufficientBalanceException({
    required this.currentBalance,
    required this.requiredAmount,
  }) : super(
    '残高不足です。現在の残高: $currentBalance, 必要な金額: $requiredAmount',
    code: 'INSUFFICIENT_BALANCE',
  );
}
```

## 許可されるimport

```dart
// ✅ 許可されるimport
import 'dart:core';           // 標準ライブラリ
import 'package:meta/meta.dart'; // メタアノテーション

// 同一ドメイン内の他の例外
import 'base_domain_exception.dart';
import '../1_entities/user_entity.dart'; // エンティティ（必要な場合のみ）
```

## 禁止されるimport

```dart
// ❌ 禁止されるimport
import 'package:flutter/material.dart';     // UIフレームワーク
import 'package:dio/dio.dart';              // HTTP通信
import 'package:drift/drift.dart';          // データベース
import 'package:riverpod/riverpod.dart';    // 状態管理
import '../../2_infrastructure/**';         // インフラ層
import '../../3_application/**';            // アプリケーション層
import '../../4_presentation/**';           // プレゼンテーション層
```

## テスト指針

### 1. 例外メッセージのテスト
```dart
// test/domain/exceptions/user_domain_exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/features/user/1_domain/exceptions/user_domain_exceptions.dart';

void main() {
  group('UserNotFoundException', () {
    test('should create exception with correct message and code', () {
      // Arrange
      const userId = 'user123';
      
      // Act
      const exception = UserNotFoundException(userId);
      
      // Assert
      expect(exception.message, 'ユーザーが見つかりません: user123');
      expect(exception.code, 'USER_NOT_FOUND');
    });
  });
}
```

### 2. バリデーション例外のテスト
```dart
group('ValidationException', () {
  test('should create single field validation exception', () {
    // Act
    final exception = ValidationException.singleField('email', 'メールアドレスの形式が正しくありません');
    
    // Assert
    expect(exception.fieldErrors['email'], ['メールアドレスの形式が正しくありません']);
    expect(exception.code, 'VALIDATION_ERROR');
  });
});
```

## 注意事項

### パフォーマンス
- 例外生成のコストを考慮し、頻繁に発生する可能性がある場合は設計を見直す
- スタックトレースの生成コストを意識する

### エラーハンドリング
- 例外は例外的な状況でのみ使用し、通常の制御フローには使用しない
- 適切なレベルで例外をキャッチし、必要に応じて変換する

### メッセージの国際化
- 将来的な国際化を考慮し、エラーコードベースでのメッセージ管理を検討
- ユーザー向けメッセージと開発者向けメッセージを分離する

### セキュリティ
- 例外メッセージに機密情報を含めない
- ログ出力時の情報漏洩に注意する
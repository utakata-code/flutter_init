---
applyTo: 'lib/features/**/2_infrastructure/2_data_sources/1_local/exceptions/**'
---

# Local Data Source Exception Layer Instructions - ローカルデータソース例外層

## 概要
ローカルデータソース例外層は、Driftデータベースやローカルストレージに関連する例外を定義します。データベース操作、ファイルI/O、ローカルキャッシュなどで発生する技術的なエラーを適切に表現し、上位層への例外変換を支援します。

## 役割と責務

### ✅ すべきこと
- **Drift例外の定義**: データベース操作に関連する例外の実装
- **ローカルストレージ例外**: ファイルI/Oやキャッシュエラーの表現
- **技術的詳細の保持**: デバッグに必要な技術情報の保存
- **上位層への変換支援**: Repository層での例外変換を容易にする情報提供
- **原因例外の保持**: 元の例外情報の適切な保存

### ❌ してはいけないこと
- **ビジネスロジックの混入**: ドメイン固有の判断やルールの実装
- **UIフレームワークへの依存**: Flutterウィジェットのimport禁止
- **リモートAPI例外の定義**: ネットワーク関連例外はremote層で定義
- **状態管理への依存**: Riverpodなどの状態管理ライブラリの使用禁止

## 実装ガイドライン

### 1. 基底例外クラス
```dart
// local_data_source_exception.dart
abstract class LocalDataSourceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const LocalDataSourceException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => 'LocalDataSourceException: $message';
}
```

### 2. Drift関連例外
```dart
// drift_exceptions.dart
import 'package:drift/drift.dart';
import 'local_data_source_exception.dart';

class DriftDatabaseException extends LocalDataSourceException {
  final String? tableName;
  final String? operation;
  
  const DriftDatabaseException(
    String message, {
    this.tableName,
    this.operation,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
  
  factory DriftDatabaseException.fromSqliteException(
    SqliteException sqliteException, {
    String? tableName,
    String? operation,
  }) {
    return DriftDatabaseException(
      'データベースエラー: ${sqliteException.message}',
      tableName: tableName,
      operation: operation,
      code: 'SQLITE_ERROR_${sqliteException.extendedResultCode}',
      originalError: sqliteException,
    );
  }
}

class DriftConnectionException extends LocalDataSourceException {
  const DriftConnectionException(String message, {dynamic originalError}) 
    : super(
        message,
        code: 'DATABASE_CONNECTION_ERROR',
        originalError: originalError,
      );
}

class DriftMigrationException extends LocalDataSourceException {
  final int fromVersion;
  final int toVersion;
  
  const DriftMigrationException(
    String message, {
    required this.fromVersion,
    required this.toVersion,
    dynamic originalError,
  }) : super(
    message,
    code: 'DATABASE_MIGRATION_ERROR',
    originalError: originalError,
  );
}

class DriftTransactionException extends LocalDataSourceException {
  const DriftTransactionException(String message, {dynamic originalError}) 
    : super(
        message,
        code: 'DATABASE_TRANSACTION_ERROR',
        originalError: originalError,
      );
}
```

### 3. CRUD操作例外
```dart
// crud_exceptions.dart
class RecordNotFoundException extends LocalDataSourceException {
  final String tableName;
  final Map<String, dynamic> searchCriteria;
  
  const RecordNotFoundException(
    this.tableName,
    this.searchCriteria,
  ) : super(
    'レコードが見つかりません: テーブル=$tableName, 検索条件=$searchCriteria',
    code: 'RECORD_NOT_FOUND',
  );
}

class RecordInsertException extends LocalDataSourceException {
  final String tableName;
  final Map<String, dynamic> data;
  
  const RecordInsertException(
    this.tableName,
    this.data, {
    dynamic originalError,
  }) : super(
    'レコードの挿入に失敗しました: テーブル=$tableName',
    code: 'RECORD_INSERT_ERROR',
    originalError: originalError,
  );
}

class RecordUpdateException extends LocalDataSourceException {
  final String tableName;
  final Map<String, dynamic> data;
  final Map<String, dynamic> whereClause;
  
  const RecordUpdateException(
    this.tableName,
    this.data,
    this.whereClause, {
    dynamic originalError,
  }) : super(
    'レコードの更新に失敗しました: テーブル=$tableName',
    code: 'RECORD_UPDATE_ERROR',
    originalError: originalError,
  );
}

class RecordDeleteException extends LocalDataSourceException {
  final String tableName;
  final Map<String, dynamic> whereClause;
  
  const RecordDeleteException(
    this.tableName,
    this.whereClause, {
    dynamic originalError,
  }) : super(
    'レコードの削除に失敗しました: テーブル=$tableName',
    code: 'RECORD_DELETE_ERROR',
    originalError: originalError,
  );
}
```

### 4. ファイルストレージ例外
```dart
// file_storage_exceptions.dart
import 'dart:io';
import 'local_data_source_exception.dart';

class FileStorageException extends LocalDataSourceException {
  final String? filePath;
  final String? operation;
  
  const FileStorageException(
    String message, {
    this.filePath,
    this.operation,
    String? code,
    dynamic originalError,
  }) : super(
    message,
    code: code,
    originalError: originalError,
  );
}

class FileNotFoundException extends FileStorageException {
  const FileNotFoundException(String filePath) 
    : super(
        'ファイルが見つかりません: $filePath',
        filePath: filePath,
        operation: 'READ',
        code: 'FILE_NOT_FOUND',
      );
}

class FileWriteException extends FileStorageException {
  const FileWriteException(String filePath, {dynamic originalError}) 
    : super(
        'ファイルの書き込みに失敗しました: $filePath',
        filePath: filePath,
        operation: 'WRITE',
        code: 'FILE_WRITE_ERROR',
        originalError: originalError,
      );
}

class FileReadException extends FileStorageException {
  const FileReadException(String filePath, {dynamic originalError}) 
    : super(
        'ファイルの読み込みに失敗しました: $filePath',
        filePath: filePath,
        operation: 'READ',
        code: 'FILE_READ_ERROR',
        originalError: originalError,
      );
}

class DirectoryCreationException extends FileStorageException {
  const DirectoryCreationException(String directoryPath, {dynamic originalError}) 
    : super(
        'ディレクトリの作成に失敗しました: $directoryPath',
        filePath: directoryPath,
        operation: 'CREATE_DIRECTORY',
        code: 'DIRECTORY_CREATION_ERROR',
        originalError: originalError,
      );
}
```

### 5. キャッシュ例外
```dart
// cache_exceptions.dart
class CacheException extends LocalDataSourceException {
  final String? cacheKey;
  final String? operation;
  
  const CacheException(
    String message, {
    this.cacheKey,
    this.operation,
    String? code,
    dynamic originalError,
  }) : super(
    message,
    code: code,
    originalError: originalError,
  );
}

class CacheKeyNotFoundException extends CacheException {
  const CacheKeyNotFoundException(String cacheKey) 
    : super(
        'キャッシュキーが見つかりません: $cacheKey',
        cacheKey: cacheKey,
        operation: 'GET',
        code: 'CACHE_KEY_NOT_FOUND',
      );
}

class CacheWriteException extends CacheException {
  const CacheWriteException(String cacheKey, {dynamic originalError}) 
    : super(
        'キャッシュの書き込みに失敗しました: $cacheKey',
        cacheKey: cacheKey,
        operation: 'SET',
        code: 'CACHE_WRITE_ERROR',
        originalError: originalError,
      );
}

class CacheExpiredException extends CacheException {
  final DateTime expiredAt;
  
  const CacheExpiredException(String cacheKey, this.expiredAt) 
    : super(
        'キャッシュが期限切れです: $cacheKey (期限: $expiredAt)',
        cacheKey: cacheKey,
        operation: 'GET',
        code: 'CACHE_EXPIRED',
      );
}

class CacheSizeExceededException extends CacheException {
  final int currentSize;
  final int maxSize;
  
  const CacheSizeExceededException({
    required this.currentSize,
    required this.maxSize,
  }) : super(
        'キャッシュサイズが上限を超過しました: $currentSize/$maxSize',
        operation: 'SET',
        code: 'CACHE_SIZE_EXCEEDED',
      );
}
```

### 6. データ変換例外
```dart
// data_conversion_exceptions.dart
class DataConversionException extends LocalDataSourceException {
  final String sourceType;
  final String targetType;
  final dynamic sourceData;
  
  const DataConversionException(
    String message, {
    required this.sourceType,
    required this.targetType,
    this.sourceData,
    dynamic originalError,
  }) : super(
    message,
    code: 'DATA_CONVERSION_ERROR',
    originalError: originalError,
  );
}

class JsonParsingException extends DataConversionException {
  const JsonParsingException(String jsonString, {dynamic originalError}) 
    : super(
        'JSONの解析に失敗しました',
        sourceType: 'String',
        targetType: 'Map<String, dynamic>',
        sourceData: jsonString,
        originalError: originalError,
      );
}

class ModelMappingException extends DataConversionException {
  final String modelName;
  
  const ModelMappingException(
    this.modelName,
    Map<String, dynamic> sourceData, {
    dynamic originalError,
  }) : super(
        'モデルへのマッピングに失敗しました: $modelName',
        sourceType: 'Map<String, dynamic>',
        targetType: modelName,
        sourceData: sourceData,
        originalError: originalError,
      );
}
```

## 例外変換パターン

### Repository層での使用例
```dart
// user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;
  
  @override
  Future<User> getUserById(String id) async {
    try {
      final userModel = await _localDataSource.getUserById(id);
      return userModel.toEntity();
    } on RecordNotFoundException catch (e) {
      // ローカル例外をドメイン例外に変換
      throw UserNotFoundException(id);
    } on DriftDatabaseException catch (e) {
      // データベース例外をストレージ例外に変換
      throw StorageException(
        'ユーザー情報の取得に失敗しました',
        originalError: e,
      );
    } on DataConversionException catch (e) {
      // データ変換例外をドメイン例外に変換
      throw InvalidUserDataException(
        'ユーザーデータの形式が正しくありません',
      );
    }
  }
}
```

## 命名規則

### ファイル名
- **パターン**: `{機能名}_exceptions.dart`
- **例**: `drift_exceptions.dart`, `file_storage_exceptions.dart`

### クラス名
- **パターン**: `{具体的な状況}Exception`
- **例**: `DriftDatabaseException`, `FileNotFoundException`

### エラーコード
- **パターン**: `UPPER_SNAKE_CASE`
- **例**: `DATABASE_CONNECTION_ERROR`, `FILE_NOT_FOUND`

## 許可されるimport

```dart
// ✅ 許可されるimport
import 'dart:core';                    // 標準ライブラリ
import 'dart:io';                      // ファイルI/O
import 'dart:convert';                 // JSON変換
import 'package:drift/drift.dart';     // Driftデータベース
import 'package:meta/meta.dart';       // メタアノテーション
import 'package:path/path.dart';       // パス操作

// 同一層内の他の例外
import 'local_data_source_exception.dart';

// モデル（必要な場合のみ）
import '../../../1_models/user_model.dart';
```

## 禁止されるimport

```dart
// ❌ 禁止されるimport
import 'package:flutter/material.dart';     // UIフレームワーク
import 'package:dio/dio.dart';              // HTTP通信（remote層で使用）
import 'package:riverpod/riverpod.dart';    // 状態管理
import '../../../1_domain/**';              // ドメイン層
import '../../../3_application/**';         // アプリケーション層
import '../../../4_presentation/**';        // プレゼンテーション層
import '../2_remote/**';                    // リモートデータソース
```

## ベストプラクティス

### 1. 原因例外の保持
```dart
// ✅ 良い例
try {
  await database.insert(users).insert(userCompanion);
} on SqliteException catch (e, stackTrace) {
  throw DriftDatabaseException.fromSqliteException(
    e,
    tableName: 'users',
    operation: 'INSERT',
  );
}

// ❌ 悪い例
try {
  await database.insert(users).insert(userCompanion);
} catch (e) {
  throw DriftDatabaseException('データベースエラーが発生しました');
}
```

### 2. 適切なコンテキスト情報
```dart
// ✅ 良い例
class RecordNotFoundException extends LocalDataSourceException {
  final String tableName;
  final Map<String, dynamic> searchCriteria;
  
  const RecordNotFoundException(
    this.tableName,
    this.searchCriteria,
  ) : super(
    'レコードが見つかりません: テーブル=$tableName, 検索条件=$searchCriteria',
    code: 'RECORD_NOT_FOUND',
  );
}

// ❌ 悪い例
class RecordNotFoundException extends LocalDataSourceException {
  const RecordNotFoundException() 
    : super('レコードが見つかりません');
}
```

### 3. ファクトリーコンストラクタの活用
```dart
class DriftDatabaseException extends LocalDataSourceException {
  // 通常のコンストラクタ
  const DriftDatabaseException(String message, {/* ... */});
  
  // SQLite例外からの変換用ファクトリー
  factory DriftDatabaseException.fromSqliteException(
    SqliteException sqliteException, {
    String? tableName,
    String? operation,
  }) {
    return DriftDatabaseException(
      'データベースエラー: ${sqliteException.message}',
      tableName: tableName,
      operation: operation,
      code: 'SQLITE_ERROR_${sqliteException.extendedResultCode}',
      originalError: sqliteException,
    );
  }
}
```

## テスト指針

### 1. 例外生成のテスト
```dart
// test/infrastructure/data_sources/local/exceptions/drift_exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

void main() {
  group('DriftDatabaseException', () {
    test('should create from SqliteException with correct information', () {
      // Arrange
      final sqliteException = SqliteException(19, 'CONSTRAINT failed');
      
      // Act
      final exception = DriftDatabaseException.fromSqliteException(
        sqliteException,
        tableName: 'users',
        operation: 'INSERT',
      );
      
      // Assert
      expect(exception.message, contains('CONSTRAINT failed'));
      expect(exception.tableName, 'users');
      expect(exception.operation, 'INSERT');
      expect(exception.originalError, sqliteException);
    });
  });
}
```

### 2. 例外変換のテスト
```dart
group('Exception conversion', () {
  test('should convert SqliteException to DriftDatabaseException', () {
    // Arrange
    final sqliteException = SqliteException(19, 'CONSTRAINT failed');
    
    // Act & Assert
    expect(
      () => throw DriftDatabaseException.fromSqliteException(sqliteException),
      throwsA(isA<DriftDatabaseException>()),
    );
  });
});
```

## 注意事項

### パフォーマンス
- 例外生成時のスタックトレース取得コストを考慮
- 大量のデータ処理時の例外頻度に注意

### デバッグ支援
- 技術的詳細を適切に保持し、デバッグを容易にする
- ログ出力時に必要な情報を提供

### セキュリティ
- データベースの内部構造を例外メッセージで露出しない
- 機密データを例外情報に含めない

### メモリ管理
- 原因例外の循環参照に注意
- 大きなデータオブジェクトの保持を避ける
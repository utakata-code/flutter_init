---
applyTo: 'lib/features/**/2_infrastructure/2_data_sources/2_remote/exceptions/**'
---

# Remote Data Source Exception Layer Instructions - リモートデータソース例外層

## 概要
リモートデータソース例外層は、HTTP通信、API呼び出し、ネットワーク関連の例外を定義します。REST API、GraphQL、WebSocketなどの外部通信で発生する技術的なエラーを適切に表現し、上位層への例外変換を支援します。

## 役割と責務

### ✅ すべきこと
- **HTTP例外の定義**: ステータスコード別の例外実装
- **ネットワーク例外**: 接続エラー、タイムアウトなどの表現
- **API応答例外**: レスポンス形式エラーやパースエラーの処理
- **認証・認可例外**: トークンエラーや権限不足の表現
- **技術的詳細の保持**: デバッグに必要な通信情報の保存
- **上位層への変換支援**: Repository層での例外変換を容易にする情報提供

### ❌ してはいけないこと
- **ビジネスロジックの混入**: ドメイン固有の判断やルールの実装
- **UIフレームワークへの依存**: Flutterウィジェットのimport禁止
- **ローカルストレージ例外の定義**: データベース関連例外はlocal層で定義
- **状態管理への依存**: Riverpodなどの状態管理ライブラリの使用禁止

## 実装ガイドライン

### 1. 基底例外クラス
```dart
// remote_data_source_exception.dart
abstract class RemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  
  const RemoteDataSourceException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
    this.requestData,
    this.responseData,
  });
  
  @override
  String toString() => 'RemoteDataSourceException: $message';
}
```

### 2. HTTP例外
```dart
// http_exceptions.dart
import 'package:dio/dio.dart';
import 'remote_data_source_exception.dart';

class HttpException extends RemoteDataSourceException {
  final int? statusCode;
  final String? method;
  final String? url;
  final Map<String, dynamic>? headers;
  
  const HttpException(
    String message, {
    this.statusCode,
    this.method,
    this.url,
    this.headers,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) : super(
    message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
    requestData: requestData,
    responseData: responseData,
  );
  
  factory HttpException.fromDioException(DioException dioException) {
    final response = dioException.response;
    final request = dioException.requestOptions;
    
    return HttpException(
      _getMessageFromDioException(dioException),
      statusCode: response?.statusCode,
      method: request.method,
      url: request.uri.toString(),
      headers: request.headers,
      code: _getCodeFromDioException(dioException),
      originalError: dioException,
      requestData: request.data is Map<String, dynamic> ? request.data : null,
      responseData: response?.data is Map<String, dynamic> ? response?.data : null,
    );
  }
  
  static String _getMessageFromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return '接続がタイムアウトしました';
      case DioExceptionType.sendTimeout:
        return '送信がタイムアウトしました';
      case DioExceptionType.receiveTimeout:
        return '受信がタイムアウトしました';
      case DioExceptionType.badResponse:
        return 'サーバーエラーが発生しました (${dioException.response?.statusCode})';
      case DioExceptionType.cancel:
        return 'リクエストがキャンセルされました';
      case DioExceptionType.connectionError:
        return 'ネットワーク接続エラーが発生しました';
      case DioExceptionType.badCertificate:
        return 'SSL証明書エラーが発生しました';
      case DioExceptionType.unknown:
      default:
        return '不明なネットワークエラーが発生しました';
    }
  }
  
  static String _getCodeFromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case DioExceptionType.sendTimeout:
        return 'SEND_TIMEOUT';
      case DioExceptionType.receiveTimeout:
        return 'RECEIVE_TIMEOUT';
      case DioExceptionType.badResponse:
        return 'HTTP_${dioException.response?.statusCode ?? "UNKNOWN"}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      case DioExceptionType.connectionError:
        return 'CONNECTION_ERROR';
      case DioExceptionType.badCertificate:
        return 'BAD_CERTIFICATE';
      case DioExceptionType.unknown:
      default:
        return 'UNKNOWN_ERROR';
    }
  }
}

// 具体的なHTTPステータスコード例外
class BadRequestException extends HttpException {
  const BadRequestException(String message, {Map<String, dynamic>? responseData}) 
    : super(
        message,
        statusCode: 400,
        code: 'BAD_REQUEST',
        responseData: responseData,
      );
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException(String message) 
    : super(
        message,
        statusCode: 401,
        code: 'UNAUTHORIZED',
      );
}

class ForbiddenException extends HttpException {
  const ForbiddenException(String message) 
    : super(
        message,
        statusCode: 403,
        code: 'FORBIDDEN',
      );
}

class NotFoundException extends HttpException {
  const NotFoundException(String message) 
    : super(
        message,
        statusCode: 404,
        code: 'NOT_FOUND',
      );
}

class InternalServerErrorException extends HttpException {
  const InternalServerErrorException(String message) 
    : super(
        message,
        statusCode: 500,
        code: 'INTERNAL_SERVER_ERROR',
      );
}

class ServiceUnavailableException extends HttpException {
  const ServiceUnavailableException(String message) 
    : super(
        message,
        statusCode: 503,
        code: 'SERVICE_UNAVAILABLE',
      );
}
```

### 3. ネットワーク例外
```dart
// network_exceptions.dart
class NetworkException extends RemoteDataSourceException {
  final String? operation;
  
  const NetworkException(
    String message, {
    this.operation,
    String? code,
    dynamic originalError,
  }) : super(
    message,
    code: code,
    originalError: originalError,
  );
}

class ConnectionTimeoutException extends NetworkException {
  final Duration timeout;
  
  const ConnectionTimeoutException(this.timeout) 
    : super(
        '接続がタイムアウトしました (${timeout.inSeconds}秒)',
        operation: 'CONNECT',
        code: 'CONNECTION_TIMEOUT',
      );
}

class NoInternetConnectionException extends NetworkException {
  const NoInternetConnectionException() 
    : super(
        'インターネット接続がありません',
        operation: 'CONNECT',
        code: 'NO_INTERNET_CONNECTION',
      );
}

class DnsLookupException extends NetworkException {
  final String hostname;
  
  const DnsLookupException(this.hostname) 
    : super(
        'DNS解決に失敗しました: $hostname',
        operation: 'DNS_LOOKUP',
        code: 'DNS_LOOKUP_FAILED',
      );
}

class SslHandshakeException extends NetworkException {
  final String hostname;
  
  const SslHandshakeException(this.hostname) 
    : super(
        'SSL/TLSハンドシェイクに失敗しました: $hostname',
        operation: 'SSL_HANDSHAKE',
        code: 'SSL_HANDSHAKE_FAILED',
      );
}
```

### 4. API応答例外
```dart
// api_response_exceptions.dart
class ApiResponseException extends RemoteDataSourceException {
  final String? endpoint;
  final int? statusCode;
  
  const ApiResponseException(
    String message, {
    this.endpoint,
    this.statusCode,
    String? code,
    dynamic originalError,
    Map<String, dynamic>? responseData,
  }) : super(
    message,
    code: code,
    originalError: originalError,
    responseData: responseData,
  );
}

class InvalidResponseFormatException extends ApiResponseException {
  final String expectedFormat;
  final String actualFormat;
  
  const InvalidResponseFormatException({
    required this.expectedFormat,
    required this.actualFormat,
    String? endpoint,
    Map<String, dynamic>? responseData,
  }) : super(
    'レスポンス形式が正しくありません。期待: $expectedFormat, 実際: $actualFormat',
    endpoint: endpoint,
    code: 'INVALID_RESPONSE_FORMAT',
    responseData: responseData,
  );
}

class JsonParsingException extends ApiResponseException {
  final String rawResponse;
  
  const JsonParsingException(this.rawResponse, {dynamic originalError}) 
    : super(
        'JSONの解析に失敗しました',
        code: 'JSON_PARSING_ERROR',
        originalError: originalError,
      );
}

class MissingRequiredFieldException extends ApiResponseException {
  final List<String> missingFields;
  
  const MissingRequiredFieldException(this.missingFields, {String? endpoint}) 
    : super(
        '必須フィールドが不足しています: ${missingFields.join(", ")}',
        endpoint: endpoint,
        code: 'MISSING_REQUIRED_FIELD',
      );
}

class UnexpectedResponseStructureException extends ApiResponseException {
  const UnexpectedResponseStructureException(String message, {String? endpoint}) 
    : super(
        message,
        endpoint: endpoint,
        code: 'UNEXPECTED_RESPONSE_STRUCTURE',
      );
}
```

### 5. 認証・認可例外
```dart
// auth_exceptions.dart
class AuthException extends RemoteDataSourceException {
  final String? tokenType;
  
  const AuthException(
    String message, {
    this.tokenType,
    String? code,
    dynamic originalError,
  }) : super(
    message,
    code: code,
    originalError: originalError,
  );
}

class InvalidTokenException extends AuthException {
  const InvalidTokenException({String? tokenType}) 
    : super(
        'トークンが無効です',
        tokenType: tokenType,
        code: 'INVALID_TOKEN',
      );
}

class ExpiredTokenException extends AuthException {
  final DateTime expiredAt;
  
  const ExpiredTokenException(this.expiredAt, {String? tokenType}) 
    : super(
        'トークンが期限切れです (期限: $expiredAt)',
        tokenType: tokenType,
        code: 'EXPIRED_TOKEN',
      );
}

class RefreshTokenException extends AuthException {
  const RefreshTokenException({dynamic originalError}) 
    : super(
        'トークンの更新に失敗しました',
        tokenType: 'refresh_token',
        code: 'REFRESH_TOKEN_FAILED',
        originalError: originalError,
      );
}

class InsufficientPermissionException extends AuthException {
  final String requiredPermission;
  final List<String> userPermissions;
  
  const InsufficientPermissionException({
    required this.requiredPermission,
    required this.userPermissions,
  }) : super(
        '権限が不足しています。必要: $requiredPermission, 所有: ${userPermissions.join(", ")}',
        code: 'INSUFFICIENT_PERMISSION',
      );
}
```

### 6. レート制限例外
```dart
// rate_limit_exceptions.dart
class RateLimitException extends RemoteDataSourceException {
  final int? retryAfterSeconds;
  final int? remainingRequests;
  final DateTime? resetTime;
  
  const RateLimitException({
    this.retryAfterSeconds,
    this.remainingRequests,
    this.resetTime,
    dynamic originalError,
  }) : super(
    'レート制限に達しました${retryAfterSeconds != null ? " (${retryAfterSeconds}秒後に再試行)" : ""}',
    code: 'RATE_LIMIT_EXCEEDED',
    originalError: originalError,
  );
  
  factory RateLimitException.fromHeaders(Map<String, dynamic> headers) {
    final retryAfter = headers['retry-after'];
    final remaining = headers['x-ratelimit-remaining'];
    final reset = headers['x-ratelimit-reset'];
    
    return RateLimitException(
      retryAfterSeconds: retryAfter is String ? int.tryParse(retryAfter) : retryAfter,
      remainingRequests: remaining is String ? int.tryParse(remaining) : remaining,
      resetTime: reset is String ? DateTime.tryParse(reset) : null,
    );
  }
}
```

## 例外変換パターン

### Repository層での使用例
```dart
// user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  
  @override
  Future<User> getUserById(String id) async {
    try {
      final userModel = await _remoteDataSource.getUserById(id);
      return userModel.toEntity();
    } on NotFoundException catch (e) {
      // リモート例外をドメイン例外に変換
      throw UserNotFoundException(id);
    } on UnauthorizedException catch (e) {
      // 認証例外をドメイン例外に変換
      throw AuthenticationException('認証が必要です');
    } on HttpException catch (e) {
      // HTTP例外をネットワーク例外に変換
      throw NetworkException(
        'ユーザー情報の取得に失敗しました',
        originalError: e,
      );
    } on NetworkException catch (e) {
      // ネットワーク例外をそのまま再スロー
      rethrow;
    } on JsonParsingException catch (e) {
      // パース例外をドメイン例外に変換
      throw InvalidUserDataException(
        'ユーザーデータの形式が正しくありません',
      );
    }
  }
}
```

### データソース実装での使用例
```dart
// user_remote_data_source_impl.dart
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;
  
  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      
      if (response.data == null) {
        throw InvalidResponseFormatException(
          expectedFormat: 'JSON Object',
          actualFormat: 'null',
          endpoint: '/users/$id',
        );
      }
      
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw HttpException.fromDioException(e);
    } on FormatException catch (e) {
      throw JsonParsingException(
        e.source,
        originalError: e,
      );
    } catch (e) {
      throw ApiResponseException(
        'ユーザー情報の取得中に予期しないエラーが発生しました',
        endpoint: '/users/$id',
        originalError: e,
      );
    }
  }
}
```

## 命名規則

### ファイル名
- **パターン**: `{機能名}_exceptions.dart`
- **例**: `http_exceptions.dart`, `auth_exceptions.dart`

### クラス名
- **パターン**: `{具体的な状況}Exception`
- **例**: `HttpException`, `UnauthorizedException`

### エラーコード
- **パターン**: `UPPER_SNAKE_CASE`
- **例**: `CONNECTION_TIMEOUT`, `INVALID_TOKEN`

## 許可されるimport

```dart
// ✅ 許可されるimport
import 'dart:core';                    // 標準ライブラリ
import 'dart:io';                      // HTTP関連
import 'dart:convert';                 // JSON変換
import 'package:dio/dio.dart';         // HTTP通信
import 'package:meta/meta.dart';       // メタアノテーション

// 同一層内の他の例外
import 'remote_data_source_exception.dart';

// モデル（必要な場合のみ）
import '../../../1_models/user_model.dart';
```

## 禁止されるimport

```dart
// ❌ 禁止されるimport
import 'package:flutter/material.dart';     // UIフレームワーク
import 'package:drift/drift.dart';          // データベース（local層で使用）
import 'package:riverpod/riverpod.dart';    // 状態管理
import '../../../1_domain/**';              // ドメイン層
import '../../../3_application/**';         // アプリケーション層
import '../../../4_presentation/**';        // プレゼンテーション層
import '../1_local/**';                     // ローカルデータソース
```

## ベストプラクティス

### 1. DioExceptionからの適切な変換
```dart
// ✅ 良い例
try {
  final response = await _dio.get('/users');
  return response.data;
} on DioException catch (e) {
  throw HttpException.fromDioException(e);
}

// ❌ 悪い例
try {
  final response = await _dio.get('/users');
  return response.data;
} catch (e) {
  throw HttpException('エラーが発生しました');
}
```

### 2. レスポンスデータの保持
```dart
// ✅ 良い例
class BadRequestException extends HttpException {
  const BadRequestException(String message, {Map<String, dynamic>? responseData}) 
    : super(
        message,
        statusCode: 400,
        code: 'BAD_REQUEST',
        responseData: responseData, // レスポンスデータを保持
      );
}

// 使用例
if (response.statusCode == 400) {
  throw BadRequestException(
    'リクエストが正しくありません',
    responseData: response.data,
  );
}
```

### 3. ファクトリーコンストラクタの活用
```dart
class RateLimitException extends RemoteDataSourceException {
  // ヘッダーから情報を抽出するファクトリー
  factory RateLimitException.fromHeaders(Map<String, dynamic> headers) {
    final retryAfter = headers['retry-after'];
    final remaining = headers['x-ratelimit-remaining'];
    
    return RateLimitException(
      retryAfterSeconds: retryAfter is String ? int.tryParse(retryAfter) : retryAfter,
      remainingRequests: remaining is String ? int.tryParse(remaining) : remaining,
    );
  }
}
```

## テスト指針

### 1. HTTP例外のテスト
```dart
// test/infrastructure/data_sources/remote/exceptions/http_exceptions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('HttpException', () {
    test('should create from DioException with correct information', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      
      // Act
      final exception = HttpException.fromDioException(dioException);
      
      // Assert
      expect(exception.message, contains('タイムアウト'));
      expect(exception.code, 'CONNECTION_TIMEOUT');
      expect(exception.originalError, dioException);
    });
  });
}
```

### 2. 認証例外のテスト
```dart
group('AuthException', () {
  test('should create expired token exception with correct information', () {
    // Arrange
    final expiredAt = DateTime.now().subtract(Duration(hours: 1));
    
    // Act
    final exception = ExpiredTokenException(expiredAt, tokenType: 'access_token');
    
    // Assert
    expect(exception.message, contains('期限切れ'));
    expect(exception.code, 'EXPIRED_TOKEN');
    expect(exception.expiredAt, expiredAt);
    expect(exception.tokenType, 'access_token');
  });
});
```

## 注意事項

### パフォーマンス
- 大きなレスポンスデータの保持によるメモリ使用量に注意
- 例外生成時のスタックトレース取得コストを考慮

### セキュリティ
- 認証トークンや機密情報を例外メッセージに含めない
- ログ出力時の情報漏洩に注意
- APIキーやパスワードの露出を防ぐ

### デバッグ支援
- HTTP通信の詳細情報を適切に保持
- リクエスト・レスポンスの内容をデバッグ時に確認可能にする

### エラーハンドリング
- ネットワーク状態に応じた適切な例外選択
- リトライ可能なエラーと不可能なエラーの区別
- ユーザーフレンドリーなエラーメッセージの提供
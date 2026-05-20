---
applyTo: 'lib/features/**/2_infrastructure/2_data_sources/2_remote/**'
---

# Remote Data Source Layer Instructions - リモートデータソース層

## 概要
リモートデータソース層は、外部API、Webサービス、クラウドサービスとの通信を担当します。HTTP通信、認証、レスポンス処理、エラーハンドリングを実装し、外部データソースからの情報取得・送信を行います。

## 役割と責務

### ✅ すべきこと
- **HTTP通信**: RESTful API、GraphQL、WebSocketとの通信
- **認証処理**: API認証、トークン管理、リフレッシュ処理
- **レスポンス処理**: JSON/XMLパース、エラーレスポンス処理
- **リクエスト構築**: APIエンドポイント、ヘッダー、パラメータの構築
- **ネットワークエラー処理**: タイムアウト、接続エラー、サーバーエラーの処理

### ❌ してはいけないこと
- **ビジネスロジックの実装**: ドメインルールやビジネス判断の記述
- **UIロジックの実装**: プレゼンテーション層のロジックの混入
- **ローカルストレージアクセス**: データベースやファイルへの直接操作
- **エンティティの直接使用**: ドメインエンティティではなくモデルクラスを使用

## 実装ガイドライン

### 1. 基本的なHTTPクライアント実装
※ インターフェースと実装は必ず別ファイルに分割してください（インターフェース: `{対象名}_remote_data_source.dart`、実装: `{対象名}_remote_data_source_impl.dart`）。以下のコードは説明のため1つのブロックにまとめていますが、実際のプロジェクトでは分割して配置します。
```dart
// data_sources/remote/user_remote_data_source.dart
import 'package:dio/dio.dart';
import '../../1_models/user_model.dart';
import '../../1_models/api_error_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String id);
  Future<List<UserModel>> getUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  });
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(String id, UserModel user);
  Future<void> deleteUser(String id);
  Future<bool> userExists(String email);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  UserRemoteDataSourceImpl(this._dio, this._baseUrl);

  @override
  Future<UserModel> getUser(String id) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$id');
      
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (limit != null) queryParameters['limit'] = limit;
      if (offset != null) queryParameters['offset'] = offset;
      if (searchQuery != null) queryParameters['search'] = searchQuery;

      final response = await _dio.get(
        '$_baseUrl/users',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/users',
        data: user.toJson(),
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> updateUser(String id, UserModel user) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/$id',
        data: user.toJson(),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      final response = await _dio.delete('$_baseUrl/users/$id');

      if (response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> userExists(String email) async {
    try {
      final response = await _dio.head(
        '$_baseUrl/users/check',
        queryParameters: {'email': email},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleDioException(e);
    } catch (e) {
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  RemoteDataSourceException _handleErrorResponse(Response response) {
    try {
      final errorModel = ApiErrorModel.fromJson(response.data);
      return errorModel.toDomainException();
    } catch (e) {
      return ServerException(
        'Server error: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  RemoteDataSourceException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timeout: ${e.message}');
      
      case DioExceptionType.connectionError:
        return NetworkException('Network error: ${e.message}');
      
      case DioExceptionType.badResponse:
        if (e.response != null) {
          return _handleErrorResponse(e.response!);
        }
        return ServerException('Bad response: ${e.message}');
      
      case DioExceptionType.cancel:
        return RequestCancelledException('Request cancelled: ${e.message}');
      
      default:
        return RemoteDataSourceException('Unknown error: ${e.message}');
    }
  }
}
```

### 2. 認証付きデータソース
```dart
// data_sources/remote/authenticated_remote_data_source.dart
abstract class AuthenticatedRemoteDataSource {
  Future<void> setAuthToken(String token);
  Future<void> clearAuthToken();
  Future<String?> getAuthToken();
  Future<void> refreshAuthToken();
}

class AuthenticatedRemoteDataSourceImpl implements AuthenticatedRemoteDataSource {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final String _refreshEndpoint;

  AuthenticatedRemoteDataSourceImpl(
    this._dio,
    this._tokenStorage,
    this._refreshEndpoint,
  ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // リクエストインターセプター（認証ヘッダー自動追加）
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401エラーの場合、トークンリフレッシュを試行
          if (error.response?.statusCode == 401) {
            try {
              await refreshAuthToken();
              
              // 元のリクエストを再実行
              final token = await _tokenStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (refreshError) {
              // リフレッシュに失敗した場合は認証をクリア
              await clearAuthToken();
            }
          }
          
          handler.next(error);
        },
      ),
    );
  }

  @override
  Future<void> setAuthToken(String token) async {
    await _tokenStorage.saveAccessToken(token);
  }

  @override
  Future<void> clearAuthToken() async {
    await _tokenStorage.clearTokens();
  }

  @override
  Future<String?> getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  @override
  Future<void> refreshAuthToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw AuthenticationException('No refresh token available');
    }

    try {
      final response = await _dio.post(
        _refreshEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // 認証ヘッダーを除外
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _tokenStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _tokenStorage.saveRefreshToken(newRefreshToken);
        }
      } else {
        throw AuthenticationException('Failed to refresh token');
      }
    } on DioException catch (e) {
      throw AuthenticationException('Token refresh failed: ${e.message}');
    }
  }
}
```

### 3. GraphQLデータソース
```dart
// data_sources/remote/graphql_data_source.dart
import 'package:graphql_flutter/graphql_flutter.dart';

abstract class UserGraphQLDataSource {
  Future<UserModel> getUser(String id);
  Future<List<UserModel>> searchUsers(String query);
  Future<UserModel> createUser(CreateUserInput input);
}

class UserGraphQLDataSourceImpl implements UserGraphQLDataSource {
  final GraphQLClient _client;

  UserGraphQLDataSourceImpl(this._client);

  @override
  Future<UserModel> getUser(String id) async {
    const String query = '''
      query GetUser(\$id: ID!) {
        user(id: \$id) {
          id
          name
          email
          createdAt
          profileImageUrl
        }
      }
    ''';

    try {
      final QueryOptions options = QueryOptions(
        document: gql(query),
        variables: {'id': id},
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final userData = result.data!['user'];
      if (userData == null) {
        throw NotFoundException('User not found: $id');
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      if (e is RemoteDataSourceException) rethrow;
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    const String searchQuery = '''
      query SearchUsers(\$query: String!) {
        searchUsers(query: \$query) {
          id
          name
          email
          profileImageUrl
        }
      }
    ''';

    try {
      final QueryOptions options = QueryOptions(
        document: gql(searchQuery),
        variables: {'query': query},
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final List<dynamic> usersData = result.data!['searchUsers'];
      return usersData.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      if (e is RemoteDataSourceException) rethrow;
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> createUser(CreateUserInput input) async {
    const String mutation = '''
      mutation CreateUser(\$input: CreateUserInput!) {
        createUser(input: \$input) {
          id
          name
          email
          createdAt
        }
      }
    ''';

    try {
      final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: {'input': input.toJson()},
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final userData = result.data!['createUser'];
      return UserModel.fromJson(userData);
    } catch (e) {
      if (e is RemoteDataSourceException) rethrow;
      throw RemoteDataSourceException('Unexpected error: $e');
    }
  }

  RemoteDataSourceException _handleGraphQLException(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      final error = exception.graphqlErrors.first;
      
      switch (error.extensions?['code']) {
        case 'UNAUTHENTICATED':
          return AuthenticationException(error.message);
        case 'FORBIDDEN':
          return ForbiddenException(error.message);
        case 'NOT_FOUND':
          return NotFoundException(error.message);
        case 'VALIDATION_ERROR':
          return ValidationException(error.message);
        default:
          return ServerException(error.message);
      }
    }

    if (exception.linkException != null) {
      return NetworkException(exception.linkException.toString());
    }

    return RemoteDataSourceException('GraphQL error: ${exception.toString()}');
  }
}
```

### 4. WebSocketデータソース
```dart
// data_sources/remote/websocket_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class ChatWebSocketDataSource {
  Stream<MessageModel> get messageStream;
  Future<void> connect(String url);
  Future<void> disconnect();
  Future<void> sendMessage(SendMessageModel message);
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom(String roomId);
}

class ChatWebSocketDataSourceImpl implements ChatWebSocketDataSource {
  WebSocketChannel? _channel;
  final StreamController<MessageModel> _messageController = 
      StreamController<MessageModel>.broadcast();
  
  Timer? _heartbeatTimer;
  bool _isConnected = false;

  @override
  Stream<MessageModel> get messageStream => _messageController.stream;

  @override
  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      // メッセージリスナーの設定
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // ハートビートの開始
      _startHeartbeat();
      
    } catch (e) {
      throw NetworkException('Failed to connect to WebSocket: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  Future<void> sendMessage(SendMessageModel message) async {
    if (!_isConnected || _channel == null) {
      throw NetworkException('WebSocket not connected');
    }

    try {
      final jsonMessage = json.encode({
        'type': 'message',
        'data': message.toJson(),
      });

      _channel!.sink.add(jsonMessage);
    } catch (e) {
      throw RemoteDataSourceException('Failed to send message: $e');
    }
  }

  @override
  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _channel == null) {
      throw NetworkException('WebSocket not connected');
    }

    try {
      final joinMessage = json.encode({
        'type': 'join_room',
        'data': {'room_id': roomId},
      });

      _channel!.sink.add(joinMessage);
    } catch (e) {
      throw RemoteDataSourceException('Failed to join room: $e');
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    if (!_isConnected || _channel == null) {
      throw NetworkException('WebSocket not connected');
    }

    try {
      final leaveMessage = json.encode({
        'type': 'leave_room',
        'data': {'room_id': roomId},
      });

      _channel!.sink.add(leaveMessage);
    } catch (e) {
      throw RemoteDataSourceException('Failed to leave room: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = json.decode(data);
      final String type = message['type'];

      switch (type) {
        case 'message':
          final messageModel = MessageModel.fromJson(message['data']);
          _messageController.add(messageModel);
          break;
          
        case 'heartbeat':
          // ハートビート応答
          _sendHeartbeatResponse();
          break;
          
        case 'error':
          final error = message['data']['message'];
          _messageController.addError(
            RemoteDataSourceException('Server error: $error'),
          );
          break;
      }
    } catch (e) {
      _messageController.addError(
        RemoteDataSourceException('Failed to parse message: $e'),
      );
    }
  }

  void _handleError(dynamic error) {
    _messageController.addError(
      NetworkException('WebSocket error: $error'),
    );
  }

  void _handleDisconnection() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _messageController.addError(
      NetworkException('WebSocket disconnected'),
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    if (_isConnected && _channel != null) {
      final heartbeat = json.encode({'type': 'heartbeat'});
      _channel!.sink.add(heartbeat);
    }
  }

  void _sendHeartbeatResponse() {
    if (_isConnected && _channel != null) {
      final response = json.encode({'type': 'heartbeat_response'});
      _channel!.sink.add(response);
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _messageController.close();
  }
}
```

## 命名規則

### ファイル名
インターフェースと実装を別ファイルに分割します。
- **インターフェースファイル**: `{対象名}_remote_data_source.dart`
- **実装ファイル**: `{対象名}_remote_data_source_impl.dart`
- **例**: `user_remote_data_source.dart`（インターフェース）, `user_remote_data_source_impl.dart`（実装）, `auth_remote_data_source.dart`, `auth_remote_data_source_impl.dart`

### ファイル分割構造（推奨）
```
lib/features/{feature_name}/2_infrastructure/2_data_sources/2_remote/
├── user_remote_data_source.dart          # インターフェース定義
├── user_remote_data_source_impl.dart     # Dioベースの実装
└── exceptions/
    └── remote_data_source_exceptions.dart # 例外クラス
```

### クラス名
- **インターフェース**: `{対象名}RemoteDataSource`
- **実装クラス**: `{対象名}RemoteDataSourceImpl`
- **例**: `UserRemoteDataSource`, `UserRemoteDataSourceImpl`

### メソッド名
- **GET操作**: `get{対象}`, `fetch{対象}`, `retrieve{対象}`
- **POST操作**: `create{対象}`, `post{対象}`, `send{対象}`
- **PUT操作**: `update{対象}`, `put{対象}`, `modify{対象}`
- **DELETE操作**: `delete{対象}`, `remove{対象}`
- **認証関連**: `authenticate`, `refreshToken`, `logout`

## ベストプラクティス

### 1. 例外処理の統一
```dart
// exceptions/remote_data_source_exceptions.dart
abstract class RemoteDataSourceException implements Exception {
  final String message;
  RemoteDataSourceException(this.message);
  
  @override
  String toString() => 'RemoteDataSourceException: $message';
}

class NetworkException extends RemoteDataSourceException {
  NetworkException(super.message);
}

class TimeoutException extends RemoteDataSourceException {
  TimeoutException(super.message);
}

class AuthenticationException extends RemoteDataSourceException {
  AuthenticationException(super.message);
}

class ServerException extends RemoteDataSourceException {
  final int? statusCode;
  ServerException(super.message, [this.statusCode]);
}

class ValidationException extends RemoteDataSourceException {
  final Map<String, List<String>>? errors;
  ValidationException(super.message, [this.errors]);
}
```

### 2. リトライ機能
```dart
class RetryableRemoteDataSource {
  final Dio _dio;
  final int _maxRetries;
  final Duration _retryDelay;

  RetryableRemoteDataSource(
    this._dio, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  })  : _maxRetries = maxRetries,
        _retryDelay = retryDelay;

  Future<T> executeWithRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= _maxRetries || !_shouldRetry(e)) {
          rethrow;
        }
        
        await Future.delayed(_retryDelay * attempts);
      }
    }
    
    throw RemoteDataSourceException('Max retries exceeded');
  }

  bool _shouldRetry(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          // 5xxエラーのみリトライ
          return error.response?.statusCode != null &&
                 error.response!.statusCode >= 500;
        default:
          return false;
      }
    }
    return false;
  }
}
```

### 3. レスポンスキャッシュ
```dart
class CachedRemoteDataSource {
  final Dio _dio;
  final Map<String, CacheEntry> _cache = {};
  final Duration _defaultCacheDuration;

  CachedRemoteDataSource(
    this._dio, {
    Duration defaultCacheDuration = const Duration(minutes: 5),
  }) : _defaultCacheDuration = defaultCacheDuration;

  Future<T> getWithCache<T>(
    String cacheKey,
    Future<T> Function() fetcher, {
    Duration? cacheDuration,
  }) async {
    final cachedEntry = _cache[cacheKey];
    
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.data as T;
    }

    final data = await fetcher();
    final expiry = DateTime.now().add(cacheDuration ?? _defaultCacheDuration);
    
    _cache[cacheKey] = CacheEntry(data, expiry);
    
    return data;
  }

  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:async';
import 'dart:convert';

// ✅ HTTP通信ライブラリ
import 'package:dio/dio.dart';
import 'package:http/http.dart';

// ✅ WebSocket
import 'package:web_socket_channel/web_socket_channel.dart';

// ✅ GraphQL
import 'package:graphql_flutter/graphql_flutter.dart';

// ✅ モデルクラス
import '../../1_models/user_model.dart';

// ✅ 例外クラス
import '../exceptions/remote_data_source_exceptions.dart';
```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ ローカルストレージ
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ❌ ドメインエンティティ
import '../../../1_domain/1_entities/user_entity.dart';

// ❌ アプリケーション層
import '../../../3_application/states/user_state.dart';
```

## テスト指針

### 1. モックサーバーテスト
```dart
// test/infrastructure/data_sources/remote/user_remote_data_source_test.dart
void main() {
  group('UserRemoteDataSource', () {
    late MockWebServer mockWebServer;
    late UserRemoteDataSourceImpl dataSource;

    setUp(() async {
      mockWebServer = MockWebServer();
      await mockWebServer.start();
      
      final dio = Dio();
      dataSource = UserRemoteDataSourceImpl(
        dio,
        mockWebServer.url,
      );
    });

    tearDown(() async {
      await mockWebServer.shutdown();
    });

    test('should return user model when API returns 200', () async {
      // Given
      const userId = '1';
      const responseJson = {
        'id': '1',
        'name': 'Test User',
        'email': 'test@example.com',
      };
      
      mockWebServer.enqueue(
        MockResponse()
          ..statusCode = 200
          ..body = json.encode(responseJson),
      );

      // When
      final result = await dataSource.getUser(userId);

      // Then
      expect(result.id, '1');
      expect(result.name, 'Test User');
      expect(result.email, 'test@example.com');
    });

    test('should throw NotFoundException when API returns 404', () async {
      // Given
      mockWebServer.enqueue(
        MockResponse()..statusCode = 404,
      );

      // When & Then
      expect(
        () => dataSource.getUser('nonexistent'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
```

## 注意事項

1. **セキュリティ**: API認証情報やトークンの安全な管理
2. **エラーハンドリング**: ネットワーク状況に応じた適切な例外処理
3. **パフォーマンス**: リクエストの最適化とキャッシュ戦略
4. **レート制限**: API使用制限に配慮したリクエスト制御
5. **ログ出力**: デバッグ用のログ出力（本番環境では機密情報を除外）

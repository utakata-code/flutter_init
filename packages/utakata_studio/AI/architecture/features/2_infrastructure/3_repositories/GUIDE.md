---
applyTo: 'lib/features/**/2_infrastructure/3_repositories/**'
---

# Repository Implementation Layer Instructions - リポジトリ実装層

## 概要
リポジトリ実装層は、ドメイン層で定義されたリポジトリインターフェースの具体的な実装を提供します。ローカルとリモートのデータソースを組み合わせ、データアクセスの詳細を隠蔽し、ドメインエンティティとインフラストラクチャ層の間の変換を担当します。

## 役割と責務

### ✅ すべきこと
- **インターフェース実装**: ドメイン層のリポジトリインターフェースの具体的な実装
- **データソース統合**: ローカルとリモートデータソースの組み合わせ
- **データ変換**: モデルクラスとドメインエンティティ間の変換
- **キャッシュ戦略**: ローカルキャッシュとリモートデータの整合性管理
- **エラー変換**: インフラ層の例外をドメイン例外に変換

### ❌ してはいけないこと
- **ビジネスロジックの実装**: ドメインルールやビジネス判断の記述
- **UIロジックの実装**: プレゼンテーション層のロジックの混入
- **直接的なデータアクセス**: データソースを介さない直接操作
- **状態管理**: アプリケーションの状態管理やライフサイクル管理

## 実装ガイドライン

### 1. 基本的なリポジトリ実装
```dart
// repositories/user_repository_impl.dart
import '../../1_domain/1_entities/user_entity.dart';
import '../../1_domain/2_repositories/user_repository.dart';
import '../2_data_sources/1_local/user_local_data_source.dart';
import '../2_data_sources/2_remote/user_remote_data_source.dart';
import '../1_models/user_model.dart';
import '../1_models/user_db_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<UserEntity?> getUser(String id) async {
    try {
      // 1. ローカルキャッシュから取得を試行
      final localUser = await _localDataSource.getUser(id);
      if (localUser != null) {
        return localUser.toEntity();
      }

      // 2. リモートから取得
      final remoteUser = await _remoteDataSource.getUser(id);
      
      // 3. ローカルキャッシュに保存
      final dbModel = UserDbModel.fromEntity(remoteUser.toEntity());
      await _localDataSource.saveUser(dbModel);

      return remoteUser.toEntity();
    } on RemoteDataSourceException catch (e) {
      // リモート取得に失敗した場合はローカルデータを返す
      final localUser = await _localDataSource.getUser(id);
      if (localUser != null) {
        return localUser.toEntity();
      }
      
      // ローカルにもない場合は例外を変換して再スロー
      throw _convertToDomainException(e);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  @override
  Future<List<UserEntity>> getUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    try {
      // リモートから最新データを取得
      final remoteUsers = await _remoteDataSource.getUsers(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );

      // ローカルキャッシュを更新
      final dbModels = remoteUsers
          .map((model) => UserDbModel.fromEntity(model.toEntity()))
          .toList();
      await _localDataSource.saveUsers(dbModels);

      return remoteUsers.map((model) => model.toEntity()).toList();
    } on RemoteDataSourceException catch (e) {
      // リモート取得に失敗した場合はローカルデータを返す
      final localUsers = await _localDataSource.getAllUsers();
      if (localUsers.isNotEmpty) {
        return localUsers.map((model) => model.toEntity()).toList();
      }
      
      throw _convertToDomainException(e);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    try {
      // 1. リモートに作成
      final userModel = UserModel.fromEntity(user);
      final createdUserModel = await _remoteDataSource.createUser(userModel);

      // 2. ローカルキャッシュに保存
      final dbModel = UserDbModel.fromEntity(createdUserModel.toEntity());
      await _localDataSource.saveUser(dbModel);

      return createdUserModel.toEntity();
    } on RemoteDataSourceException catch (e) {
      throw _convertToDomainException(e);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      // 1. リモートを更新
      final userModel = UserModel.fromEntity(user);
      final updatedUserModel = await _remoteDataSource.updateUser(
        user.id,
        userModel,
      );

      // 2. ローカルキャッシュを更新
      final dbModel = UserDbModel.fromEntity(updatedUserModel.toEntity());
      await _localDataSource.updateUser(dbModel);

      return updatedUserModel.toEntity();
    } on RemoteDataSourceException catch (e) {
      // リモート更新に失敗してもローカルは更新する
      final dbModel = UserDbModel.fromEntity(user);
      await _localDataSource.updateUser(dbModel);
      
      throw _convertToDomainException(e);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      // 1. リモートから削除
      await _remoteDataSource.deleteUser(id);

      // 2. ローカルキャッシュからも削除
      await _localDataSource.deleteUser(id);
    } on RemoteDataSourceException catch (e) {
      // リモート削除に失敗してもローカルは削除する
      await _localDataSource.deleteUser(id);
      
      throw _convertToDomainException(e);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  @override
  Future<bool> userExists(String id) async {
    try {
      // まずローカルで確認
      final localExists = await _localDataSource.userExists(id);
      if (localExists) {
        return true;
      }

      // ローカルにない場合はリモートで確認
      return await _remoteDataSource.userExists(id);
    } on RemoteDataSourceException catch (e) {
      // リモート確認に失敗した場合はローカルの結果を返す
      return await _localDataSource.userExists(id);
    } on LocalDataSourceException catch (e) {
      throw _convertToDomainException(e);
    }
  }

  /// インフラ層の例外をドメイン例外に変換
  DomainException _convertToDomainException(Exception e) {
    if (e is NetworkException) {
      return NetworkDomainException(e.message);
    } else if (e is TimeoutException) {
      return TimeoutDomainException(e.message);
    } else if (e is AuthenticationException) {
      return UnauthorizedDomainException(e.message);
    } else if (e is NotFoundException) {
      return NotFoundDomainException(e.message);
    } else if (e is ValidationException) {
      return ValidationDomainException(e.message);
    } else if (e is ServerException) {
      return ServerDomainException(e.message);
    } else {
      return UnknownDomainException(e.toString());
    }
  }
}
```

### 2. オフライン優先の実装
```dart
// repositories/offline_first_repository_impl.dart
class OfflineFirstUserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  OfflineFirstUserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
  );

  @override
  Future<UserEntity?> getUser(String id) async {
    // 1. 常にローカルから取得
    final localUser = await _localDataSource.getUser(id);
    
    // 2. オンラインの場合はバックグラウンドで同期
    if (await _connectivityService.isConnected) {
      _syncUserInBackground(id);
    }

    return localUser?.toEntity();
  }

  Future<void> _syncUserInBackground(String id) async {
    try {
      final remoteUser = await _remoteDataSource.getUser(id);
      final dbModel = UserDbModel.fromEntity(remoteUser.toEntity());
      await _localDataSource.saveUser(dbModel);
    } catch (e) {
      // バックグラウンド同期の失敗は無視
      // ログ出力など必要に応じて処理
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    if (await _connectivityService.isConnected) {
      // オンライン：リモートに作成してローカルに同期
      return await _createUserOnline(user);
    } else {
      // オフライン：ローカルに保存して後で同期
      return await _createUserOffline(user);
    }
  }

  Future<UserEntity> _createUserOnline(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final createdUserModel = await _remoteDataSource.createUser(userModel);
      
      final dbModel = UserDbModel.fromEntity(createdUserModel.toEntity());
      await _localDataSource.saveUser(dbModel);

      return createdUserModel.toEntity();
    } catch (e) {
      // リモート作成に失敗した場合はオフライン作成にフォールバック
      return await _createUserOffline(user);
    }
  }

  Future<UserEntity> _createUserOffline(UserEntity user) async {
    // 仮のIDを生成してローカルに保存
    final tempUser = user.copyWith(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      isTemporary: true, // 同期が必要であることを示すフラグ
    );

    final dbModel = UserDbModel.fromEntity(tempUser);
    await _localDataSource.saveUser(dbModel);

    // 後で同期するためのキューに追加
    await _addToSyncQueue(SyncOperation.create, tempUser);

    return tempUser;
  }

  Future<void> _addToSyncQueue(SyncOperation operation, UserEntity user) async {
    // 同期キューの実装（SharedPreferencesやローカルDBを使用）
    // 実装は省略
  }

  /// オンライン復帰時の同期処理
  Future<void> syncPendingOperations() async {
    if (!await _connectivityService.isConnected) {
      return;
    }

    // 同期キューから未処理の操作を取得して実行
    // 実装は省略
  }
}
```

### 3. キャッシュ戦略の実装
```dart
// repositories/cached_repository_impl.dart
class CachedUserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final Duration _cacheExpiry;

  CachedUserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource, {
    Duration cacheExpiry = const Duration(minutes: 30),
  }) : _cacheExpiry = cacheExpiry;

  @override
  Future<UserEntity?> getUser(String id) async {
    try {
      // 1. ローカルキャッシュの確認
      final localUser = await _localDataSource.getUser(id);
      
      if (localUser != null && !_isCacheExpired(localUser)) {
        return localUser.toEntity();
      }

      // 2. キャッシュが期限切れまたは存在しない場合はリモートから取得
      final remoteUser = await _remoteDataSource.getUser(id);
      
      // 3. キャッシュを更新
      final dbModel = UserDbModel.fromEntity(remoteUser.toEntity());
      await _localDataSource.saveUser(dbModel);

      return remoteUser.toEntity();
    } on RemoteDataSourceException catch (e) {
      // リモート取得に失敗した場合は期限切れでもローカルデータを返す
      if (localUser != null) {
        return localUser.toEntity();
      }
      
      throw _convertToDomainException(e);
    }
  }

  bool _isCacheExpired(UserDbModel user) {
    final expiryTime = user.updatedAt.add(_cacheExpiry);
    return DateTime.now().isAfter(expiryTime);
  }

  @override
  Future<void> clearCache() async {
    await _localDataSource.deleteAllUsers();
  }

  @override
  Future<void> refreshCache(String id) async {
    try {
      final remoteUser = await _remoteDataSource.getUser(id);
      final dbModel = UserDbModel.fromEntity(remoteUser.toEntity());
      await _localDataSource.saveUser(dbModel);
    } catch (e) {
      throw _convertToDomainException(e);
    }
  }
}
```

### 4. ページネーション対応リポジトリ
```dart
// repositories/paginated_repository_impl.dart
class PaginatedUserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  PaginatedUserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<PaginatedResult<UserEntity>> getUsers({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      // リモートから取得
      final remoteUsers = await _remoteDataSource.getUsers(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );

      // ページネーション情報の構築
      final hasNext = remoteUsers.length == limit;
      final nextOffset = hasNext ? offset + limit : null;

      // ローカルキャッシュの更新（検索クエリがない場合のみ）
      if (searchQuery == null) {
        final dbModels = remoteUsers
            .map((model) => UserDbModel.fromEntity(model.toEntity()))
            .toList();
        
        if (offset == 0) {
          // 最初のページの場合は既存データをクリア
          await _localDataSource.deleteAllUsers();
        }
        
        await _localDataSource.saveUsers(dbModels);
      }

      return PaginatedResult(
        items: remoteUsers.map((model) => model.toEntity()).toList(),
        pagination: Pagination(
          limit: limit,
          offset: offset,
          total: null, // APIから取得できる場合は設定
        ),
        hasNext: hasNext,
        nextOffset: nextOffset,
      );
    } on RemoteDataSourceException catch (e) {
      // リモート取得に失敗した場合はローカルから取得
      if (searchQuery == null && offset == 0) {
        final localUsers = await _localDataSource.getAllUsers();
        final limitedUsers = localUsers.take(limit).toList();
        
        return PaginatedResult(
          items: limitedUsers.map((model) => model.toEntity()).toList(),
          pagination: Pagination(limit: limit, offset: offset),
          hasNext: localUsers.length > limit,
          nextOffset: localUsers.length > limit ? limit : null,
        );
      }
      
      throw _convertToDomainException(e);
    }
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{対象名}_repository_impl.dart`
- **例**: `user_repository_impl.dart`, `product_repository_impl.dart`

### クラス名
- **命名形式**: `{対象名}RepositoryImpl`
- **例**: `UserRepositoryImpl`, `ProductRepositoryImpl`

### メソッド名
- **プライベートメソッド**: `_convert{処理内容}`, `_handle{処理内容}`, `_sync{処理内容}`
- **例**: `_convertToDomainException`, `_handleNetworkError`, `_syncUserInBackground`

## ベストプラクティス

### 1. エラー変換の統一
```dart
// shared/error_converter.dart
class ErrorConverter {
  static DomainException convertToDomainException(Exception e) {
    if (e is NetworkException) {
      return NetworkDomainException(e.message);
    } else if (e is TimeoutException) {
      return TimeoutDomainException(e.message);
    } else if (e is AuthenticationException) {
      return UnauthorizedDomainException(e.message);
    } else if (e is NotFoundException) {
      return NotFoundDomainException(e.message);
    } else if (e is ValidationException) {
      return ValidationDomainException(e.message);
    } else if (e is ServerException) {
      return ServerDomainException(e.message);
    } else {
      return UnknownDomainException(e.toString());
    }
  }
}

// リポジトリ実装で使用
class UserRepositoryImpl implements UserRepository {
  // ...

  DomainException _convertToDomainException(Exception e) {
    return ErrorConverter.convertToDomainException(e);
  }
}
```

### 2. トランザクション処理
```dart
class UserRepositoryImpl implements UserRepository {
  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    // ローカルデータベースのトランザクション
    return await _localDataSource.transaction(() async {
      try {
        return await action();
      } catch (e) {
        // ロールバックは自動的に行われる
        rethrow;
      }
    });
  }

  @override
  Future<UserEntity> createUserWithProfile(
    UserEntity user,
    UserProfileEntity profile,
  ) async {
    return await transaction(() async {
      // 1. ユーザー作成
      final createdUser = await createUser(user);
      
      // 2. プロフィール作成
      final updatedProfile = profile.copyWith(userId: createdUser.id);
      await _profileRepository.createProfile(updatedProfile);
      
      return createdUser;
    });
  }
}
```

### 3. 同期状態の管理
```dart
enum SyncStatus { synced, pending, failed }

class SyncableUserEntity extends UserEntity {
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;
  final String? syncError;

  const SyncableUserEntity({
    required super.id,
    required super.name,
    required super.email,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncAt,
    this.syncError,
  });

  bool get needsSync => syncStatus == SyncStatus.pending || 
                       syncStatus == SyncStatus.failed;
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ ドメイン層
import '../../1_domain/1_entities/user_entity.dart';
import '../../1_domain/2_repositories/user_repository.dart';
import '../../1_domain/exceptions/domain_exceptions.dart';

// ✅ インフラ層内のコンポーネント
import '../2_data_sources/1_local/user_local_data_source.dart';
import '../2_data_sources/2_remote/user_remote_data_source.dart';
import '../1_models/user_model.dart';
import '../1_models/user_db_model.dart';

```

### 禁止されるimport
```dart
// ❌ UIフレームワーク
import 'package:flutter/material.dart';

// ❌ 状態管理
import 'package:riverpod/riverpod.dart';

// ❌ アプリケーション層
import '../../3_application/states/user_state.dart';

// ❌ プレゼンテーション層
import '../../4_presentation/pages/user_page.dart';
```

## テスト指針

### 1. リポジトリ実装のテスト
```dart
// test/infrastructure/repositories/user_repository_impl_test.dart
void main() {
  group('UserRepositoryImpl', () {
    late MockUserRemoteDataSource mockRemoteDataSource;
    late MockUserLocalDataSource mockLocalDataSource;
    late UserRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockUserRemoteDataSource();
      mockLocalDataSource = MockUserLocalDataSource();
      repository = UserRepositoryImpl(
        mockRemoteDataSource,
        mockLocalDataSource,
      );
    });

    test('should return user from local cache when available', () async {
      // Given
      const userId = '1';
      final localUser = UserDbModel(
        id: userId,
        name: 'Cached User',
        email: 'cached@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(() => mockLocalDataSource.getUser(userId))
          .thenAnswer((_) async => localUser);

      // When
      final result = await repository.getUser(userId);

      // Then
      expect(result?.id, userId);
      expect(result?.name, 'Cached User');
      verify(() => mockLocalDataSource.getUser(userId)).called(1);
      verifyNever(() => mockRemoteDataSource.getUser(any()));
    });

    test('should fetch from remote and cache when local cache is empty', () async {
      // Given
      const userId = '1';
      final remoteUser = UserModel(
        id: userId,
        name: 'Remote User',
        email: 'remote@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      when(() => mockLocalDataSource.getUser(userId))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getUser(userId))
          .thenAnswer((_) async => remoteUser);
      when(() => mockLocalDataSource.saveUser(any()))
          .thenAnswer((_) async {});

      // When
      final result = await repository.getUser(userId);

      // Then
      expect(result?.id, userId);
      expect(result?.name, 'Remote User');
      verify(() => mockLocalDataSource.getUser(userId)).called(1);
      verify(() => mockRemoteDataSource.getUser(userId)).called(1);
      verify(() => mockLocalDataSource.saveUser(any())).called(1);
    });
  });
}
```

## 注意事項

1. **データ整合性**: ローカルとリモートデータの一貫性を保つ戦略を明確に定義
2. **例外処理**: インフラ層の例外を適切にドメイン例外に変換
3. **パフォーマンス**: 不要なネットワーク通信を避けるキャッシュ戦略の実装
4. **オフライン対応**: ネットワーク接続がない場合の適切な動作を保証
5. **テスタビリティ**: モックが容易に作成できる依存関係の設計

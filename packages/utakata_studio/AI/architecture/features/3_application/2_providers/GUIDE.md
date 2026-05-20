---
applyTo: 'lib/features/**/3_application/2_providers/**'
---

# Provider Layer Instructions - プロバイダー層

## 概要
プロバイダー層は、依存性注入（DI）を担当し、アプリケーション全体で使用される各種コンポーネントのインスタンス生成と管理を行います。Riverpodを使用して、型安全で効率的な依存関係の解決を実現します。

## 役割と責務

### ✅ すべきこと
- **依存性注入**: Repository、UseCase、DataSourceなどのインスタンス生成と注入
- **ライフサイクル管理**: シングルトン、ファクトリーなどの適切なライフサイクル管理
- **テスタビリティ**: テスト時のモック注入を容易にする構造の提供
- **型安全性**: コンパイル時に依存関係の問題を検出できる設計
- **設定の集約**: アプリケーション設定やAPIエンドポイントなどの一元管理

### ❌ してはいけないこと
- **ビジネスロジックの実装**: UseCase以外でのビジネスロジックの記述
- **状態管理ロジック**: UIの状態変更や副作用の実装（Notifier層の責務）
- **直接的な外部依存**: HTTP通信やデータベースアクセスの直接実装
- **複雑な初期化処理**: プロバイダー内での複雑な初期化ロジックの実装

## 実装ガイドライン

### 1. 基本的なリポジトリプロバイダー
```dart
// providers/user_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

// ドメイン層
import '../../1_domain/2_repositories/user_repository.dart';
import '../../1_domain/3_usecases/get_user_usecase.dart';
import '../../1_domain/3_usecases/create_user_usecase.dart';

// インフラ層
import '../../2_infrastructure/3_repositories/user_repository_impl.dart';
import '../../2_infrastructure/2_data_sources/1_local/user_local_data_source.dart';
import '../../2_infrastructure/2_data_sources/2_remote/user_remote_data_source.dart';

// 共通プロバイダー
import '../../../shared/providers/database_providers.dart';
import '../../../shared/providers/network_providers.dart';

part 'user_providers.g.dart';

/// UserRepositoryの依存性注入
/// 
/// UserRemoteDataSourceとUserLocalDataSourceを組み合わせて
/// UserRepositoryImplのインスタンスを生成します。
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  
  return UserRepositoryImpl(remoteDataSource, localDataSource);
}

/// UserRemoteDataSourceの依存性注入
@riverpod
UserRemoteDataSource userRemoteDataSource(UserRemoteDataSourceRef ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  
  return UserRemoteDataSourceImpl(dio, baseUrl);
}

/// UserLocalDataSourceの依存性注入
@riverpod
UserLocalDataSource userLocalDataSource(UserLocalDataSourceRef ref) {
  final database = ref.watch(databaseProvider);
  
  return UserLocalDataSourceImpl(database);
}

/// GetUserUseCaseの依存性注入
@riverpod
GetUserUseCase getUserUseCase(GetUserUseCaseRef ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserUseCase(repository);
}

/// CreateUserUseCaseの依存性注入
@riverpod
CreateUserUseCase createUserUseCase(CreateUserUseCaseRef ref) {
  final repository = ref.watch(userRepositoryProvider);
  final emailService = ref.watch(emailServiceProvider);
  
  return CreateUserUseCase(repository, emailService);
}
```

### 2. 共通プロバイダー（ネットワーク関連）
```dart
// shared/providers/network_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';

part 'network_providers.g.dart';

/// APIベースURLの設定
@riverpod
String apiBaseUrl(ApiBaseUrlRef ref) {
  // 環境に応じてURLを変更
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  switch (environment) {
    case 'prod':
      return 'https://api.production.com';
    case 'staging':
      return 'https://api.staging.com';
    case 'dev':
    default:
      return 'https://api.development.com';
  }
}

/// DioクライアントのProvider
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio();
  
  // インターセプターの設定
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) {
      // デバッグモードでのみログ出力
      if (kDebugMode) {
        debugPrint(obj.toString());
      }
    },
  ));
  
  // タイムアウト設定
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  
  return dio;
}

/// 認証付きDioクライアント
@riverpod
Dio authenticatedDio(AuthenticatedDioRef ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  
  // 認証インターセプターを追加
  dio.interceptors.add(AuthInterceptor(authService));
  
  return dio;
}

/// HTTP接続チェック用Provider
@riverpod
Future<bool> connectivity(ConnectivityRef ref) async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  
  return result != ConnectivityResult.none;
}
```

### 3. データベースプロバイダー
```dart
// shared/providers/database_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart';

part 'database_providers.g.dart';

/// DriftデータベースのProvider
@riverpod
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}

/// データベース接続の管理
@riverpod
Future<void> initializeDatabase(InitializeDatabaseRef ref) async {
  final database = ref.watch(databaseProvider);
  // データベースの初期化処理
  // Driftでは自動的にテーブルが作成されます
    onUpgrade: (db, oldVersion, newVersion) async {
      // データベースマイグレーション処理
      await _performMigration(db, oldVersion, newVersion);
    },
  );
}

/// データベースマイグレーション処理
Future<void> _performMigration(Database db, int oldVersion, int newVersion) async {
  // バージョンに応じたマイグレーション処理
  for (int version = oldVersion + 1; version <= newVersion; version++) {
    switch (version) {
      case 2:
        await db.execute('ALTER TABLE users ADD COLUMN profile_image_url TEXT');
        break;
      case 3:
        await db.execute('CREATE INDEX idx_users_email ON users(email)');
        break;
      // 他のバージョンも同様に処理
    }
  }
}

/// データベース初期化状態のProvider
@riverpod
Future<bool> databaseInitialized(DatabaseInitializedRef ref) async {
  try {
    await ref.watch(databaseProvider.future);
    return true;
  } catch (e) {
    return false;
  }
}
```

### 4. 認証関連プロバイダー
```dart
// shared/providers/auth_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_providers.g.dart';

/// 認証トークンストレージのProvider
@riverpod
TokenStorage tokenStorage(TokenStorageRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorageImpl(prefs);
}

/// SharedPreferencesのProvider
@riverpod
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) {
  return SharedPreferences.getInstance();
}

/// 認証サービスのProvider
@riverpod
AuthService authService(AuthServiceRef ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  
  return AuthServiceImpl(dio, tokenStorage, baseUrl);
}

/// 現在の認証状態のProvider
@riverpod
Future<AuthState> authState(AuthStateRef ref) async {
  final authService = ref.watch(authServiceProvider);
  
  try {
    final isAuthenticated = await authService.isAuthenticated();
    if (isAuthenticated) {
      final user = await authService.getCurrentUser();
      return AuthState.authenticated(user);
    } else {
      return const AuthState.unauthenticated();
    }
  } catch (e) {
    return AuthState.error(e.toString());
  }
}
```

### 5. 環境設定プロバイダー
```dart
// shared/providers/config_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

part 'config_providers.g.dart';

/// アプリケーション設定のProvider
@riverpod
AppConfig appConfig(AppConfigRef ref) {
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  const apiKey = String.fromEnvironment('API_KEY');
  
  return AppConfig(
    environment: environment,
    apiKey: apiKey,
    isDebugMode: kDebugMode,
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
}

/// ログレベル設定のProvider
@riverpod
LogLevel logLevel(LogLevelRef ref) {
  final config = ref.watch(appConfigProvider);
  
  if (config.isDebugMode) {
    return LogLevel.debug;
  } else {
    return LogLevel.error;
  }
}

/// フィーチャーフラグのProvider
@riverpod
FeatureFlags featureFlags(FeatureFlagsRef ref) {
  final config = ref.watch(appConfigProvider);
  
  return FeatureFlags(
    enableNewFeature: config.environment == 'dev',
    enableAnalytics: config.environment == 'prod',
    enableCrashReporting: config.environment != 'dev',
  );
}

/// アプリケーション設定クラス
@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String environment,
    required String apiKey,
    required bool isDebugMode,
    required String baseUrl,
  }) = _AppConfig;
}

/// フィーチャーフラグクラス
@freezed
class FeatureFlags with _$FeatureFlags {
  const factory FeatureFlags({
    required bool enableNewFeature,
    required bool enableAnalytics,
    required bool enableCrashReporting,
  }) = _FeatureFlags;
}
```

### 6. 外部サービスプロバイダー
```dart
// shared/providers/service_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

/// メールサービスのProvider
@riverpod
EmailService emailService(EmailServiceRef ref) {
  final config = ref.watch(appConfigProvider);
  final dio = ref.watch(dioProvider);
  
  return EmailServiceImpl(
    apiKey: config.apiKey,
    httpClient: dio,
  );
}

/// プッシュ通知サービスのProvider
@riverpod
PushNotificationService pushNotificationService(
  PushNotificationServiceRef ref,
) {
  final config = ref.watch(appConfigProvider);
  
  return PushNotificationServiceImpl(
    apiKey: config.apiKey,
    environment: config.environment,
  );
}

/// ファイルストレージサービスのProvider
@riverpod
FileStorageService fileStorageService(FileStorageServiceRef ref) {
  final config = ref.watch(appConfigProvider);
  
  if (config.environment == 'dev') {
    return LocalFileStorageService();
  } else {
    return CloudFileStorageService(
      apiKey: config.apiKey,
      bucketName: 'app-files-${config.environment}',
    );
  }
}

/// 位置情報サービスのProvider
@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationServiceImpl();
}

/// カメラサービスのProvider
@riverpod
CameraService cameraService(CameraServiceRef ref) {
  return CameraServiceImpl();
}
```

## 命名規則

### ファイル名
- **命名形式**: `{機能名}_providers.dart`
- **例**: `user_providers.dart`, `auth_providers.dart`, `config_providers.dart`

### プロバイダー名
- **命名形式**: `{対象名}Provider`
- **例**: `userRepositoryProvider`, `getUserUseCaseProvider`, `dioProvider`

### プロバイダーグループ
- **機能別**: 同じ機能に関連するプロバイダーは同一ファイルにまとめる
- **依存関係**: 共通の依存関係は別ファイル（shared/providers/）に配置

## ベストプラクティス

### 1. プロバイダーの階層化
```dart
// ✅ Good: 依存関係を明確に分離
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource, localDataSource);
}

@riverpod
UserRemoteDataSource userRemoteDataSource(UserRemoteDataSourceRef ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return UserRemoteDataSourceImpl(dio, baseUrl);
}

// ❌ Bad: 複数の依存関係を一つのプロバイダーで解決
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final dio = Dio(); // 直接インスタンス化
  final database = openDatabase('app.db'); // 直接インスタンス化
  // ...
}
```

### 2. 設定の外部化
```dart
// ✅ Good: 環境変数を使用
@riverpod
String apiBaseUrl(ApiBaseUrlRef ref) {
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  switch (environment) {
    case 'prod':
      return 'https://api.production.com';
    case 'staging':
      return 'https://api.staging.com';
    case 'dev':
    default:
      return 'https://api.development.com';
  }
}

// ❌ Bad: ハードコーディング
@riverpod
String apiBaseUrl(ApiBaseUrlRef ref) {
  return 'https://api.production.com'; // 固定値
}
```

### 3. エラーハンドリング
```dart
@riverpod
Future<Database> database(DatabaseRef ref) async {
  try {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');
    
    return await openDatabase(path, version: 1);
  } catch (e) {
    // ログ出力
    debugPrint('Database initialization failed: $e');
    
    // 適切な例外を再スロー
    throw DatabaseInitializationException('Failed to initialize database: $e');
  }
}
```

### 4. テスト用プロバイダーオーバーライド
```dart
// test/helpers/provider_overrides.dart
class TestProviderOverrides {
  static List<Override> get overrides => [
    userRepositoryProvider.overrideWith((ref) => MockUserRepository()),
    dioProvider.overrideWith((ref) => createMockDio()),
    databaseProvider.overrideWith((ref) => createInMemoryDatabase()),
  ];
}

// テストで使用
void main() {
  testWidgets('should display user data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: TestProviderOverrides.overrides,
        child: MyApp(),
      ),
    );
    
    // テストコード
  });
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Riverpod
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ✅ ドメイン層
import '../../1_domain/2_repositories/user_repository.dart';
import '../../1_domain/3_usecases/get_user_usecase.dart';

// ✅ インフラ層
import '../../2_infrastructure/3_repositories/user_repository_impl.dart';

// ✅ 外部ライブラリ
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ 共通プロバイダー
import '../../../shared/providers/network_providers.dart';
```

### 禁止されるimport
```dart
// ❌ プレゼンテーション層
import '../../4_presentation/pages/user_page.dart';

// ❌ 状態クラス（Providerは状態を持たない）
import '../1_states/user_state.dart';

// ❌ Notifierクラス（Providerは状態管理しない）
import '../3_notifiers/user_notifier.dart';
```

## テスト指針

### 1. プロバイダーのテスト
```dart
// test/application/providers/user_providers_test.dart
void main() {
  group('UserProviders', () {
    test('userRepository should return UserRepositoryImpl', () {
      // Given
      final container = ProviderContainer(
        overrides: [
          userRemoteDataSourceProvider.overrideWith(
            (ref) => MockUserRemoteDataSource(),
          ),
          userLocalDataSourceProvider.overrideWith(
            (ref) => MockUserLocalDataSource(),
          ),
        ],
      );

      // When
      final repository = container.read(userRepositoryProvider);

      // Then
      expect(repository, isA<UserRepositoryImpl>());
    });

    test('getUserUseCase should be created with dependencies', () {
      // Given
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith(
            (ref) => MockUserRepository(),
          ),
        ],
      );

      // When
      final useCase = container.read(getUserUseCaseProvider);

      // Then
      expect(useCase, isA<GetUserUseCase>());
    });
  });
}
```

## 注意事項

1. **単一責任の原則**: 各プロバイダーは単一のインスタンス生成のみを担当
2. **循環依存の回避**: プロバイダー間の循環依存を避ける設計
3. **ライフサイクル管理**: 適切なスコープでインスタンスを管理
4. **テスタビリティ**: テスト時のモック注入を考慮した設計
5. **設定の分離**: 環境固有の設定は外部化し、プロバイダーで注入する

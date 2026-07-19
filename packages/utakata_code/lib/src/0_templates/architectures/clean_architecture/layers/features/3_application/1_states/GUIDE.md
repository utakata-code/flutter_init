---
applyTo: 'lib/features/**/3_application/1_states/**'
---

# State Layer Instructions - 状態層

## 概要
状態層は、アプリケーションの状態を表現するデータクラスを定義します。UIの状態、非同期処理の状態、エラー状態などを型安全に管理し、プレゼンテーション層で使用される状態の構造を明確に定義します。

## 役割と責務

### ✅ すべきこと
- **状態の定義**: UIコンポーネントが必要とする状態の構造を定義
- **不変性の保証**: Freezedを使用した不変な状態クラスの作成
- **型安全性の確保**: 状態の変化を型安全に管理
- **非同期状態の表現**: ローディング、成功、エラーなどの非同期処理状態の定義
- **状態の合成**: 複数のドメインオブジェクトを組み合わせた複合状態の定義

### ❌ してはいけないこと
- **ビジネスロジックの実装**: 状態変更のロジックや副作用の実装
- **外部依存の直接使用**: HTTP通信やデータベースアクセスの実装
- **状態変更メソッドの実装**: 状態を変更するメソッドの定義
- **Notifierロジックの混入**: 状態管理のロジックを状態クラスに含める

## 実装ガイドライン

### 1. 基本的な非同期状態の定義
```dart
// states/user_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../1_domain/1_entities/user_entity.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  /// 初期状態
  const factory UserState.initial() = UserStateInitial;
  
  /// ローディング状態
  const factory UserState.loading() = UserStateLoading;
  
  /// データ読み込み完了状態
  const factory UserState.loaded(UserEntity user) = UserStateLoaded;
  
  /// エラー状態
  const factory UserState.error(String message) = UserStateError;
}

// 拡張メソッドでユーティリティ機能を追加
extension UserStateX on UserState {
  /// 現在ローディング中かどうか
  bool get isLoading => this is UserStateLoading;
  
  /// エラー状態かどうか
  bool get hasError => this is UserStateError;
  
  /// データが読み込まれているかどうか
  bool get hasData => this is UserStateLoaded;
  
  /// ユーザーデータを取得（ある場合）
  UserEntity? get user => mapOrNull(
    loaded: (state) => state.user,
  );
  
  /// エラーメッセージを取得（ある場合）
  String? get errorMessage => mapOrNull(
    error: (state) => state.message,
  );
}
```

### 2. リスト状態の定義
```dart
// states/user_list_state.dart
@freezed
class UserListState with _$UserListState {
  const factory UserListState.initial() = UserListStateInitial;
  
  const factory UserListState.loading() = UserListStateLoading;
  
  const factory UserListState.loaded({
    required List<UserEntity> users,
    required bool hasNext,
    required bool isLoadingMore,
  }) = UserListStateLoaded;
  
  const factory UserListState.error(String message) = UserListStateError;
}

extension UserListStateX on UserListState {
  bool get isLoading => this is UserListStateLoading;
  
  bool get hasError => this is UserListStateError;
  
  bool get hasData => this is UserListStateLoaded;
  
  List<UserEntity> get users => mapOrNull(
    loaded: (state) => state.users,
  ) ?? [];
  
  bool get hasNext => mapOrNull(
    loaded: (state) => state.hasNext,
  ) ?? false;
  
  bool get isLoadingMore => mapOrNull(
    loaded: (state) => state.isLoadingMore,
  ) ?? false;
  
  /// より多くのアイテムを読み込み中の状態に更新
  UserListState loadingMore() => mapOrNull(
    loaded: (state) => state.copyWith(isLoadingMore: true),
  ) ?? this;
  
  /// アイテムを追加して読み込み完了状態に更新
  UserListState addUsers(List<UserEntity> newUsers, bool hasNext) {
    return mapOrNull(
      loaded: (state) => state.copyWith(
        users: [...state.users, ...newUsers],
        hasNext: hasNext,
        isLoadingMore: false,
      ),
    ) ?? this;
  }
}
```

### 3. フォーム状態の定義
```dart
// states/user_form_state.dart
@freezed
class UserFormState with _$UserFormState {
  const factory UserFormState({
    @Default('') String name,
    @Default('') String email,
    @Default(UserRole.user) UserRole role,
    @Default({}) Map<String, String> errors,
    @Default(false) bool isSubmitting,
    @Default(false) bool isValid,
  }) = _UserFormState;
}

extension UserFormStateX on UserFormState {
  /// 名前フィールドにエラーがあるかどうか
  bool get hasNameError => errors.containsKey('name');
  
  /// メールフィールドにエラーがあるかどうか
  bool get hasEmailError => errors.containsKey('email');
  
  /// 任意のフィールドエラーメッセージを取得
  String? getFieldError(String field) => errors[field];
  
  /// フィールド値を更新
  UserFormState updateField(String field, String value) {
    switch (field) {
      case 'name':
        return copyWith(name: value);
      case 'email':
        return copyWith(email: value);
      default:
        return this;
    }
  }
  
  /// エラーを設定
  UserFormState setError(String field, String message) {
    final newErrors = Map<String, String>.from(errors);
    newErrors[field] = message;
    return copyWith(errors: newErrors);
  }
  
  /// エラーをクリア
  UserFormState clearError(String field) {
    final newErrors = Map<String, String>.from(errors);
    newErrors.remove(field);
    return copyWith(errors: newErrors);
  }
  
  /// すべてのエラーをクリア
  UserFormState clearAllErrors() {
    return copyWith(errors: {});
  }
  
  /// ドメインエンティティに変換
  UserEntity toEntity() {
    return UserEntity(
      id: '', // 新規作成時は空文字、更新時は適切なIDを設定
      name: name,
      email: email,
      role: role,
    );
  }
}
```

### 4. 複合状態の定義
```dart
// states/dashboard_state.dart
@freezed
class DashboardState with _$DashboardState {
  const factory DashboardState({
    required UserState userState,
    required NotificationListState notificationState,
    required StatisticsState statisticsState,
    @Default(false) bool isRefreshing,
  }) = _DashboardState;
}

extension DashboardStateX on DashboardState {
  /// 全体的にローディング中かどうか
  bool get isLoading => 
      userState.isLoading || 
      notificationState.isLoading || 
      statisticsState.isLoading;
  
  /// いずれかにエラーがあるかどうか
  bool get hasAnyError => 
      userState.hasError || 
      notificationState.hasError || 
      statisticsState.hasError;
  
  /// 全てのデータが読み込まれているかどうか
  bool get allDataLoaded => 
      userState.hasData && 
      notificationState.hasData && 
      statisticsState.hasData;
  
  /// エラーメッセージのリストを取得
  List<String> get errorMessages {
    final messages = <String>[];
    
    final userError = userState.errorMessage;
    if (userError != null) messages.add('User: $userError');
    
    final notificationError = notificationState.errorMessage;
    if (notificationError != null) messages.add('Notifications: $notificationError');
    
    final statisticsError = statisticsState.errorMessage;
    if (statisticsError != null) messages.add('Statistics: $statisticsError');
    
    return messages;
  }
}
```

### 5. 検索状態の定義
```dart
// states/search_state.dart
@freezed
class SearchState<T> with _$SearchState<T> {
  const factory SearchState({
    @Default('') String query,
    @Default([]) List<T> results,
    @Default([]) List<String> recentSearches,
    @Default(false) bool isSearching,
    @Default(false) bool hasSearched,
    String? error,
  }) = _SearchState<T>;
}

extension SearchStateX<T> on SearchState<T> {
  /// 検索結果があるかどうか
  bool get hasResults => results.isNotEmpty;
  
  /// 検索中かどうか
  bool get isLoading => isSearching;
  
  /// エラーがあるかどうか
  bool get hasError => error != null;
  
  /// 空の検索結果かどうか（検索実行済みだが結果が0件）
  bool get isEmptyResult => hasSearched && results.isEmpty && !hasError;
  
  /// クエリが有効かどうか
  bool get hasValidQuery => query.trim().isNotEmpty;
}

// 具体的な型での使用例
typedef UserSearchState = SearchState<UserEntity>;
typedef ProductSearchState = SearchState<ProductEntity>;
```

### 6. ページネーション状態の定義
```dart
// states/paginated_state.dart
@freezed
class PaginatedState<T> with _$PaginatedState<T> {
  const factory PaginatedState.initial() = PaginatedStateInitial<T>;
  
  const factory PaginatedState.loading() = PaginatedStateLoading<T>;
  
  const factory PaginatedState.loaded({
    required List<T> items,
    required int currentPage,
    required bool hasNext,
    @Default(false) bool isLoadingMore,
  }) = PaginatedStateLoaded<T>;
  
  const factory PaginatedState.error(String message) = PaginatedStateError<T>;
}

extension PaginatedStateX<T> on PaginatedState<T> {
  bool get isLoading => this is PaginatedStateLoading<T>;
  
  bool get hasError => this is PaginatedStateError<T>;
  
  bool get hasData => this is PaginatedStateLoaded<T>;
  
  List<T> get items => mapOrNull(
    loaded: (state) => state.items,
  ) ?? [];
  
  bool get hasNext => mapOrNull(
    loaded: (state) => state.hasNext,
  ) ?? false;
  
  bool get isLoadingMore => mapOrNull(
    loaded: (state) => state.isLoadingMore,
  ) ?? false;
  
  int get currentPage => mapOrNull(
    loaded: (state) => state.currentPage,
  ) ?? 0;
  
  /// 次のページを読み込み中の状態に更新
  PaginatedState<T> loadingNextPage() => mapOrNull(
    loaded: (state) => state.copyWith(isLoadingMore: true),
  ) ?? this;
  
  /// 新しいページのアイテムを追加
  PaginatedState<T> addPage(List<T> newItems, bool hasNext) {
    return mapOrNull(
      loaded: (state) => state.copyWith(
        items: [...state.items, ...newItems],
        currentPage: state.currentPage + 1,
        hasNext: hasNext,
        isLoadingMore: false,
      ),
    ) ?? this;
  }
  
  /// リフレッシュ（最初のページをリロード）
  PaginatedState<T> refresh(List<T> newItems, bool hasNext) {
    return PaginatedStateLoaded(
      items: newItems,
      currentPage: 1,
      hasNext: hasNext,
      isLoadingMore: false,
    );
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{対象名}_state.dart`
- **例**: `user_state.dart`, `user_list_state.dart`, `user_form_state.dart`

### クラス名
- **命名形式**: `{対象名}State`
- **例**: `UserState`, `UserListState`, `UserFormState`

### 状態バリアント名
- **初期状態**: `initial`
- **ローディング状態**: `loading`
- **データ読み込み完了**: `loaded`
- **エラー状態**: `error`
- **フォーム状態**: フィールド名をプロパティとして定義

## ベストプラクティス

### 1. Union Typesの活用
```dart
// ✅ Good: Union Typesで状態を明確に分離
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = UserStateInitial;
  const factory UserState.loading() = UserStateLoading;
  const factory UserState.loaded(UserEntity user) = UserStateLoaded;
  const factory UserState.error(String message) = UserStateError;
}

// ❌ Bad: 単一のクラスにすべての状態を詰め込む
@freezed
class UserState with _$UserState {
  const factory UserState({
    UserEntity? user,
    bool isLoading,
    String? error,
  }) = _UserState;
}
```

### 2. 拡張メソッドの活用
```dart
extension UserStateX on UserState {
  /// 状態に応じた適切なウィジェットを返す
  Widget when({
    required Widget Function() initial,
    required Widget Function() loading,
    required Widget Function(UserEntity user) loaded,
    required Widget Function(String message) error,
  }) {
    return this.when(
      initial: initial,
      loading: loading,
      loaded: loaded,
      error: error,
    );
  }

  /// 状態の説明を取得
  String get description => when(
    initial: () => 'Initial state',
    loading: () => 'Loading...',
    loaded: (user) => 'Loaded user: ${user.name}',
    error: (message) => 'Error: $message',
  );
}
```

### 3. ジェネリクスの活用
```dart
// 再利用可能な非同期状態
@freezed
class AsyncState<T> with _$AsyncState<T> {
  const factory AsyncState.initial() = AsyncStateInitial<T>;
  const factory AsyncState.loading() = AsyncStateLoading<T>;
  const factory AsyncState.loaded(T data) = AsyncStateLoaded<T>;
  const factory AsyncState.error(String message) = AsyncStateError<T>;
}

// 具体的な型での使用
typedef UserAsyncState = AsyncState<UserEntity>;
typedef UserListAsyncState = AsyncState<List<UserEntity>>;
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ 標準ライブラリ
import 'dart:core';

// ✅ Freezed（コード生成）
import 'package:freezed_annotation/freezed_annotation.dart';

// ✅ ドメインエンティティ
import '../../1_domain/1_entities/user_entity.dart';

// ✅ UIライブラリ（extension用）
import 'package:flutter/widgets.dart';
```

### 禁止されるimport
```dart
// ❌ 状態管理ライブラリ
import 'package:riverpod/riverpod.dart';

// ❌ HTTP通信
import 'package:dio/dio.dart';

// ❌ データベース
import 'package:drift/drift.dart';

// ❌ インフラ層
import '../../2_infrastructure/models/user_model.dart';

// ❌ プレゼンテーション層
import '../../4_presentation/pages/user_page.dart';
```

## テスト指針

### 1. 状態クラスのテスト
```dart
// test/application/states/user_state_test.dart
void main() {
  group('UserState', () {
    test('should create initial state', () {
      // When
      const state = UserState.initial();

      // Then
      expect(state, isA<UserStateInitial>());
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.hasData, false);
    });

    test('should create loaded state with user', () {
      // Given
      const user = UserEntity(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
      );

      // When
      const state = UserState.loaded(user);

      // Then
      expect(state, isA<UserStateLoaded>());
      expect(state.hasData, true);
      expect(state.user, user);
    });

    test('should provide error message in error state', () {
      // Given
      const errorMessage = 'Something went wrong';

      // When
      const state = UserState.error(errorMessage);

      // Then
      expect(state, isA<UserStateError>());
      expect(state.hasError, true);
      expect(state.errorMessage, errorMessage);
    });
  });

  group('UserFormState', () {
    test('should validate fields correctly', () {
      // Given
      const state = UserFormState(
        name: 'John Doe',
        email: 'john@example.com',
      );

      // When
      final entity = state.toEntity();

      // Then
      expect(entity.name, 'John Doe');
      expect(entity.email, 'john@example.com');
    });

    test('should handle field errors', () {
      // Given
      const state = UserFormState();

      // When
      final stateWithError = state.setError('name', 'Name is required');

      // Then
      expect(stateWithError.hasNameError, true);
      expect(stateWithError.getFieldError('name'), 'Name is required');
    });
  });
}
```

## 注意事項

1. **不変性**: 状態クラスは常に不変にし、変更は新しいインスタンスを作成して行う
2. **型安全性**: Union Typesを活用して状態の変化を型安全に管理する
3. **再利用性**: ジェネリクスを活用して再利用可能な状態パターンを作成する
4. **拡張性**: 拡張メソッドを使用して状態に関連するユーティリティ機能を追加する
5. **テスタビリティ**: 各状態バリアントと拡張メソッドに対して適切なテストを作成する

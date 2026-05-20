---
applyTo: 'lib/features/**/3_application/3_notifiers/**'
---

# Notifier Layer Instructions - Notifier層

## 概要
Notifier層は、アプリケーションの状態管理とビジネスロジックの実行を担当します。Riverpodの`@riverpod`アノテーションを使用して型安全なNotifierを作成し、UIの状態変更、UseCase実行、副作用の管理を行います。

## 役割と責務

### ✅ すべきこと
- **状態管理**: UIが関心を持つ状態の生成、更新、管理
- **UseCase実行**: ドメイン層のUseCaseを呼び出してビジネスロジックを実行
- **副作用の管理**: API通信、データベースアクセス、ナビゲーションなどの副作用を制御
- **エラーハンドリング**: 例外の適切な処理と状態への反映
- **状態の変換**: ドメインエンティティとUI状態の変換

### ❌ してはいけないこと
- **ビジネスロジックの直接実装**: ドメインロジックをNotifier内に記述
- **データアクセスの直接実装**: Repository以外でのデータアクセス
- **UIロジックの混入**: ウィジェットの構築やナビゲーションロジックの実装
- **複雑な状態の保持**: 単純でない状態構造の管理

## 実装ガイドライン

### 1. 基本的なNotifierの実装
```dart
// notifiers/user_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../1_states/user_state.dart';
import '../2_providers/user_providers.dart';
import '../../1_domain/1_entities/user_entity.dart';

part 'user_notifier.g.dart';

/// ユーザー情報の状態管理を行うNotifier
/// 
/// ユーザーの取得、作成、更新、削除などの操作を管理し、
/// 対応する状態変更をUIに提供します。
@riverpod
class UserNotifier extends _$UserNotifier {
  /// 初期状態を返す
  @override
  UserState build() => const UserState.initial();

  /// 指定されたIDのユーザーを取得する
  Future<void> getUser(String userId) async {
    // ローディング状態に変更
    state = const UserState.loading();

    try {
      // UseCaseを実行
      final getUserUseCase = ref.read(getUserUseCaseProvider);
      final user = await getUserUseCase(userId);
      
      // 成功状態に変更
      state = UserState.loaded(user);
    } catch (e) {
      // エラー状態に変更
      state = UserState.error(_formatErrorMessage(e));
    }
  }

  /// 新しいユーザーを作成する
  Future<void> createUser({
    required String name,
    required String email,
    UserRole role = UserRole.user,
  }) async {
    state = const UserState.loading();

    try {
      final createUserUseCase = ref.read(createUserUseCaseProvider);
      final params = CreateUserParams(
        name: name,
        email: email,
        role: role,
      );
      
      final user = await createUserUseCase(params);
      state = UserState.loaded(user);
    } catch (e) {
      state = UserState.error(_formatErrorMessage(e));
    }
  }

  /// ユーザー情報を更新する
  Future<void> updateUser(UserEntity updatedUser) async {
    // 現在の状態を保持
    final currentState = state;
    
    state = const UserState.loading();

    try {
      final updateUserUseCase = ref.read(updateUserUseCaseProvider);
      final user = await updateUserUseCase(updatedUser);
      
      state = UserState.loaded(user);
    } catch (e) {
      // エラー時は前の状態に戻す
      state = currentState;
      
      // エラーメッセージは別途通知（後述のエラーNotifierを使用）
      ref.read(errorNotifierProvider.notifier).showError(_formatErrorMessage(e));
    }
  }

  /// ユーザーを削除する
  Future<void> deleteUser(String userId) async {
    state = const UserState.loading();

    try {
      final deleteUserUseCase = ref.read(deleteUserUseCaseProvider);
      await deleteUserUseCase(userId);
      
      // 削除後は初期状態に戻す
      state = const UserState.initial();
    } catch (e) {
      state = UserState.error(_formatErrorMessage(e));
    }
  }

  /// 状態をリセットする
  void reset() {
    state = const UserState.initial();
  }

  /// エラーメッセージをフォーマットする
  String _formatErrorMessage(Object error) {
    if (error is DomainException) {
      return error.message;
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
```

### 2. リスト管理のNotifier実装
```dart
// notifiers/user_list_notifier.dart
@riverpod
class UserListNotifier extends _$UserListNotifier {
  @override
  UserListState build() => const UserListState.initial();

  /// ユーザーリストを取得する
  Future<void> loadUsers({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    // 初回読み込みの場合はローディング状態
    if (offset == 0) {
      state = const UserListState.loading();
    } else {
      // 追加読み込みの場合は現在の状態を維持してloadingMoreフラグを設定
      state = state.maybeWhen(
        loaded: (users, hasNext, _) => UserListState.loaded(
          users: users,
          hasNext: hasNext,
          isLoadingMore: true,
        ),
        orElse: () => const UserListState.loading(),
      );
    }

    try {
      final getUsersUseCase = ref.read(getUsersUseCaseProvider);
      final params = GetUsersParams(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
      
      final result = await getUsersUseCase(params);

      state = state.maybeWhen(
        loaded: (currentUsers, _, __) {
          // 追加読み込みの場合は既存リストに追加
          final updatedUsers = offset == 0 
              ? result.users 
              : [...currentUsers, ...result.users];
          
          return UserListState.loaded(
            users: updatedUsers,
            hasNext: result.hasNext,
            isLoadingMore: false,
          );
        },
        orElse: () => UserListState.loaded(
          users: result.users,
          hasNext: result.hasNext,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // 追加読み込み時のエラーは現在の状態を維持
      if (offset > 0) {
        state = state.maybeWhen(
          loaded: (users, hasNext, _) => UserListState.loaded(
            users: users,
            hasNext: hasNext,
            isLoadingMore: false,
          ),
          orElse: () => UserListState.error(_formatErrorMessage(e)),
        );
        
        // エラーメッセージを別途通知
        ref.read(errorNotifierProvider.notifier).showError(_formatErrorMessage(e));
      } else {
        state = UserListState.error(_formatErrorMessage(e));
      }
    }
  }

  /// 次のページを読み込む
  Future<void> loadMoreUsers() async {
    final currentState = state;
    
    if (currentState is UserListStateLoaded && 
        currentState.hasNext && 
        !currentState.isLoadingMore) {
      
      final currentCount = currentState.users.length;
      await loadUsers(offset: currentCount);
    }
  }

  /// リストをリフレッシュする
  Future<void> refreshUsers() async {
    await loadUsers(offset: 0);
  }

  /// 検索を実行する
  Future<void> searchUsers(String query) async {
    await loadUsers(searchQuery: query);
  }

  /// ユーザーをリストに追加する（他のNotifierから呼び出される）
  void addUser(UserEntity user) {
    state = state.maybeWhen(
      loaded: (users, hasNext, isLoadingMore) => UserListState.loaded(
        users: [user, ...users], // 先頭に追加
        hasNext: hasNext,
        isLoadingMore: isLoadingMore,
      ),
      orElse: () => state,
    );
  }

  /// ユーザーをリストから削除する
  void removeUser(String userId) {
    state = state.maybeWhen(
      loaded: (users, hasNext, isLoadingMore) => UserListState.loaded(
        users: users.where((user) => user.id != userId).toList(),
        hasNext: hasNext,
        isLoadingMore: isLoadingMore,
      ),
      orElse: () => state,
    );
  }

  /// ユーザー情報を更新する
  void updateUser(UserEntity updatedUser) {
    state = state.maybeWhen(
      loaded: (users, hasNext, isLoadingMore) {
        final updatedUsers = users.map((user) {
          return user.id == updatedUser.id ? updatedUser : user;
        }).toList();
        
        return UserListState.loaded(
          users: updatedUsers,
          hasNext: hasNext,
          isLoadingMore: isLoadingMore,
        );
      },
      orElse: () => state,
    );
  }

  String _formatErrorMessage(Object error) {
    if (error is DomainException) {
      return error.message;
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
```

### 3. フォーム管理のNotifier実装
```dart
// notifiers/user_form_notifier.dart
@riverpod
class UserFormNotifier extends _$UserFormNotifier {
  @override
  UserFormState build() => const UserFormState();

  /// 名前フィールドを更新する
  void updateName(String name) {
    state = state.copyWith(name: name);
    _validateField('name', name);
  }

  /// メールフィールドを更新する
  void updateEmail(String email) {
    state = state.copyWith(email: email);
    _validateField('email', email);
  }

  /// ロールを更新する
  void updateRole(UserRole role) {
    state = state.copyWith(role: role);
  }

  /// フォームをクリアする
  void clear() {
    state = const UserFormState();
  }

  /// フォームデータでユーザーを作成する
  Future<void> submitCreate() async {
    if (!_validateForm()) {
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final createUserUseCase = ref.read(createUserUseCaseProvider);
      final params = CreateUserParams(
        name: state.name,
        email: state.email,
        role: state.role,
      );
      
      final user = await createUserUseCase(params);
      
      // 作成成功後はユーザーリストに追加
      ref.read(userListNotifierProvider.notifier).addUser(user);
      
      // フォームをクリア
      clear();
      
      // 成功メッセージを表示
      ref.read(messageNotifierProvider.notifier)
          .showSuccess('User created successfully');
          
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      
      // エラーがバリデーションエラーの場合はフィールドエラーとして表示
      if (e is ValidationException && e.errors != null) {
        _setValidationErrors(e.errors!);
      } else {
        ref.read(errorNotifierProvider.notifier)
            .showError(_formatErrorMessage(e));
      }
    }
  }

  /// フォームデータでユーザーを更新する
  Future<void> submitUpdate(String userId) async {
    if (!_validateForm()) {
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final updateUserUseCase = ref.read(updateUserUseCaseProvider);
      final user = UserEntity(
        id: userId,
        name: state.name,
        email: state.email,
        role: state.role,
      );
      
      final updatedUser = await updateUserUseCase(user);
      
      // リストの該当ユーザーを更新
      ref.read(userListNotifierProvider.notifier).updateUser(updatedUser);
      
      // 個別ユーザー状態も更新
      ref.read(userNotifierProvider.notifier).state = UserState.loaded(updatedUser);
      
      state = state.copyWith(isSubmitting: false);
      
      ref.read(messageNotifierProvider.notifier)
          .showSuccess('User updated successfully');
          
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      
      if (e is ValidationException && e.errors != null) {
        _setValidationErrors(e.errors!);
      } else {
        ref.read(errorNotifierProvider.notifier)
            .showError(_formatErrorMessage(e));
      }
    }
  }

  /// 既存ユーザーデータでフォームを初期化する
  void initializeWithUser(UserEntity user) {
    state = UserFormState(
      name: user.name,
      email: user.email,
      role: user.role,
    );
    _validateForm();
  }

  /// 単一フィールドのバリデーション
  void _validateField(String field, String value) {
    Map<String, String> newErrors = Map.from(state.errors);

    switch (field) {
      case 'name':
        if (value.isEmpty) {
          newErrors['name'] = 'Name is required';
        } else if (value.length < 2) {
          newErrors['name'] = 'Name must be at least 2 characters';
        } else {
          newErrors.remove('name');
        }
        break;
        
      case 'email':
        if (value.isEmpty) {
          newErrors['email'] = 'Email is required';
        } else if (!_isValidEmail(value)) {
          newErrors['email'] = 'Please enter a valid email address';
        } else {
          newErrors.remove('email');
        }
        break;
    }

    state = state.copyWith(
      errors: newErrors,
      isValid: newErrors.isEmpty && _hasRequiredFields(),
    );
  }

  /// フォーム全体のバリデーション
  bool _validateForm() {
    _validateField('name', state.name);
    _validateField('email', state.email);
    
    return state.isValid;
  }

  /// 必須フィールドがすべて入力されているかチェック
  bool _hasRequiredFields() {
    return state.name.isNotEmpty && state.email.isNotEmpty;
  }

  /// メールアドレスの形式チェック
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// バリデーションエラーを設定
  void _setValidationErrors(Map<String, List<String>> errors) {
    Map<String, String> fieldErrors = {};
    
    errors.forEach((field, messages) {
      if (messages.isNotEmpty) {
        fieldErrors[field] = messages.first;
      }
    });

    state = state.copyWith(
      errors: fieldErrors,
      isValid: fieldErrors.isEmpty,
      isSubmitting: false,
    );
  }

  String _formatErrorMessage(Object error) {
    if (error is DomainException) {
      return error.message;
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
```

### 4. 共通メッセージNotifierの実装
```dart
// shared/notifiers/message_notifier.dart
@riverpod
class MessageNotifier extends _$MessageNotifier {
  @override
  MessageState build() => const MessageState.none();

  /// 成功メッセージを表示する
  void showSuccess(String message) {
    state = MessageState.success(message);
    _autoHide();
  }

  /// 情報メッセージを表示する
  void showInfo(String message) {
    state = MessageState.info(message);
    _autoHide();
  }

  /// 警告メッセージを表示する
  void showWarning(String message) {
    state = MessageState.warning(message);
    _autoHide();
  }

  /// メッセージを非表示にする
  void hide() {
    state = const MessageState.none();
  }

  /// 自動非表示タイマー
  void _autoHide() {
    Timer(const Duration(seconds: 3), () {
      if (state != const MessageState.none()) {
        hide();
      }
    });
  }
}

@freezed
class MessageState with _$MessageState {
  const factory MessageState.none() = MessageStateNone;
  const factory MessageState.success(String message) = MessageStateSuccess;
  const factory MessageState.info(String message) = MessageStateInfo;
  const factory MessageState.warning(String message) = MessageStateWarning;
}
```

### 5. エラーNotifierの実装
```dart
// shared/notifiers/error_notifier.dart
@riverpod
class ErrorNotifier extends _$ErrorNotifier {
  @override
  ErrorState build() => const ErrorState.none();

  /// エラーメッセージを表示する
  void showError(String message) {
    state = ErrorState.error(message);
  }

  /// ネットワークエラーを表示する
  void showNetworkError() {
    state = const ErrorState.networkError();
  }

  /// サーバーエラーを表示する
  void showServerError() {
    state = const ErrorState.serverError();
  }

  /// エラーを非表示にする
  void clear() {
    state = const ErrorState.none();
  }

  /// エラーを確認済みにする
  void acknowledge() {
    clear();
  }
}

@freezed
class ErrorState with _$ErrorState {
  const factory ErrorState.none() = ErrorStateNone;
  const factory ErrorState.error(String message) = ErrorStateError;
  const factory ErrorState.networkError() = ErrorStateNetworkError;
  const factory ErrorState.serverError() = ErrorStateServerError;
}
```

## 命名規則

### ファイル名
- **命名形式**: `{対象名}_notifier.dart`
- **例**: `user_notifier.dart`, `user_list_notifier.dart`, `user_form_notifier.dart`

### クラス名
- **命名形式**: `{対象名}Notifier`
- **例**: `UserNotifier`, `UserListNotifier`, `UserFormNotifier`

### メソッド名
- **状態変更**: `update{対象}`, `set{対象}`, `clear{対象}`
- **アクション実行**: `load{対象}`, `create{対象}`, `delete{対象}`
- **フォーム操作**: `submit{操作}`, `validate{対象}`, `initialize{対象}`

## ベストプラクティス

### 1. 状態の適切な管理
```dart
// ✅ Good: 明確な状態変化
Future<void> loadUser(String userId) async {
  state = const UserState.loading();
  
  try {
    final user = await getUserUseCase(userId);
    state = UserState.loaded(user);
  } catch (e) {
    state = UserState.error(e.toString());
  }
}

// ❌ Bad: 複雑な状態変化
Future<void> loadUser(String userId) async {
  if (state is UserStateLoading) return; // 条件分岐が複雑
  
  state = UserState.loading();
  // 複雑なロジック...
}
```

### 2. 適切なエラーハンドリング
```dart
// ✅ Good: エラーの種類に応じた処理
Future<void> updateUser(UserEntity user) async {
  try {
    final updatedUser = await updateUserUseCase(user);
    state = UserState.loaded(updatedUser);
  } on ValidationException catch (e) {
    // バリデーションエラーは状態に反映
    state = UserState.validationError(e.errors);
  } on NetworkException catch (e) {
    // ネットワークエラーは別途通知
    ref.read(errorNotifierProvider.notifier).showNetworkError();
  } catch (e) {
    // その他のエラー
    state = UserState.error(e.toString());
  }
}
```

### 3. 他のNotifierとの連携
```dart
// ✅ Good: 他のNotifierを適切に更新
Future<void> deleteUser(String userId) async {
  try {
    await deleteUserUseCase(userId);
    
    // リストからも削除
    ref.read(userListNotifierProvider.notifier).removeUser(userId);
    
    // 現在のユーザー状態をリセット
    state = const UserState.initial();
    
    // 成功メッセージを表示
    ref.read(messageNotifierProvider.notifier)
        .showSuccess('User deleted successfully');
        
  } catch (e) {
    state = UserState.error(e.toString());
  }
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Riverpod
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ✅ 状態クラス
import '../1_states/user_state.dart';

// ✅ プロバイダー
import '../2_providers/user_providers.dart';

// ✅ ドメインエンティティ
import '../../1_domain/1_entities/user_entity.dart';

// ✅ ドメイン例外
import '../../1_domain/exceptions/domain_exceptions.dart';

// ✅ 標準ライブラリ
import 'dart:async';
```

### 禁止されるimport
```dart
// ❌ インフラ層
import '../../2_infrastructure/repositories/user_repository_impl.dart';

// ❌ プレゼンテーション層
import '../../4_presentation/pages/user_page.dart';

// ❌ 外部ライブラリの直接使用
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
```

## テスト指針

### 1. Notifierのテスト
```dart
// test/application/notifiers/user_notifier_test.dart
void main() {
  group('UserNotifier', () {
    late ProviderContainer container;
    late MockGetUserUseCase mockGetUserUseCase;

    setUp(() {
      mockGetUserUseCase = MockGetUserUseCase();
      
      container = ProviderContainer(
        overrides: [
          getUserUseCaseProvider.overrideWith((ref) => mockGetUserUseCase),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with initial state', () {
      // When
      final notifier = container.read(userNotifierProvider.notifier);
      final state = container.read(userNotifierProvider);

      // Then
      expect(state, const UserState.initial());
    });

    test('should load user successfully', () async {
      // Given
      const userId = '1';
      const user = UserEntity(
        id: userId,
        name: 'Test User',
        email: 'test@example.com',
      );
      
      when(() => mockGetUserUseCase(userId))
          .thenAnswer((_) async => user);

      // When
      final notifier = container.read(userNotifierProvider.notifier);
      await notifier.getUser(userId);

      // Then
      final state = container.read(userNotifierProvider);
      expect(state, const UserState.loaded(user));
    });

    test('should handle error when loading user fails', () async {
      // Given
      const userId = '1';
      const errorMessage = 'User not found';
      
      when(() => mockGetUserUseCase(userId))
          .thenThrow(NotFoundException(errorMessage));

      // When
      final notifier = container.read(userNotifierProvider.notifier);
      await notifier.getUser(userId);

      // Then
      final state = container.read(userNotifierProvider);
      expect(state, UserState.error(errorMessage));
    });
  });
}
```

## 注意事項

1. **状態の一貫性**: 状態変更は常に明確で一貫性のある方法で行う
2. **副作用の管理**: 外部システムへの影響は適切に制御し、エラー時の回復処理を考慮
3. **パフォーマンス**: 不要な状態変更や再計算を避ける
4. **テスタビリティ**: UseCaseの依存関係注入により容易にテスト可能な設計
5. **責務の分離**: NotifierとProviderの責務を明確に分離し、適切な層での処理を実装

---
applyTo: 'lib/features/**/4_presentation/2_pages/**'
---

# Page Layer Instructions - ページ層

## 概要
ページ層は、アプリケーションの画面（ページ）を定義し、ユーザーのインタラクションとアプリケーションの状態管理を結びつけます。HookConsumerWidgetを使用し、Riverpodによる状態管理とHooksによるライフサイクル管理を活用します。

## 役割と責務

### ✅ すべきこと
- **画面構成の定義**: アプリケーションの各画面のレイアウトと構造の実装
- **状態の購読**: Notifierから状態を購読し、UIに反映
- **ユーザーアクションの処理**: ボタンタップ、フォーム送信などのイベント処理
- **ライフサイクル管理**: 画面の初期化、破棄時の処理
- **ナビゲーション制御**: 他の画面への遷移処理

### ❌ してはいけないこと
- **ビジネスロジックの実装**: ドメインロジックやデータ処理ロジックの記述
- **状態管理ロジック**: 状態の更新や管理ロジックの実装（Notifier層の責務）
- **直接的なデータアクセス**: Repository やDataSourceの直接使用
- **複雑なウィジェット構築**: 再利用可能なコンポーネントは別のWidgetとして分離

## 実装ガイドライン

### 1. 基本的なページの実装
```dart
// pages/user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../3_application/3_notifiers/user_notifier.dart';
import '../../../3_application/3_notifiers/error_notifier.dart';
import '../1_widgets/2_molecules/user_info_card.dart';
import '../1_widgets/1_atoms/loading_indicator.dart';
import '../1_widgets/1_atoms/error_display.dart';

/// ユーザー詳細画面
class UserDetailPage extends HookConsumerWidget {
  const UserDetailPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 状態の購読
    final userState = ref.watch(userNotifierProvider);
    final errorState = ref.watch(errorNotifierProvider);

    // ライフサイクル管理: 画面初期化時にユーザー情報を取得
    useEffect(() {
      // 画面表示時に一度だけ実行
      Future.microtask(() {
        ref.read(userNotifierProvider.notifier).getUser(userId);
      });
      return null; // disposeは不要
    }, const []); // 依存配列は空（初回のみ実行）

    // エラー状態の監視と表示
    ref.listen<ErrorState>(errorNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (message) => _showErrorSnackBar(context, message),
        networkError: () => _showErrorSnackBar(context, 'Network connection error'),
        serverError: () => _showErrorSnackBar(context, 'Server error occurred'),
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditPage(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshUser(ref),
        child: userState.when(
          initial: () => const Center(
            child: Text('User information will be loaded'),
          ),
          loading: () => const Center(
            child: LoadingIndicator(),
          ),
          loaded: (user) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UserInfoCard(user: user),
                const SizedBox(height: 24),
                _buildActionButtons(context, ref, user),
              ],
            ),
          ),
          error: (message) => Center(
            child: ErrorDisplay(
              message: message,
              onRetry: () => _retryLoadUser(ref),
            ),
          ),
        ),
      ),
    );
  }

  /// アクションボタンの構築
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _navigateToEditPage(context),
          icon: const Icon(Icons.edit),
          label: const Text('Edit User'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _shareUser(user),
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
      ],
    );
  }

  /// ユーザー情報の再読み込み
  Future<void> _refreshUser(WidgetRef ref) async {
    await ref.read(userNotifierProvider.notifier).getUser(userId);
  }

  /// ユーザー読み込みのリトライ
  void _retryLoadUser(WidgetRef ref) {
    ref.read(userNotifierProvider.notifier).getUser(userId);
  }

  /// 編集画面への遷移
  void _navigateToEditPage(BuildContext context) {
    context.push('/users/$userId/edit');
  }

  /// ユーザー共有機能
  void _shareUser(UserEntity user) {
    // 共有機能の実装
    Share.share('Check out ${user.name}\'s profile!');
  }

  /// 削除確認ダイアログの表示
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteUser(context, ref);
      }
    });
  }

  /// ユーザー削除処理
  void _deleteUser(BuildContext context, WidgetRef ref) {
    ref.read(userNotifierProvider.notifier).deleteUser(userId).then((_) {
      // 削除成功時は前の画面に戻る
      context.pop();
    });
  }

  /// エラーメッセージのスナックバー表示
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
```

### 2. リスト表示ページの実装
```dart
// pages/user_list_page.dart
class UserListPage extends HookConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListState = ref.watch(userListNotifierProvider);
    final searchController = useTextEditingController();
    final scrollController = useScrollController();

    // 画面初期化時のデータ読み込み
    useEffect(() {
      Future.microtask(() {
        ref.read(userListNotifierProvider.notifier).loadUsers();
      });
      return null;
    }, const []);

    // スクロール監視によるページネーション
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent * 0.8) {
          // 80%スクロールしたら次のページを読み込み
          ref.read(userListNotifierProvider.notifier).loadMoreUsers();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // 検索処理のデバウンス
    useEffect(() {
      Timer? debounceTimer;
      
      void onSearchChanged() {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 500), () {
          final query = searchController.text.trim();
          if (query.isNotEmpty) {
            ref.read(userListNotifierProvider.notifier).searchUsers(query);
          } else {
            ref.read(userListNotifierProvider.notifier).loadUsers();
          }
        });
      }

      searchController.addListener(onSearchChanged);
      return () {
        debounceTimer?.cancel();
        searchController.removeListener(onSearchChanged);
      };
    }, [searchController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreatePage(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // ユーザーリスト
          Expanded(
            child: userListState.when(
              initial: () => const Center(
                child: Text('Loading users...'),
              ),
              loading: () => const Center(
                child: LoadingIndicator(),
              ),
              loaded: (users, hasNext, isLoadingMore) => RefreshIndicator(
                onRefresh: () => _refreshUsers(ref),
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: users.length + (isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    if (index < users.length) {
                      return UserListTile(
                        user: users[index],
                        onTap: () => _navigateToUserDetail(context, users[index].id),
                      );
                    } else {
                      // ローディングインジケーター
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: LoadingIndicator()),
                      );
                    }
                  },
                ),
              ),
              error: (message) => Center(
                child: ErrorDisplay(
                  message: message,
                  onRetry: () => _retryLoadUsers(ref),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePage(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ユーザーリストの再読み込み
  Future<void> _refreshUsers(WidgetRef ref) async {
    await ref.read(userListNotifierProvider.notifier).refreshUsers();
  }

  /// ユーザーリスト読み込みのリトライ
  void _retryLoadUsers(WidgetRef ref) {
    ref.read(userListNotifierProvider.notifier).loadUsers();
  }

  /// ユーザー詳細画面への遷移
  void _navigateToUserDetail(BuildContext context, String userId) {
    context.push('/users/$userId');
  }

  /// ユーザー作成画面への遷移
  void _navigateToCreatePage(BuildContext context) {
    context.push('/users/create');
  }
}
```

### 3. フォームページの実装
```dart
// pages/user_form_page.dart
class UserFormPage extends HookConsumerWidget {
  const UserFormPage({
    super.key,
    this.userId, // nullの場合は新規作成、値がある場合は編集
  });

  final String? userId;

  bool get isEditing => userId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(userFormNotifierProvider);
    final nameController = useTextEditingController(text: formState.name);
    final emailController = useTextEditingController(text: formState.email);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // 編集モードの場合、既存ユーザー情報でフォームを初期化
    useEffect(() {
      if (isEditing) {
        final userState = ref.read(userNotifierProvider);
        userState.maybeWhen(
          loaded: (user) {
            ref.read(userFormNotifierProvider.notifier).initializeWithUser(user);
          },
          orElse: () {
            // ユーザー情報が読み込まれていない場合は取得
            ref.read(userNotifierProvider.notifier).getUser(userId!);
          },
        );
      }
      return null;
    }, [isEditing, userId]);

    // フォームフィールドの変更をNotifierに反映
    useEffect(() {
      void onNameChanged() {
        ref.read(userFormNotifierProvider.notifier).updateName(nameController.text);
      }
      
      void onEmailChanged() {
        ref.read(userFormNotifierProvider.notifier).updateEmail(emailController.text);
      }

      nameController.addListener(onNameChanged);
      emailController.addListener(onEmailChanged);

      return () {
        nameController.removeListener(onNameChanged);
        emailController.removeListener(onEmailChanged);
      };
    }, [nameController, emailController]);

    // 送信成功時のナビゲーション処理
    ref.listen<UserFormState>(userFormNotifierProvider, (previous, next) {
      if (previous?.isSubmitting == true && next.isSubmitting == false) {
        // 送信完了
        if (next.errors.isEmpty) {
          // 成功時は前の画面に戻る
          context.pop();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Create User'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 名前フィールド
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: formState.getFieldError('name'),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // メールフィールド
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: formState.getFieldError('email'),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ロール選択
              DropdownButtonFormField<UserRole>(
                value: formState.role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (role) {
                  if (role != null) {
                    ref.read(userFormNotifierProvider.notifier).updateRole(role);
                  }
                },
              ),
              const SizedBox(height: 32),

              // 送信ボタン
              ElevatedButton(
                onPressed: formState.isSubmitting || !formState.isValid
                    ? null
                    : () => _submitForm(formKey, ref),
                child: formState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update User' : 'Create User'),
              ),
              
              if (isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _resetForm(ref),
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// フォーム送信処理
  void _submitForm(GlobalKey<FormState> formKey, WidgetRef ref) {
    if (formKey.currentState?.validate() ?? false) {
      if (isEditing) {
        ref.read(userFormNotifierProvider.notifier).submitUpdate(userId!);
      } else {
        ref.read(userFormNotifierProvider.notifier).submitCreate();
      }
    }
  }

  /// フォームのリセット
  void _resetForm(WidgetRef ref) {
    ref.read(userFormNotifierProvider.notifier).clear();
  }

  /// 削除確認ダイアログ
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && userId != null) {
        ref.read(userNotifierProvider.notifier).deleteUser(userId!).then((_) {
          context.pop(); // 削除成功時は前の画面に戻る
        });
      }
    });
  }
}
```

### 4. ダッシュボードページの実装
```dart
// pages/dashboard_page.dart
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userNotifierProvider);
    final userListState = ref.watch(userListNotifierProvider);
    final messageState = ref.watch(messageNotifierProvider);

    // 画面初期化時のデータ読み込み
    useEffect(() {
      Future.microtask(() {
        // 複数のデータを並列で読み込み
        ref.read(userNotifierProvider.notifier).getCurrentUser();
        ref.read(userListNotifierProvider.notifier).loadUsers(limit: 5);
        ref.read(statisticsNotifierProvider.notifier).loadStatistics();
      });
      return null;
    }, const []);

    // 定期的なデータ更新
    useEffect(() {
      final timer = Timer.periodic(const Duration(minutes: 5), (_) {
        ref.read(statisticsNotifierProvider.notifier).loadStatistics();
      });
      
      return () => timer.cancel();
    }, const []);

    // メッセージ状態の監視
    ref.listen<MessageState>(messageNotifierProvider, (previous, next) {
      next.maybeWhen(
        success: (message) => _showMessage(context, message, Colors.green),
        info: (message) => _showMessage(context, message, Colors.blue),
        warning: (message) => _showMessage(context, message, Colors.orange),
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAllData(ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAllData(ref),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ユーザー情報カード
              _buildUserSection(userState),
              const SizedBox(height: 24),

              // 統計情報
              _buildStatisticsSection(ref),
              const SizedBox(height: 24),

              // 最近のユーザー
              _buildRecentUsersSection(context, userListState),
              const SizedBox(height: 24),

              // クイックアクション
              _buildQuickActionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザー情報セクション
  Widget _buildUserSection(UserState userState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: userState.when(
          initial: () => const Text('Loading user info...'),
          loading: () => const LoadingIndicator(),
          loaded: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.name}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          error: (message) => ErrorDisplay(
            message: message,
            onRetry: () {}, // リトライ処理
          ),
        ),
      ),
    );
  }

  /// 統計情報セクション
  Widget _buildStatisticsSection(WidgetRef ref) {
    final statisticsState = ref.watch(statisticsNotifierProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            statisticsState.when(
              initial: () => const Text('Loading statistics...'),
              loading: () => const LoadingIndicator(),
              loaded: (stats) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Users', stats.totalUsers.toString()),
                  _buildStatItem('Active', stats.activeUsers.toString()),
                  _buildStatItem('New', stats.newUsers.toString()),
                ],
              ),
              error: (message) => Text('Error: $message'),
            ),
          ],
        ),
      ),
    );
  }

  /// 統計アイテム
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  /// 最近のユーザーセクション
  Widget _buildRecentUsersSection(
    BuildContext context,
    UserListState userListState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/users'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            userListState.when(
              initial: () => const Text('Loading users...'),
              loading: () => const LoadingIndicator(),
              loaded: (users, _, __) => Column(
                children: users.take(3).map((user) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0]),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () => context.push('/users/${user.id}'),
                  );
                }).toList(),
              ),
              error: (message) => Text('Error: $message'),
            ),
          ],
        ),
      ),
    );
  }

  /// クイックアクションセクション
  Widget _buildQuickActionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'Add User',
                  onTap: () => context.push('/users/create'),
                ),
                _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  onTap: () => context.push('/analytics'),
                ),
                _buildQuickActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// クイックアクションボタン
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  /// 全データの再読み込み
  Future<void> _refreshAllData(WidgetRef ref) async {
    await Future.wait([
      ref.read(userNotifierProvider.notifier).getCurrentUser(),
      ref.read(userListNotifierProvider.notifier).refreshUsers(),
      ref.read(statisticsNotifierProvider.notifier).loadStatistics(),
    ]);
  }

  /// メッセージ表示
  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{画面名}_page.dart`
- **例**: `user_detail_page.dart`, `user_list_page.dart`, `user_form_page.dart`

### クラス名
- **命名形式**: `{画面名}Page`
- **例**: `UserDetailPage`, `UserListPage`, `UserFormPage`

### メソッド名
- **ナビゲーション**: `_navigateTo{画面名}`, `_goTo{画面名}`
- **アクション**: `_handle{アクション名}`, `_on{イベント名}`
- **UI構築**: `_build{セクション名}`, `_create{コンポーネント名}`

## ベストプラクティス

### 1. 適切な状態購読
```dart
// ✅ Good: 必要な状態のみ購読
final userState = ref.watch(userNotifierProvider);
final isLoading = userState.maybeWhen(
  loading: () => true,
  orElse: () => false,
);

// ❌ Bad: 不要な状態の購読
final allStates = ref.watch(allStatesProvider); // 過度な購読
```

### 2. ライフサイクルの適切な管理
```dart
// ✅ Good: useEffectの適切な使用
useEffect(() {
  Future.microtask(() {
    ref.read(userNotifierProvider.notifier).getUser(userId);
  });
  return null;
}, const []); // 依存配列を明示

// ❌ Bad: 依存配列なし
useEffect(() {
  ref.read(userNotifierProvider.notifier).getUser(userId);
  return null;
}); // 依存配列がないため毎回実行される
```

### 3. エラーハンドリング
```dart
// ✅ Good: ref.listenでエラー監視
ref.listen<ErrorState>(errorNotifierProvider, (previous, next) {
  next.maybeWhen(
    error: (message) => _showErrorSnackBar(context, message),
    orElse: () {},
  );
});

// ❌ Bad: try-catch での直接処理
try {
  await someAsyncOperation();
} catch (e) {
  // ページ内で直接エラー処理
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Flutter UI
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ✅ ナビゲーション
import 'package:go_router/go_router.dart';

// ✅ Notifier（状態管理）
import '../../../3_application/3_notifiers/user_notifier.dart';

// ✅ Widgets（UI コンポーネント）
import '../1_widgets/2_molecules/user_info_card.dart';

// ✅ ドメインエンティティ（型定義のみ）
import '../../../1_domain/1_entities/user_entity.dart';
```

### 禁止されるimport
```dart
// ❌ UseCase の直接使用
import '../../../1_domain/3_usecases/get_user_usecase.dart';

// ❌ Repository の直接使用
import '../../../2_infrastructure/3_repositories/user_repository_impl.dart';

// ❌ データソースの直接使用
import '../../../2_infrastructure/2_data_sources/2_remote/user_remote_data_source.dart';
```

## テスト指針

### 1. ページのテスト
```dart
// test/presentation/pages/user_detail_page_test.dart
void main() {
  group('UserDetailPage', () {
    testWidgets('should display user information when loaded', (tester) async {
      // Given
      const user = UserEntity(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
      );

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userNotifierProvider.overrideWith((ref) {
              return UserNotifier()..state = UserState.loaded(user);
            }),
          ],
          child: MaterialApp(
            home: UserDetailPage(userId: '1'),
          ),
        ),
      );

      // Then
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userNotifierProvider.overrideWith((ref) {
              return UserNotifier()..state = UserState.loading();
            }),
          ],
          child: MaterialApp(
            home: UserDetailPage(userId: '1'),
          ),
        ),
      );

      // Then
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });
  });
}
```

## 注意事項

1. **状態管理の分離**: ページはUIの表示とユーザーアクションの処理のみに集中
2. **ライフサイクル管理**: useEffectを適切に使用し、メモリリークを防ぐ
3. **ナビゲーション**: 画面遷移は明確で一貫した方法で実装
4. **エラーハンドリング**: ユーザーにとってわかりやすいエラー表示を心がける
5. **パフォーマンス**: 不要な再構築を避け、効率的なウィジェット構成を実装

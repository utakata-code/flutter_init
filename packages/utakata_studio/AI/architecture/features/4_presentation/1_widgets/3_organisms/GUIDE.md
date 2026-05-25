---
applyTo: 'lib/features/**/4_presentation/1_widgets/3_organisms/**'
---

# Organisms Layer Instructions - 有機体層

## 概要
Organisms層は、Moleculesや他のAtomsを組み合わせて、複雑で機能的なUIセクションを構築します。ページの特定のセクションや、独立した機能的なブロックを表現し、アプリケーションの主要なUI構成要素となります。

## 役割と責務

### ✅ すべきこと
- **機能セクションの実装**: ページの主要セクション（リスト、フォーム、ダッシュボードなど）の構築
- **Molecules/Atomsの統合**: 複数のコンポーネントを組み合わせた複雑なUI構造の実装
- **状態の橋渡し**: Pageから受け取った状態をMoleculesやAtomsに適切に分配
- **レイアウト管理**: セクション内の複雑なレイアウトとUI階層の制御

### ❌ してはいけないこと
- **独立した状態管理**: 内部での複雑な状態管理や副作用の実行
- **直接的なデータ操作**: APIアクセスやビジネスロジックの実装
- **ナビゲーション処理**: 画面遷移の直接実行（コールバックとして上位に委譲）
- **ページレベルの責務**: 画面全体の制御や管理

## 実装ガイドライン

### 1. ユーザーリスト表示
```dart
// widgets/3_organisms/user_list_view.dart
import 'package:flutter/material.dart';
import '../../../1_domain/1_entities/user_entity.dart';
import '../2_molecules/user_info_card.dart';
import '../2_molecules/search_bar.dart';
import '../1_atoms/loading_indicator.dart';
import '../1_atoms/error_display.dart';

/// ユーザーリスト表示オーガニズム
class UserListView extends StatelessWidget {
  const UserListView({
    super.key,
    required this.users,
    required this.isLoading,
    this.error,
    this.searchQuery = '',
    this.onUserTap,
    this.onUserEdit,
    this.onUserMessage,
    this.onSearch,
    this.onRefresh,
    this.onLoadMore,
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.emptyMessage = 'No users found',
    this.showSearch = true,
  });

  final List<UserEntity> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final Function(UserEntity)? onUserTap;
  final Function(UserEntity)? onUserEdit;
  final Function(UserEntity)? onUserMessage;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String emptyMessage;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 検索バー
        if (showSearch) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search users...',
              onSearch: onSearch,
              initialValue: searchQuery,
            ),
          ),
        ],

        // メインコンテンツ
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  /// メインコンテンツの構築
  Widget _buildContent() {
    // ローディング状態
    if (isLoading && users.isEmpty) {
      return const Center(
        child: LoadingIndicator(
          size: LoadingSize.large,
          message: 'Loading users...',
        ),
      );
    }

    // エラー状態
    if (error != null && users.isEmpty) {
      return Center(
        child: ErrorDisplay(
          message: error!,
          onRetry: onRefresh,
        ),
      );
    }

    // 空状態
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    // ユーザーリスト
    return _buildUserList();
  }

  /// 空状態の構築
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ユーザーリストの構築
  Widget _buildUserList() {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // 無限スクロールの実装
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.extentAfter < 200 &&
              hasNextPage &&
              !isLoadingMore) {
            onLoadMore?.call();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index < users.length) {
              return _buildUserItem(users[index]);
            } else {
              // ローディングインジケーター
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: LoadingIndicator(size: LoadingSize.medium),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// ユーザーアイテムの構築
  Widget _buildUserItem(UserEntity user) {
    return UserInfoCard(
      user: user,
      variant: UserCardVariant.standard,
      onTap: () => onUserTap?.call(user),
      onEdit: onUserEdit != null ? () => onUserEdit!(user) : null,
      onMessage: onUserMessage != null ? () => onUserMessage!(user) : null,
      showActions: onUserEdit != null || onUserMessage != null,
      showBadge: user.unreadCount > 0,
    );
  }
}
```

### 2. ダッシュボード統計セクション
```dart
// widgets/3_organisms/dashboard_statistics.dart
import 'package:flutter/material.dart';
import '../2_molecules/statistics_card.dart';
import '../1_atoms/loading_indicator.dart';
import '../1_atoms/error_display.dart';

/// ダッシュボード統計セクション
class DashboardStatistics extends StatelessWidget {
  const DashboardStatistics({
    super.key,
    required this.statistics,
    this.isLoading = false,
    this.error,
    this.onStatisticTap,
    this.onRefresh,
  });

  final List<StatisticItem> statistics;
  final bool isLoading;
  final String? error;
  final Function(StatisticItem)? onStatisticTap;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        _buildSectionHeader(context),
        const SizedBox(height: 16),

        // 統計コンテンツ
        _buildStatisticsContent(),
      ],
    );
  }

  /// セクションヘッダーの構築
  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Statistics',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh statistics',
          ),
      ],
    );
  }

  /// 統計コンテンツの構築
  Widget _buildStatisticsContent() {
    // エラー状態
    if (error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: ErrorDisplay(
            message: error!,
            onRetry: onRefresh,
          ),
        ),
      );
    }

    // ローディング状態
    if (isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: LoadingIndicator(
            size: LoadingSize.large,
            message: 'Loading statistics...',
          ),
        ),
      );
    }

    // 統計グリッド
    return _buildStatisticsGrid();
  }

  /// 統計グリッドの構築
  Widget _buildStatisticsGrid() {
    if (statistics.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No statistics available'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: statistics.length,
      itemBuilder: (context, index) {
        final statistic = statistics[index];
        return StatisticsCard(
          title: statistic.title,
          value: statistic.value,
          subtitle: statistic.subtitle,
          icon: statistic.icon,
          trend: statistic.trend,
          color: statistic.color,
          onTap: onStatisticTap != null
              ? () => onStatisticTap!(statistic)
              : null,
        );
      },
    );
  }
}

/// 統計アイテム
class StatisticItem {
  const StatisticItem({
    required this.id,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.color,
  });

  final String id;
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StatisticsTrend? trend;
  final Color? color;
}
```

### 3. フォームセクション
```dart
// widgets/3_organisms/user_form_section.dart
import 'package:flutter/material.dart';
import '../2_molecules/form_field_group.dart';
import '../1_atoms/custom_button.dart';
import '../1_atoms/loading_indicator.dart';

/// ユーザーフォームセクション
class UserFormSection extends StatelessWidget {
  const UserFormSection({
    super.key,
    required this.formKey,
    required this.personalInfo,
    required this.contactInfo,
    required this.preferences,
    this.isSubmitting = false,
    this.submitLabel = 'Save',
    this.onSubmit,
    this.onCancel,
    this.errors = const {},
  });

  final GlobalKey<FormState> formKey;
  final FormFieldGroup personalInfo;
  final FormFieldGroup contactInfo;
  final FormFieldGroup preferences;
  final bool isSubmitting;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 個人情報セクション
          personalInfo,
          const SizedBox(height: 24),

          // 連絡先情報セクション
          contactInfo,
          const SizedBox(height: 24),

          // 設定セクション
          preferences,
          const SizedBox(height: 32),

          // 送信ボタンセクション
          _buildSubmitSection(),
        ],
      ),
    );
  }

  /// 送信セクションの構築
  Widget _buildSubmitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // エラーメッセージ
        if (errors.containsKey('general')) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errors['general']!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ボタン行
        Row(
          children: [
            // キャンセルボタン
            if (onCancel != null)
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: isSubmitting ? null : onCancel,
                  variant: ButtonVariant.outlined,
                ),
              ),

            if (onCancel != null && onSubmit != null)
              const SizedBox(width: 16),

            // 送信ボタン
            if (onSubmit != null)
              Expanded(
                flex: onCancel != null ? 1 : 1,
                child: CustomButton(
                  text: submitLabel,
                  onPressed: isSubmitting ? null : onSubmit,
                  variant: ButtonVariant.primary,
                  isLoading: isSubmitting,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

### 4. 設定パネル
```dart
// widgets/3_organisms/settings_panel.dart
import 'package:flutter/material.dart';
import '../2_molecules/custom_list_tile.dart';
import '../1_atoms/custom_button.dart';

/// 設定パネル
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.sections,
    this.onSectionTap,
    this.onSignOut,
    this.userAvatarUrl,
    this.userName,
    this.userEmail,
  });

  final List<SettingsSection> sections;
  final Function(SettingsItem)? onSectionTap;
  final VoidCallback? onSignOut;
  final String? userAvatarUrl;
  final String? userName;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ユーザープロフィールヘッダー
        if (userName != null && userEmail != null)
          _buildUserHeader(context),

        // 設定セクション
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: sections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _buildSettingsSection(sections[index]);
            },
          ),
        ),

        // サインアウトボタン
        if (onSignOut != null)
          _buildSignOutSection(),
      ],
    );
  }

  /// ユーザーヘッダーの構築
  Widget _buildUserHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: CustomListTile(
        avatarUrl: userAvatarUrl,
        avatarName: userName,
        title: userName,
        subtitle: userEmail,
        showDivider: false,
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // プロフィール編集の処理は上位に委譲
          },
        ),
      ),
    );
  }

  /// 設定セクションの構築
  Widget _buildSettingsSection(SettingsSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションタイトル
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // セクションアイテム
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: section.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == section.items.length - 1;

              return CustomListTile(
                leading: Icon(item.icon),
                title: item.title,
                subtitle: item.subtitle,
                trailing: _buildTrailing(item),
                onTap: onSectionTap != null
                    ? () => onSectionTap!(item)
                    : null,
                showDivider: !isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// トレーリングウィジェットの構築
  Widget? _buildTrailing(SettingsItem item) {
    switch (item.type) {
      case SettingsItemType.navigation:
        return const Icon(Icons.arrow_forward_ios);
      
      case SettingsItemType.toggle:
        return Switch(
          value: item.value as bool? ?? false,
          onChanged: item.onChanged != null
              ? (value) => item.onChanged!(value)
              : null,
        );
      
      case SettingsItemType.text:
        return Text(
          item.value?.toString() ?? '',
          style: const TextStyle(
            color: Colors.grey,
          ),
        );
      
      case SettingsItemType.action:
        return null;
    }
  }

  /// サインアウトセクションの構築
  Widget _buildSignOutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomButton(
        text: 'Sign Out',
        onPressed: onSignOut,
        variant: ButtonVariant.danger,
        fullWidth: true,
        icon: Icons.logout,
      ),
    );
  }
}

/// 設定セクション
class SettingsSection {
  const SettingsSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<SettingsItem> items;
}

/// 設定アイテム
class SettingsItem {
  const SettingsItem({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.icon,
    this.value,
    this.onChanged,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final SettingsItemType type;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
}

/// 設定アイテムタイプ
enum SettingsItemType {
  navigation,
  toggle,
  text,
  action,
}
```

### 5. フィルターパネル
```dart
// widgets/3_organisms/filter_panel.dart
import 'package:flutter/material.dart';
import '../2_molecules/form_field_group.dart';
import '../1_atoms/custom_button.dart';

/// フィルターパネル
class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.filters,
    this.onApply,
    this.onReset,
    this.onClose,
    this.appliedFiltersCount = 0,
  });

  final List<FilterGroup> filters;
  final Function(Map<String, dynamic>)? onApply;
  final VoidCallback? onReset;
  final VoidCallback? onClose;
  final int appliedFiltersCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          _buildHeader(theme),

          // フィルター内容
          Expanded(
            child: _buildFilterContent(),
          ),

          // フッター
          _buildFooter(),
        ],
      ),
    );
  }

  /// ヘッダーの構築
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (appliedFiltersCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appliedFiltersCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  /// フィルター内容の構築
  Widget _buildFilterContent() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _buildFilterGroup(filters[index]);
      },
    );
  }

  /// フィルターグループの構築
  Widget _buildFilterGroup(FilterGroup filterGroup) {
    return FormFieldGroup(
      title: filterGroup.title,
      subtitle: filterGroup.subtitle,
      fields: filterGroup.fields,
    );
  }

  /// フッターの構築
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // リセットボタン
          if (onReset != null)
            Expanded(
              child: CustomButton(
                text: 'Reset',
                onPressed: appliedFiltersCount > 0 ? onReset : null,
                variant: ButtonVariant.outlined,
              ),
            ),

          if (onReset != null && onApply != null)
            const SizedBox(width: 16),

          // 適用ボタン
          if (onApply != null)
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Apply Filters',
                onPressed: () => _handleApply(),
                variant: ButtonVariant.primary,
              ),
            ),
        ],
      ),
    );
  }

  /// フィルター適用処理
  void _handleApply() {
    final filterValues = <String, dynamic>{};
    
    for (final group in filters) {
      for (final field in group.fields) {
        // フィールドの値を収集
        switch (field.type) {
          case FormFieldType.text:
            if (field.controller?.text.isNotEmpty ?? false) {
              filterValues[group.id] = field.controller!.text;
            }
            break;
          case FormFieldType.dropdown:
            if (field.selectedValue != null) {
              filterValues[group.id] = field.selectedValue;
            }
            break;
          case FormFieldType.checkbox:
            filterValues[group.id] = field.boolValue ?? false;
            break;
          default:
            break;
        }
      }
    }
    
    onApply?.call(filterValues);
  }
}

/// フィルターグループ
class FilterGroup {
  const FilterGroup({
    required this.id,
    required this.title,
    required this.fields,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<FormFieldItem> fields;
}
```

## 命名規則

### ファイル名
- **命名形式**: `{機能名}_view.dart`, `{機能名}_section.dart`, `{機能名}_panel.dart`
- **例**: `user_list_view.dart`, `dashboard_statistics.dart`, `settings_panel.dart`

### クラス名
- **命名形式**: `{機能名}View`, `{機能名}Section`, `{機能名}Panel`
- **例**: `UserListView`, `DashboardStatistics`, `SettingsPanel`

### プロパティ名
- **状態関連**: `isLoading`, `hasError`, `isEmpty`
- **コールバック**: `on{Action}`, `{verb}Callback`
- **設定**: `show{Feature}`, `enable{Feature}`

## ベストプラクティス

### 1. 適切なコンポーネント組み合わせ
```dart
// ✅ Good: MoleculesとAtomsを効果的に組み合わせ
class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(onSearch: onSearch),     // Molecule
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              return UserInfoCard(         // Molecule
                user: users[index],
                onTap: onUserTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ❌ Bad: 基本要素から独自に構築
class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(/* 独自実装 */),        // Moleculeを使わない
        ListView.builder(
          itemBuilder: (context, index) {
            return Card(/* 独自実装 */);   // Moleculeを使わない
          },
        ),
      ],
    );
  }
}
```

### 2. 状態の適切な委譲
```dart
// ✅ Good: 状態を受け取り、アクションは上位に委譲
class UserListView extends StatelessWidget {
  const UserListView({
    required this.users,
    required this.isLoading,
    this.onUserTap,      // アクションは上位に委譲
    this.onRefresh,      // アクションは上位に委譲
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return LoadingIndicator();
    return ListView(/* ... */);
  }
}

// ❌ Bad: 内部で状態管理
class UserListView extends StatefulWidget {
  @override
  _UserListViewState createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  bool isLoading = false;
  
  void loadUsers() async {
    setState(() => isLoading = true);
    // データ取得処理（Organismの責務外）
  }
}
```

### 3. 適切な粒度とスコープ
```dart
// ✅ Good: 明確な機能セクションとして設計
class DashboardStatistics extends StatelessWidget {
  // 統計表示という明確な機能セクション
}

class UserListView extends StatelessWidget {
  // ユーザーリスト表示という明確な機能セクション
}

// ❌ Bad: 責務が曖昧または過大
class EntirePageContent extends StatelessWidget {
  // ページ全体を含む（Pageの責務）
}

class ButtonAndTextWidget extends StatelessWidget {
  // 機能的なまとまりがない（Moleculeレベル）
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Flutter基本
import 'package:flutter/material.dart';

// ✅ 下位レイヤー
import '../2_molecules/user_info_card.dart';
import '../1_atoms/loading_indicator.dart';

// ✅ エンティティ（型定義のみ）
import '../../../1_domain/1_entities/user_entity.dart';
```

### 禁止されるimport
```dart
// ❌ 同層・上位層
import '../3_organisms/user_dashboard.dart';
import '../../../2_pages/user_list_page.dart';

// ❌ ビジネスロジック
import '../../../3_application/3_notifiers/user_notifier.dart';
import '../../../1_domain/3_usecases/get_user_usecase.dart';
```

## テスト指針

### 1. Organismsのテスト
```dart
// test/presentation/widgets/organisms/user_list_view_test.dart
void main() {
  group('UserListView', () {
    const testUsers = [
      UserEntity(id: '1', name: 'User 1', email: 'user1@example.com'),
      UserEntity(id: '2', name: 'User 2', email: 'user2@example.com'),
    ];

    testWidgets('should display user list when loaded', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListView(
              users: testUsers,
              isLoading: false,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 2'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListView(
              users: const [],
              isLoading: true,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('should call onUserTap when user is tapped', (tester) async {
      // Given
      UserEntity? tappedUser;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserListView(
              users: testUsers,
              isLoading: false,
              onUserTap: (user) => tappedUser = user,
            ),
          ),
        ),
      );

      // When
      await tester.tap(find.text('User 1'));
      await tester.pump();

      // Then
      expect(tappedUser?.id, equals('1'));
    });
  });
}
```

## 注意事項

1. **機能的まとまり**: 明確な機能セクションとして設計し、責務を明確にする
2. **状態の委譲**: 内部状態は最小限に留め、主要な状態は上位から受け取る
3. **アクションの委譲**: ユーザーアクションは上位にコールバックとして委譲する
4. **コンポーネント活用**: 下位レイヤーのコンポーネントを積極的に活用する
5. **レイアウト責任**: セクション内の複雑なレイアウトや配置制御を担う

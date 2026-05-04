---
applyTo: 'lib/features/**/4_presentation/1_widgets/2_molecules/**'
---

# Molecules Layer Instructions - 分子層

## 概要
Molecules層は、複数のAtoms（原子）を組み合わせて、より意味のある機能単位のUIコンポーネントを構築します。再利用可能でありながら、特定の機能に特化した中間レベルのコンポーネントです。

## 役割と責務

### ✅ すべきこと
- **Atomsの組み合わせ**: 複数の基本コンポーネントを組み合わせた機能的なUI単位の実装
- **特定機能のUI表現**: ユーザー情報表示、フォーム要素、リストアイテムなど意味のある機能単位
- **レイアウトの実装**: Atoms間の配置、間隔、整列などのレイアウト制御
- **再利用可能な設計**: 複数の画面で使用できる汎用性を持つ実装

### ❌ してはいけないこと
- **ビジネスロジック**: ドメインロジックや複雑な状態管理の実装
- **直接的なデータアクセス**: APIやデータベースへの直接アクセス
- **画面レベルの制御**: ナビゲーションや画面全体の状態管理
- **複雑な状態管理**: 内部状態は最小限に留める

## 実装ガイドライン

### 1. ユーザー情報カード
```dart
// widgets/2_molecules/user_info_card.dart
import 'package:flutter/material.dart';
import '../../../1_domain/1_entities/user_entity.dart';
import '../1_atoms/custom_avatar.dart';
import '../1_atoms/custom_button.dart';
import '../1_atoms/custom_badge.dart';

/// ユーザー情報カードコンポーネント
class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onMessage,
    this.showActions = true,
    this.showBadge = false,
    this.variant = UserCardVariant.standard,
  });

  final UserEntity user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMessage;
  final bool showActions;
  final bool showBadge;
  final UserCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getCardConfig();

    return Card(
      elevation: config.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: Padding(
          padding: config.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヘッダー部分（アバターとメイン情報）
              _buildHeader(theme),
              
              if (variant == UserCardVariant.detailed) ...[
                const SizedBox(height: 12),
                _buildDetailedInfo(theme),
              ],
              
              if (showActions) ...[
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分の構築
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // アバター
        CustomBadge(
          showBadge: showBadge,
          count: user.unreadCount,
          child: CustomAvatar(
            imageUrl: user.avatarUrl,
            name: user.name,
            size: variant == UserCardVariant.compact 
                ? AvatarSize.small 
                : AvatarSize.medium,
          ),
        ),
        const SizedBox(width: 12),
        
        // メイン情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 名前
              Text(
                user.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // メールアドレス
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (variant != UserCardVariant.compact) ...[
                const SizedBox(height: 4),
                _buildStatusChip(theme),
              ],
            ],
          ),
        ),
        
        // ステータスインジケーター
        if (variant == UserCardVariant.compact)
          _buildStatusIndicator(theme),
      ],
    );
  }

  /// 詳細情報の構築
  Widget _buildDetailedInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.department != null) ...[
            _buildInfoRow(
              icon: Icons.business,
              label: 'Department',
              value: user.department!,
              theme: theme,
            ),
            const SizedBox(height: 8),
          ],
          
          if (user.role != null) ...[
            _buildInfoRow(
              icon: Icons.work_outline,
              label: 'Role',
              value: user.role!.displayName,
              theme: theme,
            ),
            const SizedBox(height: 8),
          ],
          
          _buildInfoRow(
            icon: Icons.schedule,
            label: 'Last Seen',
            value: _formatLastSeen(user.lastSeenAt),
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// 情報行の構築
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// ステータスチップの構築
  Widget _buildStatusChip(ThemeData theme) {
    final statusConfig = _getStatusConfig(theme);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusConfig.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// ステータスインジケーターの構築
  Widget _buildStatusIndicator(ThemeData theme) {
    final statusConfig = _getStatusConfig(theme);
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        shape: BoxShape.circle,
      ),
    );
  }

  /// アクションボタンの構築
  Widget _buildActions() {
    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: CustomButton(
              text: 'Edit',
              onPressed: onEdit,
              variant: ButtonVariant.outlined,
              size: ButtonSize.small,
            ),
          ),
        
        if (onEdit != null && onMessage != null)
          const SizedBox(width: 8),
        
        if (onMessage != null)
          Expanded(
            child: CustomButton(
              text: 'Message',
              onPressed: onMessage,
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
              icon: Icons.message,
            ),
          ),
      ],
    );
  }

  /// カード設定の取得
  _CardConfig _getCardConfig() {
    switch (variant) {
      case UserCardVariant.compact:
        return const _CardConfig(
          elevation: 1,
          borderRadius: 8,
          padding: EdgeInsets.all(12),
        );
      case UserCardVariant.standard:
        return const _CardConfig(
          elevation: 2,
          borderRadius: 12,
          padding: EdgeInsets.all(16),
        );
      case UserCardVariant.detailed:
        return const _CardConfig(
          elevation: 3,
          borderRadius: 16,
          padding: EdgeInsets.all(20),
        );
    }
  }

  /// ステータス設定の取得
  _StatusConfig _getStatusConfig(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    switch (user.status) {
      case UserStatus.active:
        return _StatusConfig(
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      case UserStatus.inactive:
        return _StatusConfig(
          backgroundColor: colorScheme.outline,
          textColor: colorScheme.onSurface,
        );
      case UserStatus.pending:
        return _StatusConfig(
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      case UserStatus.suspended:
        return _StatusConfig(
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
    }
  }

  /// 最終ログイン時刻のフォーマット
  String _formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeenAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// ユーザーカードバリアント
enum UserCardVariant {
  compact,
  standard,
  detailed,
}

/// カード設定
class _CardConfig {
  const _CardConfig({
    required this.elevation,
    required this.borderRadius,
    required this.padding,
  });

  final double elevation;
  final double borderRadius;
  final EdgeInsets padding;
}

/// ステータス設定
class _StatusConfig {
  const _StatusConfig({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
}
```

### 2. 検索バー
```dart
// widgets/2_molecules/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../1_atoms/custom_text_field.dart';
import '../1_atoms/custom_button.dart';

/// 検索バーコンポーネント
class SearchBar extends HookWidget {
  const SearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onSearch,
    this.onClear,
    this.onFilterTap,
    this.showFilter = false,
    this.initialValue = '',
    this.debounceMs = 500,
  });

  final String hintText;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final bool showFilter;
  final String initialValue;
  final int debounceMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = useTextEditingController(text: initialValue);
    final debounceTimer = useRef<Timer?>(null);

    // 検索テキストの変更を監視
    useEffect(() {
      void onTextChanged() {
        final query = controller.text.trim();
        
        // 既存のタイマーをキャンセル
        debounceTimer.value?.cancel();
        
        // 新しいタイマーを設定
        debounceTimer.value = Timer(Duration(milliseconds: debounceMs), () {
          onSearch?.call(query);
        });
      }

      controller.addListener(onTextChanged);
      
      return () {
        debounceTimer.value?.cancel();
        controller.removeListener(onTextChanged);
      };
    }, [controller, onSearch, debounceMs]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 検索アイコン
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          
          // 検索入力フィールド
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          
          // クリアボタン
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onClear?.call();
              },
              child: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
          
          // フィルターボタン
          if (showFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 3. フォームフィールドグループ
```dart
// widgets/2_molecules/form_field_group.dart
import 'package:flutter/material.dart';
import '../1_atoms/custom_text_field.dart';

/// フォームフィールドグループコンポーネント
class FormFieldGroup extends StatelessWidget {
  const FormFieldGroup({
    super.key,
    required this.title,
    required this.fields,
    this.subtitle,
    this.isRequired = false,
    this.errorText,
  });

  final String title;
  final String? subtitle;
  final List<FormFieldItem> fields;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // グループタイトル
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        
        // サブタイトル
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // フィールド一覧
        ...fields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          final isLast = index == fields.length - 1;
          
          return Column(
            children: [
              _buildField(field, theme),
              if (!isLast) const SizedBox(height: 16),
            ],
          );
        }),
        
        // エラーメッセージ
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  /// フィールドの構築
  Widget _buildField(FormFieldItem field, ThemeData theme) {
    switch (field.type) {
      case FormFieldType.text:
        return CustomTextField(
          controller: field.controller,
          labelText: field.label,
          hintText: field.hint,
          errorText: field.errorText,
          keyboardType: field.keyboardType,
          obscureText: field.obscureText,
          enabled: field.enabled,
          validator: field.validator,
          onChanged: field.onChanged,
        );
        
      case FormFieldType.dropdown:
        return DropdownButtonFormField<String>(
          value: field.selectedValue,
          decoration: InputDecoration(
            labelText: field.label,
            errorText: field.errorText,
            border: const OutlineInputBorder(),
          ),
          items: field.options?.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: field.enabled ? field.onDropdownChanged : null,
        );
        
      case FormFieldType.checkbox:
        return CheckboxListTile(
          title: Text(field.label),
          subtitle: field.hint != null ? Text(field.hint!) : null,
          value: field.boolValue ?? false,
          onChanged: field.enabled ? field.onBoolChanged : null,
          controlAffinity: ListTileControlAffinity.leading,
        );
        
      case FormFieldType.radio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...field.options?.map((option) {
              return RadioListTile<String>(
                title: Text(option.label),
                value: option.value,
                groupValue: field.selectedValue,
                onChanged: field.enabled ? field.onDropdownChanged : null,
              );
            }) ?? [],
          ],
        );
    }
  }
}

/// フォームフィールドアイテム
class FormFieldItem {
  const FormFieldItem({
    required this.type,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.options,
    this.selectedValue,
    this.onDropdownChanged,
    this.boolValue,
    this.onBoolChanged,
  });

  final FormFieldType type;
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<DropdownOption>? options;
  final String? selectedValue;
  final ValueChanged<String?>? onDropdownChanged;
  final bool? boolValue;
  final ValueChanged<bool?>? onBoolChanged;
}

/// フォームフィールドタイプ
enum FormFieldType {
  text,
  dropdown,
  checkbox,
  radio,
}

/// ドロップダウンオプション
class DropdownOption {
  const DropdownOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}
```

### 4. 統計カード
```dart
// widgets/2_molecules/statistics_card.dart
import 'package:flutter/material.dart';
import '../1_atoms/loading_indicator.dart';

/// 統計カードコンポーネント
class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.isLoading = false,
    this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final StatisticsTrend? trend;
  final bool isLoading;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withOpacity(0.1),
                cardColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー（タイトルとアイコン）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (icon != null)
                    Icon(
                      icon,
                      color: cardColor,
                      size: 24,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 値の表示
              if (isLoading)
                const LoadingIndicator(size: LoadingSize.small)
              else
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              
              // サブタイトルとトレンド
              if (subtitle != null || trend != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    if (trend != null)
                      _buildTrendIndicator(theme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// トレンドインジケーターの構築
  Widget _buildTrendIndicator(ThemeData theme) {
    if (trend == null) return const SizedBox.shrink();

    final isPositive = trend!.isPositive;
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend!.percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計トレンド
class StatisticsTrend {
  const StatisticsTrend({
    required this.percentage,
    required this.isPositive,
  });

  final double percentage;
  final bool isPositive;
}
```

### 5. リストタイル
```dart
// widgets/2_molecules/custom_list_tile.dart
import 'package:flutter/material.dart';
import '../1_atoms/custom_avatar.dart';
import '../1_atoms/custom_badge.dart';

/// カスタムリストタイルコンポーネント
class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.avatarUrl,
    this.avatarName,
    this.badgeCount,
    this.showDivider = true,
    this.dense = false,
  });

  final Widget? leading;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? avatarUrl;
  final String? avatarName;
  final int? badgeCount;
  final bool showDivider;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && (avatarUrl != null || avatarName != null)) {
      leadingWidget = CustomBadge(
        count: badgeCount,
        showBadge: badgeCount != null && badgeCount! > 0,
        child: CustomAvatar(
          imageUrl: avatarUrl,
          name: avatarName,
          size: dense ? AvatarSize.small : AvatarSize.medium,
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          leading: leadingWidget,
          title: title != null
              ? Text(
                  title!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              : null,
          trailing: trailing,
          onTap: onTap,
          onLongPress: onLongPress,
          dense: dense,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        
        if (showDivider)
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withOpacity(0.2),
            indent: leadingWidget != null ? 72 : 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
```

## 命名規則

### ファイル名
- **命名形式**: `{機能名}_molecule.dart` または `{コンポーネント名}.dart`
- **例**: `user_info_card.dart`, `search_bar.dart`, `form_field_group.dart`

### クラス名
- **命名形式**: `{機能名}Card`, `{機能名}Bar`, `{機能名}Group`
- **例**: `UserInfoCard`, `SearchBar`, `FormFieldGroup`

### プロパティ名
- **表示制御**: `show{機能名}`, `enable{機能名}`, `hide{機能名}`
- **コールバック**: `on{アクション名}`, `{動詞}Callback`
- **バリアント**: `variant`, `type`, `style`

## ベストプラクティス

### 1. Atomsの適切な組み合わせ
```dart
// ✅ Good: Atomsを組み合わせて機能単位を構築
class UserInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          CustomAvatar(imageUrl: user.avatarUrl), // Atom
          CustomButton(                          // Atom
            text: 'Edit',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

// ❌ Bad: 基本的なUI要素をゼロから実装
class UserInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: CircleAvatar(/* 独自実装 */), // Atomsを使わない
    );
  }
}
```

### 2. 適切な責務の分離
```dart
// ✅ Good: UI構築に集中
class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    required this.user,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(user.name),
          if (onEdit != null)
            CustomButton(
              text: 'Edit',
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}

// ❌ Bad: ビジネスロジックを含む
class UserInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ビジネスロジックは不適切
    final canEdit = user.role == UserRole.admin && user.isActive;
    
    return Card(/* ... */);
  }
}
```

### 3. 再利用性の確保
```dart
// ✅ Good: 汎用的で再利用可能
class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    required this.title,
    required this.value,
    this.color,
    this.onTap,
  });
  // 様々な統計情報で使用可能
}

// ❌ Bad: 特定の用途に限定
class UserCountCard extends StatelessWidget {
  // ユーザー数専用で他に転用できない
}
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Flutter基本
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// ✅ Atomsレイヤー
import '../1_atoms/custom_button.dart';
import '../1_atoms/custom_avatar.dart';

// ✅ エンティティ（型定義のみ）
import '../../../1_domain/1_entities/user_entity.dart';
```

### 禁止されるimport
```dart
// ❌ 上位層・同層のMolecules
import '../2_molecules/user_card.dart';
import '../3_organisms/user_list.dart';

// ❌ 状態管理・ビジネスロジック
import '../../../3_application/3_notifiers/user_notifier.dart';
import '../../../1_domain/3_usecases/get_user_usecase.dart';
```

## テスト指針

### 1. Moleculesのテスト
```dart
// test/presentation/widgets/molecules/user_info_card_test.dart
void main() {
  group('UserInfoCard', () {
    const testUser = UserEntity(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
    );

    testWidgets('should display user information', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserInfoCard(user: testUser),
          ),
        ),
      );

      // Then
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should call onEdit when edit button is tapped', (tester) async {
      // Given
      var editCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserInfoCard(
              user: testUser,
              onEdit: () => editCalled = true,
            ),
          ),
        ),
      );

      // When
      await tester.tap(find.text('Edit'));
      await tester.pump();

      // Then
      expect(editCalled, isTrue);
    });
  });
}
```

## 注意事項

1. **Atomsの活用**: 基本コンポーネントは既存のAtomsを使用し、重複を避ける
2. **機能の焦点**: 明確な機能単位でコンポーネントを設計する
3. **再利用性**: 特定の画面に依存しない汎用的な設計を心がける
4. **プロパティ設計**: 必要十分なプロパティで柔軟性と簡潔性を両立する
5. **レイアウト制御**: Atoms間の適切な配置と間隔を責任を持つ

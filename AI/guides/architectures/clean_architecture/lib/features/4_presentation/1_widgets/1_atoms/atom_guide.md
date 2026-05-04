---
applyTo: 'lib/features/**/4_presentation/1_widgets/1_atoms/**'
---

# Atoms Layer Instructions - 原子層

## 概要
Atoms層は、最小単位のUIコンポーネントを定義します。再利用可能で独立性が高く、他のコンポーネントから合成される基本的なUIエレメントです。状態を持たず、プロパティのみで動作を制御します。

## 役割と責務

### ✅ すべきこと
- **基本UIエレメントの実装**: ボタン、テキスト、アイコンなどの最小単位コンポーネント
- **スタイリングの統一**: アプリケーション全体で一貫したデザインの提供
- **プロパティベースの制御**: 外部から渡されるプロパティのみで動作を決定
- **再利用性の確保**: 複数の画面・機能で使い回せる汎用的な実装

### ❌ してはいけないこと
- **状態管理**: 内部状態を持つ（StatefulWidgetの使用は基本的に禁止）
- **ビジネスロジック**: ドメインに関連するロジックの実装
- **外部データアクセス**: APIやデータベースへの直接アクセス
- **複雑な合成**: 複数のAtomsの組み合わせ（Moleculesの責務）

## 実装ガイドライン

### 1. 基本ボタンコンポーネント
```dart
// widgets/1_atoms/custom_button.dart
import 'package:flutter/material.dart';

/// カスタムボタンコンポーネント
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.fullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = _getButtonStyle(theme);
    final textStyle = _getTextStyle(theme);
    final buttonSize = _getButtonSize();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: buttonSize.iconSize,
            width: buttonSize.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingColor(theme),
              ),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: buttonSize.iconSize),
                SizedBox(width: buttonSize.spacing),
              ],
              Text(text, style: textStyle),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: buttonSize.height,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }

  /// ボタンスタイルを取得
  ButtonStyle _getButtonStyle(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final buttonSize = _getButtonSize();

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          padding: buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onSecondary,
          backgroundColor: colorScheme.secondary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          padding: buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          padding: buttonSize.padding,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          padding: buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ButtonVariant.danger:
        return ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onError,
          backgroundColor: colorScheme.error,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          padding: buttonSize.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
    }
  }

  /// テキストスタイルを取得
  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case ButtonSize.small:
        return theme.textTheme.labelSmall!;
      case ButtonSize.medium:
        return theme.textTheme.labelMedium!;
      case ButtonSize.large:
        return theme.textTheme.labelLarge!;
    }
  }

  /// ボタンサイズを取得
  _ButtonSize _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return const _ButtonSize(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          iconSize: 16,
          spacing: 4,
        );
      case ButtonSize.medium:
        return const _ButtonSize(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          iconSize: 18,
          spacing: 6,
        );
      case ButtonSize.large:
        return const _ButtonSize(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          iconSize: 20,
          spacing: 8,
        );
    }
  }

  /// ローディング時の色を取得
  Color _getLoadingColor(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    switch (variant) {
      case ButtonVariant.primary:
        return colorScheme.onPrimary;
      case ButtonVariant.secondary:
        return colorScheme.onSecondary;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return colorScheme.primary;
      case ButtonVariant.danger:
        return colorScheme.onError;
    }
  }
}

/// ボタンバリアント
enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
}

/// ボタンサイズ
enum ButtonSize {
  small,
  medium,
  large,
}

/// ボタンサイズ設定
class _ButtonSize {
  const _ButtonSize({
    required this.height,
    required this.padding,
    required this.iconSize,
    required this.spacing,
  });

  final double height;
  final EdgeInsets padding;
  final double iconSize;
  final double spacing;
}
```

### 2. テキスト入力フィールド
```dart
// widgets/1_atoms/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// カスタムテキストフィールドコンポーネント
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withOpacity(0.38),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled
            ? colorScheme.surface
            : colorScheme.surface.withOpacity(0.38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.38),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
```

### 3. ローディングインジケーター
```dart
// widgets/1_atoms/loading_indicator.dart
import 'package:flutter/material.dart';

/// ローディングインジケーターコンポーネント
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
  });

  final LoadingSize size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingConfig = _getLoadingConfig();
    final indicatorColor = color ?? theme.colorScheme.primary;

    Widget indicator = SizedBox(
      width: loadingConfig.size,
      height: loadingConfig.size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? loadingConfig.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(height: loadingConfig.spacing),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }

  /// ローディング設定を取得
  _LoadingConfig _getLoadingConfig() {
    switch (size) {
      case LoadingSize.small:
        return const _LoadingConfig(
          size: 16,
          strokeWidth: 2,
          spacing: 8,
        );
      case LoadingSize.medium:
        return const _LoadingConfig(
          size: 24,
          strokeWidth: 3,
          spacing: 12,
        );
      case LoadingSize.large:
        return const _LoadingConfig(
          size: 32,
          strokeWidth: 4,
          spacing: 16,
        );
    }
  }
}

/// ローディングサイズ
enum LoadingSize {
  small,
  medium,
  large,
}

/// ローディング設定
class _LoadingConfig {
  const _LoadingConfig({
    required this.size,
    required this.strokeWidth,
    required this.spacing,
  });

  final double size;
  final double strokeWidth;
  final double spacing;
}
```

### 4. エラー表示コンポーネント
```dart
// widgets/1_atoms/error_display.dart
import 'package:flutter/material.dart';

/// エラー表示コンポーネント
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel = 'Retry',
    this.variant = ErrorVariant.standard,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String retryLabel;
  final ErrorVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getErrorConfig(theme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: config.iconColor,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: config.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: ElevatedButton.styleFrom(
                foregroundColor: config.buttonForegroundColor,
                backgroundColor: config.buttonBackgroundColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// エラー設定を取得
  _ErrorConfig _getErrorConfig(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case ErrorVariant.standard:
        return _ErrorConfig(
          backgroundColor: colorScheme.errorContainer,
          borderColor: colorScheme.error.withOpacity(0.3),
          iconColor: colorScheme.error,
          textColor: colorScheme.onErrorContainer,
          buttonBackgroundColor: colorScheme.error,
          buttonForegroundColor: colorScheme.onError,
        );
      case ErrorVariant.warning:
        return _ErrorConfig(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.withOpacity(0.3),
          iconColor: Colors.orange,
          textColor: Colors.orange.shade800,
          buttonBackgroundColor: Colors.orange,
          buttonForegroundColor: Colors.white,
        );
      case ErrorVariant.info:
        return _ErrorConfig(
          backgroundColor: colorScheme.surfaceVariant,
          borderColor: colorScheme.outline,
          iconColor: colorScheme.primary,
          textColor: colorScheme.onSurfaceVariant,
          buttonBackgroundColor: colorScheme.primary,
          buttonForegroundColor: colorScheme.onPrimary,
        );
    }
  }
}

/// エラーバリアント
enum ErrorVariant {
  standard,
  warning,
  info,
}

/// エラー設定
class _ErrorConfig {
  const _ErrorConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.buttonBackgroundColor,
    required this.buttonForegroundColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color buttonBackgroundColor;
  final Color buttonForegroundColor;
}
```

### 5. アバターコンポーネント
```dart
// widgets/1_atoms/custom_avatar.dart
import 'package:flutter/material.dart';

/// カスタムアバターコンポーネント
class CustomAvatar extends StatelessWidget {
  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.heroTag,
  });

  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getAvatarConfig();
    final fallbackColor = backgroundColor ?? theme.colorScheme.primary;
    final fallbackTextColor = textColor ?? theme.colorScheme.onPrimary;

    Widget avatar = CircleAvatar(
      radius: config.radius,
      backgroundColor: fallbackColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              _getInitials(name),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fallbackTextColor,
                fontSize: config.fontSize,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );

    if (heroTag != null) {
      avatar = Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  /// アバター設定を取得
  _AvatarConfig _getAvatarConfig() {
    switch (size) {
      case AvatarSize.small:
        return const _AvatarConfig(radius: 16, fontSize: 12);
      case AvatarSize.medium:
        return const _AvatarConfig(radius: 24, fontSize: 16);
      case AvatarSize.large:
        return const _AvatarConfig(radius: 32, fontSize: 20);
      case AvatarSize.extraLarge:
        return const _AvatarConfig(radius: 48, fontSize: 24);
    }
  }

  /// イニシャルを取得
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }
}

/// アバターサイズ
enum AvatarSize {
  small,
  medium,
  large,
  extraLarge,
}

/// アバター設定
class _AvatarConfig {
  const _AvatarConfig({
    required this.radius,
    required this.fontSize,
  });

  final double radius;
  final double fontSize;
}
```

### 6. バッジコンポーネント
```dart
// widgets/1_atoms/custom_badge.dart
import 'package:flutter/material.dart';

/// カスタムバッジコンポーネント
class CustomBadge extends StatelessWidget {
  const CustomBadge({
    super.key,
    required this.child,
    this.count,
    this.text,
    this.showBadge = true,
    this.backgroundColor,
    this.textColor,
    this.size = BadgeSize.medium,
    this.position = BadgePosition.topRight,
  });

  final Widget child;
  final int? count;
  final String? text;
  final bool showBadge;
  final Color? backgroundColor;
  final Color? textColor;
  final BadgeSize size;
  final BadgePosition position;

  @override
  Widget build(BuildContext context) {
    if (!showBadge || (count == null && text == null) || count == 0) {
      return child;
    }

    final theme = Theme.of(context);
    final config = _getBadgeConfig();
    final badgeColor = backgroundColor ?? theme.colorScheme.error;
    final badgeTextColor = textColor ?? theme.colorScheme.onError;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: position.top,
          right: position.right,
          left: position.left,
          bottom: position.bottom,
          child: Container(
            padding: config.padding,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(config.radius),
            ),
            constraints: BoxConstraints(
              minWidth: config.minWidth,
              minHeight: config.minHeight,
            ),
            child: Text(
              _getBadgeText(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeTextColor,
                fontSize: config.fontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// バッジ設定を取得
  _BadgeConfig _getBadgeConfig() {
    switch (size) {
      case BadgeSize.small:
        return const _BadgeConfig(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          radius: 8,
          minWidth: 16,
          minHeight: 16,
          fontSize: 10,
        );
      case BadgeSize.medium:
        return const _BadgeConfig(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          radius: 10,
          minWidth: 20,
          minHeight: 20,
          fontSize: 12,
        );
      case BadgeSize.large:
        return const _BadgeConfig(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          radius: 12,
          minWidth: 24,
          minHeight: 24,
          fontSize: 14,
        );
    }
  }

  /// バッジテキストを取得
  String _getBadgeText() {
    if (text != null) return text!;
    if (count != null) {
      return count! > 99 ? '99+' : count!.toString();
    }
    return '';
  }
}

/// バッジサイズ
enum BadgeSize {
  small,
  medium,
  large,
}

/// バッジ位置
enum BadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

extension BadgePositionExtension on BadgePosition {
  double? get top {
    switch (this) {
      case BadgePosition.topRight:
      case BadgePosition.topLeft:
        return -8;
      case BadgePosition.bottomRight:
      case BadgePosition.bottomLeft:
        return null;
    }
  }

  double? get right {
    switch (this) {
      case BadgePosition.topRight:
      case BadgePosition.bottomRight:
        return -8;
      case BadgePosition.topLeft:
      case BadgePosition.bottomLeft:
        return null;
    }
  }

  double? get left {
    switch (this) {
      case BadgePosition.topLeft:
      case BadgePosition.bottomLeft:
        return -8;
      case BadgePosition.topRight:
      case BadgePosition.bottomRight:
        return null;
    }
  }

  double? get bottom {
    switch (this) {
      case BadgePosition.bottomRight:
      case BadgePosition.bottomLeft:
        return -8;
      case BadgePosition.topRight:
      case BadgePosition.topLeft:
        return null;
    }
  }
}

/// バッジ設定
class _BadgeConfig {
  const _BadgeConfig({
    required this.padding,
    required this.radius,
    required this.minWidth,
    required this.minHeight,
    required this.fontSize,
  });

  final EdgeInsets padding;
  final double radius;
  final double minWidth;
  final double minHeight;
  final double fontSize;
}
```

## 命名規則

### ファイル名
- **命名形式**: `{機能名}_atom.dart` または `custom_{コンポーネント名}.dart`
- **例**: `custom_button.dart`, `loading_indicator.dart`, `error_display.dart`

### クラス名
- **命名形式**: `Custom{コンポーネント名}` または `{機能名}Atom`
- **例**: `CustomButton`, `LoadingIndicator`, `ErrorDisplay`

### プロパティ名
- **boolプロパティ**: `is{状態名}`, `has{状態名}`, `show{機能名}`
- **コールバック**: `on{アクション名}`, `{動詞}Callback`
- **設定値**: `{設定名}`, `{機能名}Config`

## ベストプラクティス

### 1. プロパティベースの制御
```dart
// ✅ Good: プロパティで動作を制御
class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
  });

  // プロパティのみで動作を決定
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? CircularProgressIndicator() : Text(text),
    );
  }
}

// ❌ Bad: 内部状態を持つ
class BadButton extends StatefulWidget {
  // StatefulWidgetは基本的に禁止
}
```

### 2. テーマの活用
```dart
// ✅ Good: テーマから色やスタイルを取得
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Container(
    color: colorScheme.primary,
    child: Text(
      text,
      style: theme.textTheme.bodyMedium,
    ),
  );
}

// ❌ Bad: ハードコードされた色
return Container(
  color: Colors.blue, // ハードコード
  child: Text(text),
);
```

### 3. 適切なデフォルト値
```dart
// ✅ Good: 適切なデフォルト値を設定
const CustomButton({
  required this.text,
  required this.onPressed,
  this.variant = ButtonVariant.primary, // デフォルト値
  this.size = ButtonSize.medium,         // デフォルト値
  this.isLoading = false,                // デフォルト値
});

// ❌ Bad: デフォルト値なし（必須でないプロパティ）
const CustomButton({
  required this.text,
  required this.onPressed,
  required this.variant, // 必須にする必要がない
});
```

## 依存関係の制約

### 許可されるimport
```dart
// ✅ Flutter基本
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ 同階層のenum/utility（必要に応じて）
import 'button_variants.dart';
```

### 禁止されるimport
```dart
// ❌ 上位層のimport
import '../2_molecules/user_card.dart';
import '../../../3_application/states/user_state.dart';

// ❌ 外部状態管理
import 'package:riverpod/riverpod.dart';

// ❌ その他の層
import '../../../../1_domain/entities/user_entity.dart';
```

## テスト指針

### 1. Atomsのテスト
```dart
// test/presentation/widgets/atoms/custom_button_test.dart
void main() {
  group('CustomButton', () {
    testWidgets('should display text correctly', (tester) async {
      // Given
      const buttonText = 'Test Button';
      var pressed = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('should handle tap correctly', (tester) async {
      // Given
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // When
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Then
      expect(pressed, isTrue);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test'), findsNothing);
    });
  });
}
```

## 注意事項

1. **状態の禁止**: 内部状態を持たず、すべてプロパティで制御する
2. **単一責任**: 一つのUIエレメントの表示のみに集中する
3. **再利用性**: 特定の機能に依存しない汎用的な実装を心がける
4. **テーマ統一**: アプリケーション全体のデザイン統一を重視する
5. **プロパティ設計**: 適切なデフォルト値と型安全性を確保する

# Theme ガイド — MVVM

## 概要

`lib/core/theme/` はアプリ全体のデザイントークン・テーマ定義を管理する。

## ファイル構成

```
lib/core/theme/
├── app_theme.dart         # ThemeData 定義
├── app_colors.dart        # カラーパレット
├── app_text_styles.dart   # タイポグラフィ
└── app_spacing.dart       # スペーシング定数
```

## 実装例

```dart
// app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    useMaterial3: true,
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
```

## ルール

- テーマ定数は必ず `app_*.dart` に定義する（ウィジェット内にハードコードしない）
- Material 3 を推奨
- ダークモード対応を前提に設計する

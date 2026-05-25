---
applyTo: 'lib/core/theme/**'
---

# Core Theme Instructions - テーマガイド

## 概要
`lib/core/theme/` はアプリ共通のテーマ設定と Design Tokens（色・タイポグラフィ・スペーシング等）を管理します。UI はこれらの共通値を参照し、見た目の一貫性を保ちます。

## 役割と責務
- `ThemeData` の構成と共通値の提供
- Design Tokens（`colors.dart`, `typography.dart`, `spacing.dart` 等）の分離
- ダーク／ライトテーマ切り替えの基本方針（必要に応じて）

## してはいけないこと
- 画面固有のスタイルやコンポーネント実装の混在
- フィーチャー特有のドメイン語彙の混入

## 推奨構成
```
lib/core/theme/
├── colors.dart
├── typography.dart
├── spacing.dart
└── app_theme.dart      # ThemeData を組み立てる
```

## import 指針
### 許可（例）
```dart
import 'package:flutter/material.dart';
```
### 禁止（例）
```dart
// フィーチャー固有 UI への依存
// import 'package:feature_x/widgets.dart';
```

## テスト指針
- `ThemeData` の生成テスト（必須値の有無、色定義の整合性）
- ライト／ダークテーマ切り替え時の値検証
# Routing ガイド — MVVM

## 概要

`lib/core/routing/` は GoRouter を使用したアプリケーション全体のルーティング定義を管理する。

## ファイル構成

```
lib/core/routing/
├── app_router.dart          # GoRouter インスタンス定義
└── path/
    └── {feature}_paths.dart # フィーチャーごとのパス定数
```

## 実装例

```dart
// app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // ...フィーチャーごとのルート追加
  ],
);
```

```dart
// path/memo_paths.dart
abstract class MemoPaths {
  static const list = '/memos';
  static const detail = '/memos/:id';
}
```

## ルール

- パス文字列はクラス定数として管理する（ハードコード禁止）
- 認証ガードは `redirect` パラメータで実装する

# エントリーポイントガイド — MVVM

## 概要

`main.dart` と `app.dart` はアプリケーションのエントリーポイント。
MVVM では ProviderScope で Riverpod のルートを設定する。

## ファイル構成

```
lib/
├── main.dart    # エントリーポイント。ProviderScope のルート
└── app.dart     # MaterialApp の定義
```

## 実装例

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
```

### app.dart

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'App Name',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## ルール

- `main.dart` はできるだけ薄く保つ
- 初期化処理（Firebase 等）は `main()` 内の `WidgetsFlutterBinding.ensureInitialized()` の後に配置
- テーマ切り替えは `ThemeMode.system` をデフォルトとする

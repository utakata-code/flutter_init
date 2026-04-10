---
applyTo:
  - 'lib/main.dart'
  - 'lib/app.dart'
---

# Main/App Entry Guide - エントリポイントガイド

## 概要
`main.dart` はアプリのブートシーケンス（初期化）を担当し、`app.dart` は最上位のウィジェット構成（テーマ／ルーティング／ローカライズ）を担当します。データベースとルーティングは初期化の順序と責務分離が重要です。本ガイドは `lib/core` 構成（`generate_core.sh` が生成）に準拠します。

## main.dart の責務
- フレームワーク初期化（`WidgetsFlutterBinding.ensureInitialized()`）
- 例外捕捉の設定（`runZonedGuarded` で未捕捉例外をログ集約）
- 設定読み込み（必要なら `.env` 等）
- Core の初期化：
  - データベース接続（`lib/core/database/database.dart`）
  - HTTP クライアント（`lib/core/api/http_client.dart`）
  - ルーター構成（`lib/core/routing/app_router.dart`）
- ProviderScope の用意と必要な Provider の override（DB／HTTP／Router など）
- `runApp(App)` の起動

## app.dart の責務
- `MaterialApp.router` の構成（`routerConfig` を Core から取得）
- テーマ設定（`lib/core/theme` の共通テーマ）
- ローカライズ・アニメーション・その他グローバル設定
- アプリ全体で共有する Composition のみを実施（重い初期化は行わない）

## データベース初期化の指針（重要）
- DB のオープンは `main.dart` で非同期に行い、`ProviderScope` の override で供給する
- 可能なら `LazyDatabase`（例：Drift）やバックグラウンド isolate を使い UI スレッドをブロックしない
- スキーマ／マイグレーションは `lib/core/database/table/` と `database.dart` に集約し、フィーチャー固有の CRUD はフィーチャー側へ
- DB 接続の例外は Core の `exceptions` にマッピングしてハンドリング（再試行／フォールバック方針）

## ルーティング構成の指針（重要）
- 画面パスは `lib/core/routing/path/` に集約し、文字列の直書きを禁止
- ルーター初期化（`GoRouter`）は `lib/core/routing/app_router.dart` に置き、認証ガード・リダイレクト方針を統一
- `app.dart` はルーターの提供を受けて `MaterialApp.router` を構成するだけに留める
- Deep Link／パラメータ付きルートは型安全なヘルパーで扱う（必須引数漏れを防止）

## してはいけないこと
- `main.dart` や `app.dart` にフィーチャー固有のロジック・UI を混在させる
- 画面パスを文字列で直書きして散在させる
- DB 初期化を `app.dart`（build 中）で行い、フレームをブロックする
- Core をバイパスして個別にクライアントや設定を初期化する

## サンプル実装（参考）
以下は Riverpod と GoRouter を用いた最小構成の例です。実際の `provider` 名や関数はプロジェクトに合わせて調整してください。

### main.dart（例）
```dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Core
import 'package:your_app/core/database/database.dart';
import 'package:your_app/core/api/http_client.dart';
import 'package:your_app/core/routing/app_router.dart';
import 'package:your_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    // Core 初期化（非同期）
    final db = await AppDatabase.open();
    final httpClient = createHttpClient();
    final router = createAppRouter();

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      dioProvider.overrideWithValue(httpClient),
      appRouterProvider.overrideWithValue(router),
    ]);

    runApp(UncontrolledProviderScope(
      container: container,
      child: const App(),
    ));
  }, (error, stack) {
    // ログ集約・クラッシュレポートへ送信
  });
}
```

### app.dart（例）
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/core/routing/app_router.dart';
import 'package:your_app/core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## import 指針
### 許可（例）
- `flutter/widgets.dart`（`main.dart` の最低限）
- `flutter/material.dart`（`app.dart` の UI 構成）
- `flutter_riverpod`（`ProviderScope` と依存注入）
- Core（`core/database`, `core/api`, `core/routing`, `core/theme`）

### 禁止（例）
- フィーチャー固有の UI／ロジックの直接 import（責務外）
- パス定義の直書き（`routing/path` を経由）

## テスト指針
- `main.dart`：初期化順序の検証（DB→API→Router→runApp）と例外ハンドリング
- `app.dart`：`MaterialApp.router` の構成検証（テーマ／routerConfig 取得）
- 統合：Deep Link／ガード動作のシナリオテスト（モックプロバイダを使用）

## 関連ドキュメント
- `AI/architecture/lib/core_architecture.md`
- `AI/architecture/lib/core/routing/instructions.md`
- `AI/architecture/lib/core/routing/path/instructions.md`
- `AI/architecture/lib/core/theme/instructions.md`
- `AI/architecture/lib/core/api/instructions.md`
- `AI/architecture/lib/core/database/instructions.md`
- `AI/architecture/lib/core/database/table/instructions.md`
- 例外設計：`AI/architecture/lib/core/exceptions/instructions.md`（`AI/scripts/bash/init_core_exceptions.sh` 参照）
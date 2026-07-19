# DI（依存注入）ガイド — MVVM

## 概要

`lib/core/di/` はアプリケーション全体の**依存注入（Dependency Injection）**設定を管理する。
MVVM では Clean Architecture の `3_application/2_providers/` に相当する機能を、この Core DI モジュールに集約する。

## ファイル構成

```
lib/core/di/
├── providers.dart         # グローバル Provider 定義
└── overrides.dart         # テスト用 Provider オーバーライド
```

## 実装例

```dart
// providers.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/user/memo/1_model/2_repositories/memo_repository.dart';
import '../../features/user/memo/1_model/2_repositories/memo_repository_impl.dart';
import '../../features/user/memo/1_model/3_services/memo_service.dart';

// Repository のバインディング
final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  return MemoRepositoryImpl();
});

// Service のバインディング
final memoServiceProvider = Provider<MemoService>((ref) {
  return MemoService(
    repository: ref.read(memoRepositoryProvider),
  );
});
```

## ルール

- 全ての Repository と Service のバインディングはここで定義する
- テスト時は `overrides` パラメータで差し替える
- フィーチャー固有の Provider は各フィーチャーの ViewModel 層に配置してよい（Notifier 等）
- 循環参照に注意する

## Clean Architecture との違い

| Clean Architecture | MVVM |
|---|---|
| `features/{perm}/{name}/3_application/2_providers/` | `core/di/providers.dart` |
| フィーチャーごとに分散 | Core に集約 |

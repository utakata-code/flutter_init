---
applyTo: 'lib/core/exceptions/**'
---

# Core Exceptions Instructions - 共通例外ガイド

## 概要
`lib/core/exceptions/` はアプリ全体で共通的に扱う例外の基底型と汎用例外（ネットワーク系・ストレージ系）を提供します。各フィーチャーはこの共通例外を基盤として、層ごと（Domain／Infrastructure／Application／Presentation）の責務に応じた例外伝播と変換を行います。

## 役割と責務

### ✅ すべきこと
- 例外の共通基底型（`BaseException`）を提供
- ネットワーク系共通例外（`NetworkException`）を提供
- ストレージ系共通例外（`StorageException`）を提供
- メッセージ・コード・元例外を保持し、上位層での扱いを統一
- 層ごとの例外取り扱いガイドラインに沿った利用を促進

### ❌ してはいけないこと
- 具体的なドメイン固有の例外定義（各フィーチャーの `1_domain/exceptions` に配置）
- データアクセスやUIなど他責務のロジックを含める
- ログ出力やトラッキングの直接実装（必要なら別ユーティリティに委譲）

## 推奨ディレクトリ構成（Core）

```
lib/core/exceptions/
├── base_exception.dart      # 共通の基底例外
├── network_exception.dart   # ネットワーク系の共通例外
└── storage_exception.dart   # ストレージ系の共通例外
```

## 実装テンプレート

### 1. 基底例外クラス
```dart
// lib/core/exceptions/base_exception.dart
abstract class BaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const BaseException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'BaseException(message: ' + message + (code != null ? ', code: ' + code! : '') + ')';
}
```

### 2. ネットワーク例外
```dart
// lib/core/exceptions/network_exception.dart
class NetworkException extends BaseException {
  const NetworkException(super.message, {super.code, super.originalError});

  factory NetworkException.connectionTimeout() =>
      const NetworkException('接続がタイムアウトしました', code: 'CONNECTION_TIMEOUT');

  factory NetworkException.noInternet() =>
      const NetworkException('インターネット接続がありません', code: 'NO_INTERNET');
}
```

### 3. ストレージ例外
```dart
// lib/core/exceptions/storage_exception.dart
class StorageException extends BaseException {
  const StorageException(super.message, {super.code, super.originalError});

  factory StorageException.databaseError(String details) =>
      StorageException('データベースエラー: ' + details, code: 'DATABASE_ERROR');

  factory StorageException.fileNotFound(String path) =>
      StorageException('ファイルが見つかりません: ' + path, code: 'FILE_NOT_FOUND');
}
```

## 使用ガイドライン（層ごとの取り扱い）

- Domain 層（`1_domain`）
  - ドメイン固有例外を定義（`BaseException` を継承）
  - ビジネスルール違反やエンティティ不整合などに限定

- Infrastructure 層（`2_infrastructure`）
  - DataSource では外部要因（HTTP／DB）に応じて `NetworkException`／`StorageException` を使用
  - フレームワーク例外（Dio／Drift）などは可能なら捕捉し、共通例外へ変換
  - Repository では DataSource 例外を必要に応じてドメイン例外へ変換

- Application 層（`3_application`）
  - UseCase でドメイン例外はそのまま伝播し、インフラ例外は必要に応じてドメイン例外へ変換
  - Notifier ではドメイン例外を受け取り、状態を適切に更新

- Presentation 層（`4_presentation`）
  - UI は例外の種類に応じてメッセージを統一（例：ネットワーク系／ストレージ系／ドメイン系）

## メッセージ／コード設計指針

- ユーザー向けメッセージは Presentation 層で確定する（Core では汎用メッセージ）
- `code` は機械可読で一意（例：`NO_INTERNET`, `DATABASE_ERROR`）
- `originalError` に元例外・スタックなどを保持して原因追跡可能にする

## 命名規則

- ファイル名：`{種類}_exception.dart`（例：`network_exception.dart`）
- クラス名：`{種類}Exception`（例：`StorageException`）

## 許可・禁止 import

### 許可される import
```dart
import 'dart:core';
```

### 禁止される import（例）
```dart
// UI／状態管理／外部通信／DB など Core の責務外
// import 'package:flutter/material.dart';
// import 'package:riverpod/riverpod.dart';
// import 'package:dio/dio.dart';
// import 'package:drift/drift.dart';
```

## テスト指針

- 生成系（`factory`）と `code` の整合性を検証
- `originalError` の保持と `toString()` の表現を検証
- 層を跨ぐ例外変換は各層のテストで担保（Core では型と生成の正当性）

## 注意事項

1. Core は「共通型の提供」に専念し、振る舞いの決定（文言・UI）は上位層で行う
2. 例外の階層を明確化（Core 共通 → ドメイン固有 → インフラ系）
3. 例外の変換は Repository／UseCase に集約し、UI へはドメイン語彙で伝達
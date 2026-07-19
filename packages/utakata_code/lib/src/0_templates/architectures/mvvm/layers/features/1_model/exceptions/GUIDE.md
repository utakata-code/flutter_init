# Exceptions Layer — 例外定義ガイド (MVVM)

> `lib/features/{perm}/{feature}/1_model/exceptions/`

## 責務

ドメイン固有の**例外クラス**を定義する。
Model 層内で発生するビジネスロジック上のエラーを型安全に表現する。

## ルール

- ドメイン固有の例外のみ定義する（HTTP エラーなどインフラ層例外はここに書かない）
- 不変かつ明確な構造にする
- ユーザーに向けたメッセージをカプセル化してよい

## 命名規則

`{対象名}_exception.dart` — 例: `memo_exception.dart`

## 実装例

```dart
class MemoNotFoundException implements Exception {
  final String memoId;
  const MemoNotFoundException(this.memoId);

  @override
  String toString() => 'MemoNotFoundException: $memoId not found';
}

class MemoValidationException implements Exception {
  final String message;
  const MemoValidationException(this.message);

  @override
  String toString() => 'MemoValidationException: $message';
}
```

## 許可される import

- `import 'dart:core';`

## 禁止される import

- `import 'package:dio/dio.dart';`
- `import 'package:flutter/material.dart';`

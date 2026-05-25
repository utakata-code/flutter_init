# State Layer — 状態定義ガイド (MVVM)

> `lib/features/{perm}/{feature}/2_viewmodel/1_states/`

## 責務

UI が参照する**不変の状態オブジェクト**を定義する。
ローディング、成功、失敗などの UI 状態を型安全に表現する。

## ルール

- `freezed` で不変状態を定義する
- UI が描画するためのデータ構造のみを定義する
- ビジネスロジックを含めない
- Flutter ウィジェット（`BuildContext` 等）に依存しない

## 命名規則

`{feature名}_state.dart` — 例: `memo_state.dart`

## 実装例

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../1_model/1_entities/memo_entity.dart';

part 'memo_state.freezed.dart';

@freezed
abstract class MemoState with _$MemoState {
  const factory MemoState.initial() = _Initial;
  const factory MemoState.loading() = _Loading;
  const factory MemoState.loaded({
    required List<MemoEntity> memos,
  }) = _Loaded;
  const factory MemoState.error({
    required String message,
  }) = _Error;
}
```

## 許可される import

- `import 'package:freezed_annotation/freezed_annotation.dart';`
- `import '../../1_model/1_entities/some_entity.dart';`

## 禁止される import

- `import 'package:flutter/material.dart';`
- `import 'package:riverpod/riverpod.dart';`

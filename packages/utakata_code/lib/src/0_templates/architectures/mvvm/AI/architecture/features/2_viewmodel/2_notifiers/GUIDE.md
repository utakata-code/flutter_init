# Notifier Layer — ノティファイア層ガイド (MVVM)

> `lib/features/{perm}/{feature}/2_viewmodel/2_notifiers/`

## 責務

**ViewModel の中核**。ユーザーイベントを受け取り、Service 層を呼び出して State を更新する。
Riverpod の `Notifier` / `AsyncNotifier` を使用して状態遷移ロジックを実装する。

## ルール

- `Notifier` / `AsyncNotifier` で状態遷移ロジックを実装する
- Service 層を呼び出して状態を更新する
- ビジネスルール自体はここに書かない（Service に委譲する）
- Repository の実装クラスに直接依存しない

## 命名規則

`{feature名}_notifier.dart` — 例: `memo_notifier.dart`

## 実装例

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../1_states/memo_state.dart';
import '../../1_model/3_services/memo_service.dart';

part 'memo_notifier.g.dart';

@riverpod
class MemoNotifier extends _$MemoNotifier {
  late final MemoService _service;

  @override
  MemoState build() {
    _service = ref.read(memoServiceProvider);
    return const MemoState.initial();
  }

  Future<void> loadMemos() async {
    state = const MemoState.loading();
    try {
      final memos = await _service.fetchAll();
      state = MemoState.loaded(memos: memos);
    } catch (e) {
      state = MemoState.error(message: e.toString());
    }
  }

  Future<void> createMemo({
    required String title,
    required String content,
  }) async {
    await _service.create(title: title, content: content);
    await loadMemos();
  }
}
```

## 許可される import

- `import 'package:riverpod_annotation/riverpod_annotation.dart';`
- `import '../1_states/some_state.dart';`
- `import '../../1_model/3_services/some_service.dart';`

## 禁止される import

- `import 'package:flutter/material.dart';`
- Repository 実装クラスの直接 import

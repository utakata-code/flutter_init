# Screen Layer — 画面層ガイド (MVVM)

> `lib/features/{perm}/{feature}/3_view/2_screens/`

## 責務

完全な**画面レイアウト**を構築する。
ViewModel（Notifier）の状態を監視（`watch`）し、ユーザーアクションをトリガーする。
Widget を組み合わせて 1 つの画面として機能させる。

## ルール

- `ConsumerWidget` / `HookConsumerWidget` を使用して ViewModel の状態を監視する
- ユーザーアクション（ボタン押下等）は Notifier のメソッドを呼び出すのみ
- ビジネスロジックを画面内に直接記述しない
- 1 画面 = 1 Screen ファイルとする

## 命名規則

`{feature名}_screen.dart` — 例: `memo_list_screen.dart`

## 実装例

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../2_viewmodel/1_states/memo_state.dart';
import '../../2_viewmodel/2_notifiers/memo_notifier.dart';
import '../1_widgets/memo_card_widget.dart';

class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('メモ一覧')),
      body: switch (state) {
        MemoState.initial() => const Center(
            child: Text('読み込みを開始してください'),
          ),
        MemoState.loading() => const Center(
            child: CircularProgressIndicator(),
          ),
        MemoState.loaded(:final memos) => ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) => MemoCardWidget(
              memo: memos[index],
              onTap: () {
                // 詳細画面への遷移
              },
            ),
          ),
        MemoState.error(:final message) => Center(
            child: Text('エラー: $message'),
          ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(memoNotifierProvider.notifier).loadMemos(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## 許可される import

- `import 'package:flutter/material.dart';`
- `import 'package:hooks_riverpod/hooks_riverpod.dart';`
- `import '../../2_viewmodel/2_notifiers/some_notifier.dart';`
- `import '../1_widgets/some_widget.dart';`

## 禁止される import

- `import '../../1_model/2_repositories/some_repository.dart';` （直接のリポジトリ呼び出し禁止）
- `import '../../1_model/3_services/some_service.dart';` （直接のサービス呼び出し禁止）

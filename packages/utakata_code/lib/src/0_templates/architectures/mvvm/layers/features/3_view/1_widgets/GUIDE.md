# Widget Layer — ウィジェット層ガイド (MVVM)

> `lib/features/{perm}/{feature}/3_view/1_widgets/`

## 責務

再利用可能な **UI コンポーネント**を定義する。
Screen を構成するための部品（カード、リスト項目、フォームフィールド等）を配置する。

## ルール

- 状態管理（Riverpod）に直接依存しない — データはコンストラクタ引数で受け取る
- 純粋な UI 描画のみを行う
- 必要に応じてコールバック関数（`onTap`, `onChanged` 等）を引数で受け取る
- 他フィーチャーのウィジェットに依存しない（共通部品は `core/` に配置）

## 命名規則

`{対象名}_widget.dart` — 例: `memo_card_widget.dart`

## 実装例

```dart
import 'package:flutter/material.dart';
import '../../1_model/1_entities/memo_entity.dart';

class MemoCardWidget extends StatelessWidget {
  final MemoEntity memo;
  final VoidCallback? onTap;

  const MemoCardWidget({
    super.key,
    required this.memo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(memo.title),
        subtitle: Text(memo.content),
        onTap: onTap,
      ),
    );
  }
}
```

## 許可される import

- `import 'package:flutter/material.dart';`
- `import '../../1_model/1_entities/some_entity.dart';` （描画のためのエンティティ参照）
- 同一ディレクトリ内の他ウィジェット

## 禁止される import

- `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- ViewModel 層のファイル
- Repository 実装のファイル

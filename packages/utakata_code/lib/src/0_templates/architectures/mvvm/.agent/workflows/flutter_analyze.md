---
description: Flutterの静的解析を実行し、問題を修正する
---

1. プロジェクトのルートで `flutter analyze` を実行し、結果をファイルに保存します。
// turbo
2. 解析結果を確認します。
// turbo
3. 出力を確認し、エラーや警告があるか判断します。
   - "No issues found!" と表示された場合、作業は完了です。
4. エラーや警告がある場合、それらを修正します。
   - コードを修正した後、再度このワークフローを実行して、修正が正しいか確認します。
   - 全てのエラーがなくなるまでこれを繰り返します。

## 実行コマンド

ステップ1:
```bash
flutter analyze 2>&1 | tee flutter_analyze_output.txt
```

ステップ2:
```bash
cat flutter_analyze_output.txt
```
---
description: プロジェクトステータスをチェックして更新（完全レポート）
---

# プロジェクトステータスの完全レポート

このワークフローは、以下をすべて実行します:
1. プロジェクト状態のチェック
2. project_status.md の更新
3. current_structure.md のスナップショット生成

AI エージェントとの対話を開始する前に `/status_report` を実行すると、最新の状態を把握できます。

## 手順

// turbo
1. フルレポートを実行
```bash
./utakata/scripts/status/check_status.sh && ./utakata/scripts/status/update_status.sh -y && ./utakata/scripts/status/snapshot.sh
```

## 使用タイミング

- 新しい AI エージェントとの会話開始前
- 大きな実装を完了した後
- プロジェクト全体の状況を把握したい時
- チーム共有のための最新状態を確認したい時

## 出力

1. カラフルなチェック結果（ターミナル表示）
2. 更新されたステータスファイルの内容（最初の80行）
3. project_status.md の完全更新

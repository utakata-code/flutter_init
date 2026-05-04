---
description: プロジェクトの現在状態をチェックして表示
---

# プロジェクトステータスのチェック

このワークフローは、プロジェクトの現在状態をチェックしてコンソールに表示します。

## 手順

// turbo
1. ステータスチェックを実行
```bash
./utakata/scripts/status/check_status.sh
```

## チェック内容

- Flutter プロジェクトの初期化状態
- Core コンポーネントの存在確認
- エントリポイント (main.dart, app.dart) の確認
- ドキュメントの存在確認
- Features の数をカウント

## 関連コマンド

- `/status update` - project_status.md を更新
- `/status report` - チェック + 更新 + スナップショット
- Features の実装状況

## 使用タイミング

- 実装漏れをチェックしたい時

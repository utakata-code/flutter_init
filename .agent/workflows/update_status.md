---
description: project_status.mdを現在の状態で自動更新
---

# project_status.md の更新

このワークフローは、プロジェクトの現在状態を検出して `AI/snapshots/project_status.yaml` を自動更新します。

## 手順

// turbo
1. ステータスファイルを更新
```bash
./AI/scripts/status/update_status.sh --yes
```

## 更新内容

- 最終更新日時
- Core コンポーネントの状態
- エントリポイントの状態
- Flutter プロジェクトの初期化状態
- ドキュメントの状態
- Features の数

## 関連コマンド

- `/status check` - 現在の状態をチェック (更新はしない)
- `/status report` - チェック + 更新 + スナップショット

## 使用タイミング

- スクリプトでファイルを生成した後
- 実装を進めた後
- AI エージェントに現状を正確に伝えたい時

## 注意

このワークフローは `--yes` フラグで自動承認モードで実行されます。
手動で確認したい場合は、直接スクリプトを実行してください:
```bash
./AI/scripts/status/update_status.sh
```

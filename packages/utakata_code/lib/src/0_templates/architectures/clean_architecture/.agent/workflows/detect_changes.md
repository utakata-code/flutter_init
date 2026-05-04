---
description: ファイルの変更を検出して記録
---

# ファイル変更の検出

このワークフローは、プロジェクト内のファイル変更を検出して `utakata/snapshots/change_history.yaml` に記録します。
AIエージェントは前回からの変更を即座に把握できます。

## 手順

/ / turbo
1. 変更検出スクリプトを実行
```bash
./utakata/scripts/status/detect_changes.sh
```

## 検出内容

- ファイルの作成
- ファイルの変更
- ファイルの削除
- ディレクトリの作成（24時間以内）

## 使用タイミング

- AIエージェントとの会話終了時
- 大きな実装作業の後
- 前回からの差分を記録したい時
- チーム共有のために変更履歴を残したい時

## 変更履歴の確認

```bash
# 最新の変更を表示
head -n 100 utakata/snapshots/change_history.yaml

# すべての変更を表示
cat utakata/snapshots/change_history.yaml
```

## オプション

### 履歴をクリア (注意)
```bash
./utakata/scripts/status/detect_changes.sh --clear-history
```

### 古い履歴をアーカイブ
```bash
# 30日以上前の変更をアーカイブ
./utakata/scripts/status/detect_changes.sh --archive-old 30
```

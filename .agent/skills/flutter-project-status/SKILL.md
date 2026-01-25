---
name: flutter-project-status
description: |
  プロジェクトの現在状態を確認・更新するスキル。「プロジェクト状態を確認」
  「ステータス更新」「現在の進捗は？」時に使用。
  project_status.md, current_structure.md, change_history.md を管理。
---

# 📊 Flutter プロジェクトステータススキル

> **目的**: プロジェクトの現在状態を可視化・管理する

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/status check` | プロジェクト状態をチェックして表示 |
| `/status update` | project_status.md を現在の状態で更新 |
| `/status snapshot` | current_structure.md にスナップショット出力 |
| `/status report` | check + update + snapshot を一括実行（推奨） |
| `/detect_changes` | ファイルの変更を検出して change_history.md に記録 |
| `/validate_structure` | ディレクトリ構造の違反を検出 |

## スクリプト

```bash
# 状態チェック
./AI/scripts/bash/status.sh check

# ステータス更新
./AI/scripts/bash/status.sh update

# スナップショット
./AI/scripts/bash/status.sh snapshot

# 全部実行（推奨）
./AI/scripts/bash/status.sh report

# 変更検出
./AI/scripts/bash/detect_changes.sh

# 構造検証
./AI/scripts/bash/validate_structure.sh
```

## 管理ファイル

| ファイル | 役割 |
|---------|------|
| `AI/logs/project_status.md` | プロジェクトの現在状態を一元管理 |
| `AI/logs/conversation_log.md` | AIエージェントとの会話履歴 |
| `AI/logs/structure_violations.md` | 構造違反の記録 |
| `AI/logs/change_history.md` | ファイル変更履歴 |
| `AI/document/current_structure.md` | 現在の構造スナップショット |

## 使用タイミング

### 会話開始時
```
/status check
```
現在の状態を把握してから作業開始

### 作業完了時
```
/status update
/detect_changes
```
進捗を記録

### フェーズ完了時
```
/status report
```
包括的な状態更新

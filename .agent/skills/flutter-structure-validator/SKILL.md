---
name: flutter-structure-validator
description: |
  lib/配下のディレクトリ構造がルールに準拠しているか検証する。
  「構造を検証して」「ルール違反をチェック」「validate_structure」時に使用。
  違反があれば AI/logs/structure_violations.md に記録。
---

# 🔍 Flutter 構造検証スキル

> **目的**: ディレクトリ構造とファイル命名規則の違反を検出する

## 使用方法

### コマンド
```bash
./AI/scripts/bash/validate_structure.sh
```

### ワークフロー
```
/validate_structure
```

## 検証内容

### 1. ディレクトリ構造
- `lib/` 直下の構造が正しいか
- `lib/core/` 配下のディレクトリが正しいか
- `lib/features/` 配下の各フィーチャーの層構造が正しいか

### 2. 層構造
- Domain, Infrastructure, Application, Presentation の4層が正しいか
- 各層の必須ディレクトリが存在するか

### 3. 命名規則
- ディレクトリ名が snake_case か
- ファイル名が snake_case.dart か
- サフィックスが正しいか（_entity, _repository 等）

## 出力

### 違反が見つかった場合
違反内容は `AI/logs/structure_violations.md` に記録されます。

### 違反が見つからなかった場合
```
✅ 構造検証が正常に完了しました。違反は見つかりませんでした。
```

## 違反解消後

```bash
# 違反ログをクリア
./AI/scripts/bash/validate_structure.sh --clear-violations
```

## 使用タイミング

- 新しいファイルやディレクトリを作成した後
- フィーチャーを追加した後
- AIエージェントとの会話開始前（現状確認）
- 構造の整合性を確認したい時

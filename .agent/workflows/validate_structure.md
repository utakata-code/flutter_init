---
description: ディレクトリ構造の違反を検出
---

# ディレクトリ構造の検証

このワークフローは、`lib/`以下のディレクトリ構造が定義に準拠しているかを検証します。
違反があれば `AI/snapshots/structure_violations.yaml` に記録されます。

## 手順

// turbo
1. 構造検証スクリプトを実行
```bash
./AI/scripts/validate/validate_structure.sh
```

## 検証内容

- `lib/` 直下の構造
- `lib/core/` 配下のディレクトリ
- `lib/features/` 配下の各フィーチャーの層構造
- Domain, Infrastructure, Application, Presentation 層の構造

## 使用タイミング

- 新しいファイルやディレクトリを作成した後
- フィーチャーを追加した後
- AIエージェントとの会話開始前（現状確認のため）
- 構造の整合性を確認したい時

## 違反が見つかった場合

1. `AI/snapshots/structure_violations.yaml` を確認
2. 違反の内容と推奨アクションを確認
3. 構造を修正
4. 再度検証を実行
5. すべて解消したら `--clear-violations` オプションで違反ログをクリア

```bash
./AI/scripts/validate/validate_structure.sh --clear-violations
```

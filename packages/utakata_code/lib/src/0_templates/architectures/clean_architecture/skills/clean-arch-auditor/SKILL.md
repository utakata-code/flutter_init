---
name: clean-arch-auditor
description: |
  Clean Architecture (4層) プロジェクトの構造・依存方向を監査するスキル。
  「構造をチェックして」「レイヤー違反がないか見て」「依存方向を確認して」時に使用。
---

# Clean Architecture 監査スキル

## 手順

1. `utakata check --json` で不足ファイル・余分なファイル・命名規則違反を確認する
2. 違反があれば、該当レイヤーのガイドを `utakata guide show <layer>` で参照してから修正する
3. 依存方向を確認する。許可される依存は一方向のみ:
   - `4_presentation` → `3_application` → `1_domain`
   - `2_infrastructure` → `1_domain`
   - `1_domain` はどの層にも依存しない(`dart:io` も禁止)

## 違反の典型例

- domain 層に `dart:io` / infrastructure の import がある
- presentation 層から repository 実装を直接 import している
- `exceptions/` 配下のファイル名が親ディレクトリの命名規則に従っていない
- feature 直下にレイヤー番号のないディレクトリがある

## 制約

- 修正提案の前に必ず `utakata check` の実際の出力を根拠にすること
- `doc/records/**` は読み取り専用。監査結果の記録が必要なら人間にコマンド実行を提案する

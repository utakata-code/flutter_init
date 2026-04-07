# 📘 既存アプリ開発モード（構造ルール使用中） — エントリ

> 対象: 既に本リポジトリの構造規約（`lib/core` と `lib/features/...` の4層）に準拠した既存アプリ。
> 目的: 現在のコードから仕様書・構造計画書を逆算生成し、以降の機能追加/修正で両ドキュメントを継続的に同期更新する。

## 成果物
- 更新済み仕様書: `AI/document/application_specification.md`
- 更新済み構造計画書: `AI/document/structure_plan.md`
- 継続運用ルール: ドリフト防止指針の適用

## 進行ファイル
- 逆算生成: `AI/instructions/existing_app/with_rules/reverse_generate.md`
- 機能追加/修正フロー: `AI/instructions/existing_app/with_rules/feature_update.md`
- 検証・ドリフト防止: `AI/instructions/existing_app/with_rules/validation.md`

## 開始前チェック
- [ ] `lib/core/` が存在し、`routing/theme/api/exceptions/database` が責務分離されている
- [ ] `lib/features/<permission>/<feature>/1_domain..4_presentation` の4層構造が維持されている
- [ ] `flutter analyze` が重大なエラーなしで実行可能

## モード運用の原則
- ドキュメント同期ファースト: 仕様書・構造計画書を先に更新し、その後コードに反映する
- 構造の厳守: 新規フォルダの追加は禁止（構造計画書に従う）
- 小さなループ: 調査 → ドキュメント更新 → 実装 → 検証 を短いサイクルで回す


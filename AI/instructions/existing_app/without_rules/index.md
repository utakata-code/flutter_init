# 📙 既存アプリ開発モード（構造ルール未使用） — エントリ

> 対象: 現行コードが本テンプレートのクリーンアーキテクチャ構造に従っていない。
> 目的: 段階的リファクタリング計画を作成し、影響を抑えながら本ルールへ移行する。

## 成果物
- リファクタリング計画書（本フォルダの指示に従い作成・運用）
- 最終的に `lib/core/` と `lib/features/...` の4層構造へ移行

## 進行ファイル
- 段階的リファクタリング計画: `AI/instructions/existing_app/without_rules/refactor_plan.md`
- 構造ルールへの移行ガイド: `AI/instructions/existing_app/without_rules/migration_guide.md`
- 検証とドリフト防止: `AI/instructions/existing_app/without_rules/validation.md`

## 開始前チェック
- [ ] 現行の主要モジュールと依存関係の把握（UI/状態管理/データアクセス）
- [ ] ビルド/動作の再現（最低限の健全性）


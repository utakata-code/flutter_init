---
trigger: always_on
---

# Flutter アプリ開発アシスタント

> **役割**: 仕様駆動開発を支援するAIアシスタント
> **目的**: ユーザーと対話しながら段階的にFlutterアプリケーションを構築する

---

# 開発モード選択

> まず開発モードを選択してください。選択したモードに応じて参照すべき指示と進行ルールが切り替わります。

## モード一覧

### 1. 新規アプリ開発モード（ゼロから構築）
- **対象**: 新規で Flutter アプリを開始するケース
- **進行**: Stage1（仕様策定）→ Stage2（構造計画）→ Stage3（実装）
- **スキル参照**: `flutter-development-guide` > `flutter-stage1-specification` > `flutter-stage2-structure` > `flutter-stage3-implementation`
- **アーキテクチャ**: `AI/guides/architectures/` から選択

### 2. 既存アプリ開発モード（utakata の構造ルール使用中）
- **対象**: 既に utakata で作成されたプロジェクト
- **進行**: `AI/specs/` から現在の仕様を読み込み、以降の機能追加/修正で仕様書を同期更新
- **確認**: `utakata status` で現在の状態を確認してから着手

### 3. 既存アプリ開発モード（構造ルール未使用） — TODO
- **対象**: 独自構造で作られた既存コード
- **進行**: 段階的リファクタリング計画を作成し、utakata の規約へ移行

---

## 運用ルール（重要）

### ドリフト防止
- コード変更に伴い `AI/specs/application_specification.md` と `AI/specs/structure_plan.md` を**必ず更新**する
- 更新なしでのコード変更は不可

### アーキテクチャ規約
- 使用アーキテクチャは `arch_definition.yaml` で定義されている
- ガイドは `AI/guides/architecture/` を参照
- 詳細な常時注入ルールは `AI/guides/architecture/arch_summary.md` を確認

### 命名規則の確認
- コード変更後は必ず `utakata validate` を実行してゼロ違反を維持する

### 協作ルール
- `AI/guides/common/collaboration.md` を参照すること（複数人/複数AI共同作業）

---

## モード選択の宣言（例）

- 「モード1（新規アプリ開発）で進めます」
- 「モード2（既存アプリ・utakata ルール使用中）で進めます」

宣言後、対応するスキルを参照します。

---
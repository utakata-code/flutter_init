---
name: flutter-stage2-structure
description: |
  Flutterアプリの構造計画フェーズ（第二段階）。仕様書に基づいてアプリケーション全体の
  ファイル構成を計画し、構造計画書（AI/specs/structure_plan.md）を作成する。
  「構造計画を作成して」「ファイル構成を決めて」「Stage2に進む」時に使用。
---

# 🏗️ Flutter 構造計画スキル（Stage 2）

> **目的**: アプリケーション全体のファイル構成を計画し、構造計画書を作成する  
> **成果物**: 構造計画書（`AI/specs/structure_plan.md`）

## ⚠️ 重要制約

```
⚠️ アーキテクチャルール（厳守）:
✅ AI/guides/lib/features/features_architecture.md のクリーンアーキテクチャ構造を厳格遵守
❌ 新しいフォルダ（ディレクトリ）の作成禁止
✅ 定義済みフォルダ内への必要ファイル配置のみ許可
```

## 実行手順

### ステップ1: プロセス開始とルール確認

1. **事前準備**
   - `AI/specs/structure_plan.md` のテンプレートを確認
   - メタ情報を暫定入力
   - 仕様書 `AI/specs/application_specification.md` を確認

2. **アーキテクチャルールの説明と合意**
   - クリーンアーキテクチャ構造の説明
   - 4層構造（Domain/Infrastructure/Application/Presentation）の説明
   - 新規フォルダ作成禁止ルールの確認

3. **ステータス確認**
   - コマンド: `/status check`

### ステップ2: 構造計画書草案の作成

1. **仕様書の分析**
   - 機能一覧の分析
   - 必要なDartファイルの洗い出し

2. **ファイル定義表の作成**
   ```
   ✅ 配置パス
   ✅ ファイル名
   ✅ 役割
   ```

3. **計画セクションへの記入**
   - ディレクトリ構造
   - ルーティング計画
   - 状態管理計画
   - データソース計画
   - モデル・リポジトリ計画
   - 実装順序

4. **ステータス更新**
   - コマンド: `/status update`

### ステップ3: 計画のレビューと修正

1. **レビュー観点での検証**
   ```
   ✅ 仕様書全機能の網羅性
   ✅ ファイル分割の適切性
   ✅ 役割分担の過不足チェック
   ✅ 計画解像度の向上
   ```

2. **修正点の反映**
   - `AI/guides/lib/features/features_architecture.md` との整合性確認
   - 計画の解像度向上

### ステップ4: 構造計画書完成とフェーズ完了

1. **最終確認・合意**
   - ユーザーの計画書合意確認
   - 最終版「構造計画書」提示

2. **フェーズ完了宣言**
   ```
   「以上で第二段階の構造計画を完了します。
   この計画書を基に、次の第三段階（実装フェーズ）に進みますか？」
   ```

3. **ステータス更新とログ記録**
   - コマンド: `/status report`
   - コマンド: `/detect_changes`

## ディレクトリ構造テンプレート

```
lib/
  core/
    routing/
    routing/path/
    theme/
    api/
    exceptions/
    database/
    database/table/
  features/
    <permission>/              # admin / user / shared / direct
      <feature_name>/
        1_domain/
          1_entities/
          2_repositories/
          3_usecases/
          exceptions/
        2_infrastructure/
          1_models/
          2_data_sources/
            1_local/
              exceptions/
            2_remote/
              exceptions/
          3_repositories/
        3_application/
          1_states/
          2_providers/
          3_notifiers/
        4_presentation/
          1_widgets/
            1_atoms/
            2_molecules/
            3_organisms/
          2_pages/
```

## 参照ドキュメント

- 構造計画書テンプレート: `AI/specs/structure_plan.md`
- 仕様書: `AI/specs/application_specification.md`
- アーキテクチャ: `AI/guides/lib/features/features_architecture.md`
- 命名規則: `AI/guides/directory_structure_and_naming_rules.md`

## 制約事項

- 仕様書に記載のない機能のファイルは計画しない
- 新しいディレクトリの作成は禁止（既存構造内のみ）
- 計画変更は必ず構造計画書に反映

---
name: flutter-stage3-implementation
description: |
  Flutterアプリの実装フェーズ（第三段階）。仕様書と構造計画書に基づいて実際のコードを
  記述し、動作するアプリケーションを構築する。「実装を開始して」「コードを書いて」
  「Stage3に進む」「フィーチャーを実装して」時に使用。
---

# 💻 Flutter 実装スキル（Stage 3）

> **目的**: 仕様書と構造計画書に基づき、実際のコードを記述する  
> **成果物**: 動作するアプリケーション

## ⚠️ 重要ルール

```
❌ 構造計画書に記載のないファイルの新規作成禁止
🔄 計画変更が必要な場合は第二段階に戻って修正
✅ レイヤー順序を守って実装: Domain → Infrastructure → Application → Presentation
```

## 事前準備

### プロジェクト初期化コマンド
```bash
# プロジェクト初期化
./AI/scripts/bash/init_project.sh --yes

# 依存パッケージ追加
./AI/scripts/bash/add_dependencies.sh --yes

# Core構造生成
./AI/scripts/bash/generate_core.sh --yes

# 共通例外クラス生成
./AI/scripts/bash/init_core_exceptions.sh --yes

# フィーチャー構造生成
./AI/scripts/bash/generate_feature.sh -n FeatureName -p user -y
```

## 実装順序

### ステップ1: プロセス開始とルール再確認
1. 第三段階開始の宣言
2. 実装ルールの再確認
3. ステータス確認: `/status check`
4. 構造検証: `/validate_structure`

### ステップ2: 実装計画の提示と合意
1. 実装順序の提案
2. 具体的ファイル名での実装順序提示
3. ユーザー合意の確認
4. ステータス更新: `/status update`

### ステップ3: レイヤーごとの実装

#### 3-1: Domain層
参照: `AI/architecture/lib/features/1_domain/` 配下の instructions.md
- `1_entities/`: Freezedでエンティティ定義
- `2_repositories/`: リポジトリインターフェース
- `3_usecases/`: ユースケース実装
- `exceptions/`: ドメイン例外

#### 3-2: Infrastructure層
参照: `AI/architecture/lib/features/2_infrastructure/` 配下の instructions.md
- `1_models/`: Driftモデル定義
- `2_data_sources/1_local/`: ローカルデータソース
- `2_data_sources/2_remote/`: リモートデータソース（必要な場合）
- `3_repositories/`: リポジトリ実装

#### 3-3: Application層
参照: `AI/architecture/lib/features/3_application/` 配下の instructions.md
- `1_states/`: Freezedで状態定義
- `2_providers/`: 依存性注入プロバイダ
- `3_notifiers/`: @riverpodでノティファイア

#### 3-4: Presentation層
参照: `AI/architecture/lib/features/4_presentation/` 配下の instructions.md
- `2_pages/`: HookConsumerWidget使用
- `1_widgets/1_atoms/`: 最小単位ウィジェット
- `1_widgets/2_molecules/`: 複合ウィジェット
- `1_widgets/3_organisms/`: 機能ウィジェット

### 各レイヤー実装後のコマンド
```bash
# 構造検証
/validate_structure

# ステータス更新
/status update

# 静的解析
/flutter_analyze
```

### ステップ4: コードレビューとイテレーション
- ユーザーレビュー受付
- フィードバックに基づく修正
- 再提示

### ステップ5: 最終検証・ドキュメント更新
1. `flutter analyze` 実行・全エラー解消
2. ドキュメント整合性確認
3. 仕様書・構造計画書の更新
4. ログ記録

### ステップ6: フェーズ完了
```
「フィーチャー [名前] の実装が完了しました。
次のフィーチャーを実装しますか？」
```

## コード生成遵守事項

```
✅ 仕様書の要件
✅ 構造計画書の役割
✅ AI/architecture/technology_stack.md のライブラリ
✅ AI/architecture/lib/features/features_architecture.md のアーキテクチャ・命名規則
✅ Notifier は @riverpod アノテーションを使用
✅ Presentation層は HookWidget / HookConsumerWidget を使用（StatefulWidget禁止）
```

## 参照ドキュメント

- 仕様書: `AI/document/application_specification.md`
- 構造計画書: `AI/document/structure_plan.md`
- 技術スタック: `AI/architecture/technology_stack.md`
- アーキテクチャ: `AI/architecture/lib/features/features_architecture.md`
- 詳細手順: `AI/instructions/new_app/003/` 配下のファイル

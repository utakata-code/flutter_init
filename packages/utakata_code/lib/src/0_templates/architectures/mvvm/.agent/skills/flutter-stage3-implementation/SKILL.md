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
✅ レイヤー順序を守って実装: Model → ViewModel → View
```

## 事前準備

### プロジェクト初期化コマンド
```bash
# プロジェクト初期化
./AI/scripts/setup/init_project.sh --yes

# 依存パッケージ追加
./AI/scripts/setup/add_dependencies.sh --yes

# Core構造生成
./AI/scripts/generate/generate_core.sh --yes

# 共通例外クラス生成
./AI/scripts/generate/init_core_exceptions.sh --yes

# フィーチャー構造生成
./AI/scripts/generate/generate_feature.sh -n FeatureName -p user -y
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

#### 3-1: Model層
**実装前に以下のガイドを必ず読むこと:**
- `AI/architecture/features/1_model/1_entities/GUIDE.md` — Freezedエンティティ定義
- `AI/architecture/features/1_model/2_repositories/GUIDE.md` — リポジトリI/F
- `AI/architecture/features/1_model/3_services/GUIDE.md` — サービス実装
- `AI/architecture/features/1_model/exceptions/GUIDE.md` — ドメイン例外

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_entities/` | ビジネスエンティティ | Freezed |
| `2_repositories/` | リポジトリI/F + 実装 | 抽象クラス + 具象クラス |
| `3_services/` | ビジネスロジック | 純粋Dart |
| `exceptions/` | ドメイン例外 | Exception継承 |

#### 3-2: ViewModel層
**実装前に以下のガイドを必ず読むこと:**
- `AI/architecture/features/2_viewmodel/1_states/GUIDE.md` — 状態クラス定義
- `AI/architecture/features/2_viewmodel/2_notifiers/GUIDE.md` — 状態管理

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_states/` | 状態定義 | Freezed |
| `2_notifiers/` | 状態管理 | Riverpod Notifier |

**重要: DI設定について**
```
MVVM では DI（依存性注入）は core/di/ に集約:
- core/di/providers.dart で Repository / Service のバインディングを定義
- Notifier は ref.read() で Service を取得
- Clean Architecture の 2_providers/ に相当する機能を core/di/ で担う
```

#### 3-3: View層
**実装前に以下のガイドを必ず読むこと:**
- `AI/architecture/features/3_view/2_screens/GUIDE.md` — 画面定義
- `AI/architecture/features/3_view/1_widgets/GUIDE.md` — ウィジェット定義

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `2_screens/` | 画面レイアウト | ConsumerWidget / HookConsumerWidget |
| `1_widgets/` | 再利用UI部品 | StatelessWidget |

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
✅ AI/architecture/guides/dependencies/core_stack.md のライブラリ
✅ AI/architecture/guides/README.md のアーキテクチャ・命名規則
✅ Notifier は Riverpod Notifier / AsyncNotifier を使用
✅ View層は StatelessWidget / HookWidget / HookConsumerWidget / ConsumerWidget を使用（StatefulWidget禁止）
```

## 参照ドキュメント

- 仕様書: `AI/specs/application_specification.md`
- 構造計画書: `AI/specs/structure_plan.md`
- 依存関係: `AI/architecture/guides/dependencies/core_stack.md`
- アーキテクチャ: `AI/architecture/guides/README.md`
- 命名規則: `AI/architecture/guides/directory_structure_and_naming_rules.md`

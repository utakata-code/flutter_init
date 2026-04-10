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

#### 3-1: Domain層
**実装前に以下のガイドを必ず読むこと:**
- `AI/guides/lib/features/1_domain/1_entities/entity_guide.md` — Freezedエンティティ定義
- `AI/guides/lib/features/1_domain/2_repositories/repository_guide.md` — リポジトリI/F
- `AI/guides/lib/features/1_domain/3_usecases/usecase_guide.md` — ユースケース実装
- `AI/guides/lib/features/1_domain/exceptions/domain_exception_guide.md` — ドメイン例外

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_entities/` | ビジネスエンティティ | Freezed |
| `2_repositories/` | リポジトリIF | 抽象クラス |
| `3_usecases/` | ユースケース | 純粋Dart |
| `exceptions/` | ドメイン例外 | Exception継承 |

#### 3-2: Infrastructure層
**実装前に以下のガイドを必ず読むこと:**
- `AI/guides/lib/features/2_infrastructure/1_models/model_guide.md` — Driftモデル定義
- `AI/guides/lib/features/2_infrastructure/2_data_sources/1_local/local_data_source_guide.md` — ローカルDS
- `AI/guides/lib/features/2_infrastructure/2_data_sources/2_remote/remote_data_source_guide.md` — リモートDS
- `AI/guides/lib/features/2_infrastructure/3_repositories/repository_impl_guide.md` — リポジトリ実装

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_models/` | DBモデル | Drift |
| `2_data_sources/1_local/` | ローカルDS | Drift |
| `2_data_sources/2_remote/` | リモートDS | http/dio |
| `3_repositories/` | リポジトリ実装 | DomainのIF実装 |

#### 3-3: Application層
**実装前に以下のガイドを必ず読むこと:**
- `AI/guides/lib/features/3_application/1_states/state_guide.md` — 状態クラス定義
- `AI/guides/lib/features/3_application/2_providers/provider_guide.md` — DI設定
- `AI/guides/lib/features/3_application/3_notifiers/notifier_guide.md` — 状態管理

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_states/` | 状態定義 | Freezed |
| `2_providers/` | 依存性注入 | Riverpod |
| `3_notifiers/` | 状態管理 | @riverpod |

**重要: Provider vs Notifier の責務**
```
Notifier (3_notifiers/):
- UIの状態管理
- UseCaseの呼び出し
- 副作用の管理
- @riverpod アノテーション使用

Provider (2_providers/):
- 依存性注入のみ
- Repository/UseCaseのインスタンス生成
- ビジネスロジックは含めない
```

#### 3-4: Presentation層
**実装前に以下のガイドを必ず読むこと:**
- `AI/guides/lib/features/4_presentation/2_pages/page_guide.md` — ページ定義
- `AI/guides/lib/features/4_presentation/1_widgets/1_atoms/atom_guide.md` — 原子コンポーネント
- `AI/guides/lib/features/4_presentation/1_widgets/2_molecules/molecule_guide.md` — 分子コンポーネント
- `AI/guides/lib/features/4_presentation/1_widgets/3_organisms/organism_guide.md` — 有機体コンポーネント

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `2_pages/` | 画面ページ | HookConsumerWidget |
| `1_widgets/1_atoms/` | 最小単位 | StatelessWidget |
| `1_widgets/2_molecules/` | 複合ウィジェット | StatelessWidget |
| `1_widgets/3_organisms/` | 機能ウィジェット | HookConsumerWidget |

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
✅ AI/guides/technology_stack.md のライブラリ
✅ AI/guides/lib/features/features_architecture.md のアーキテクチャ・命名規則
✅ Notifier は @riverpod アノテーションを使用
✅ Presentation層は StatelessWidget / HookWidget / HookConsumerWidget / ConsumerWidget を使用（StatefulWidget禁止）
```

## 参照ドキュメント

- 仕様書: `AI/specs/application_specification.md`
- 構造計画書: `AI/specs/structure_plan.md`
- 技術スタック: `AI/guides/technology_stack.md`
- アーキテクチャ: `AI/guides/lib/features/features_architecture.md`
- 命名規則: `AI/guides/directory_structure_and_naming_rules.md`

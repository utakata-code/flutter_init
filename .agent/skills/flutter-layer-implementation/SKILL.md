---
name: flutter-layer-implementation
description: |
  Domain/Infrastructure/Application/Presentation各層の実装詳細をガイドするスキル。
  「Domain層を実装して」「Infrastructure層を作成」「Application層の書き方」
  「Presentation層の実装」時に使用。レイヤー別の具体的な実装パターンを提供。
---

# 🏛️ Flutter レイヤー別実装スキル

> **目的**: 各レイヤーの実装詳細をガイドする

## 実装順序

```
1. Domain層       → ビジネスロジックの中心
2. Infrastructure層 → データアクセス
3. Application層   → 状態管理・DI
4. Presentation層  → UI表示
```

## 各レイヤーの詳細

### Domain層 (`1_domain/`)

参照: `AI/architecture/lib/features/1_domain/` 配下の instructions.md

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_entities/` | ビジネスエンティティ | Freezed |
| `2_repositories/` | リポジトリIF | 抽象クラス |
| `3_usecases/` | ユースケース | 純粋Dart |
| `exceptions/` | ドメイン例外 | Exception継承 |

### Infrastructure層 (`2_infrastructure/`)

参照: `AI/architecture/lib/features/2_infrastructure/` 配下の instructions.md

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_models/` | DBモデル | Drift |
| `2_data_sources/1_local/` | ローカルDS | Drift |
| `2_data_sources/2_remote/` | リモートDS | http/dio |
| `3_repositories/` | リポジトリ実装 | DomainのIF実装 |

### Application層 (`3_application/`)

参照: `AI/architecture/lib/features/3_application/` 配下の instructions.md

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `1_states/` | 状態定義 | Freezed |
| `2_providers/` | 依存性注入 | Riverpod |
| `3_notifiers/` | 状態管理 | @riverpod |

#### 重要: Provider vs Notifier の責務

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

### Presentation層 (`4_presentation/`)

参照: `AI/architecture/lib/features/4_presentation/` 配下の instructions.md

| ディレクトリ | 責務 | 使用技術 |
|------------|------|---------|
| `2_pages/` | 画面ページ | HookConsumerWidget |
| `1_widgets/1_atoms/` | 最小単位 | HookWidget |
| `1_widgets/2_molecules/` | 複合ウィジェット | HookWidget |
| `1_widgets/3_organisms/` | 機能ウィジェット | HookConsumerWidget |

## 各レイヤー実装後のコマンド

```bash
# 構造検証
/validate_structure

# ステータス更新
/status update

# 静的解析
/flutter_analyze
```

## 参照ドキュメント

- `resources/domain_layer.md` - Domain層詳細
- `resources/infrastructure_layer.md` - Infrastructure層詳細
- `resources/application_layer.md` - Application層詳細
- `resources/presentation_layer.md` - Presentation層詳細

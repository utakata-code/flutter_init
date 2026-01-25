---
name: flutter-feature-generator
description: |
  新しいフィーチャーディレクトリとクリーンアーキテクチャ構造を自動生成する。
  「新しいフィーチャーを作成して」「機能を追加して」「xxxフィーチャーを生成して」時に使用。
  権限レベル: admin, user, shared, direct から選択可能。
---

# 🧩 Flutter フィーチャー生成スキル

> **目的**: 新しいフィーチャーのディレクトリ構造を自動生成する

## 使用方法

### コマンド
```bash
./AI/scripts/bash/generate_feature.sh -n <フィーチャー名> -p <権限レベル> -y
```

### 権限レベル

| レベル | 説明 | 配置先 |
|-------|------|--------|
| `admin` | 管理者専用機能 | `lib/features/admin/` |
| `user` | 一般ユーザー機能 | `lib/features/user/` |
| `shared` | 共有機能 | `lib/features/shared/` |
| `direct` | 直接配置 | `lib/features/` 直下 |

### 使用例
```bash
# ユーザー機能としてUserProfileフィーチャーを作成
./AI/scripts/bash/generate_feature.sh -n UserProfile -p user -y

# 共有機能としてAuthフィーチャーを作成
./AI/scripts/bash/generate_feature.sh -n Auth -p shared -y

# 管理者機能としてDashboardフィーチャーを作成
./AI/scripts/bash/generate_feature.sh -n Dashboard -p admin -y
```

## 生成されるディレクトリ構造

```
lib/features/<permission>/<feature_name>/
├── 1_domain/
│   ├── 1_entities/
│   ├── 2_repositories/
│   ├── 3_usecases/
│   └── exceptions/
├── 2_infrastructure/
│   ├── 1_models/
│   ├── 2_data_sources/
│   │   ├── 1_local/
│   │   │   └── exceptions/
│   │   └── 2_remote/
│   │       └── exceptions/
│   └── 3_repositories/
├── 3_application/
│   ├── 1_states/
│   ├── 2_providers/
│   └── 3_notifiers/
└── 4_presentation/
    ├── 1_widgets/
    │   ├── 1_atoms/
    │   ├── 2_molecules/
    │   └── 3_organisms/
    └── 2_pages/
```

## 生成後のステップ

1. 構造計画書 `AI/document/structure_plan.md` に新フィーチャーを追記
2. 各レイヤーのファイルを作成
3. `flutter analyze` で検証

## 制約事項

- フィーチャー名は PascalCase または snake_case で指定
- 権限レベルは必ず指定（デフォルト: user）
- 生成後のディレクトリ構造の変更は禁止

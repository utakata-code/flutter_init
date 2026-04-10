# Flutter Feature Development Template

## 概要

このドキュメントは、flutterプロジェクトにおけるフィーチャー開発のテンプレートとガイドラインを提供します。
`generate_feature.sh`と`generate_feature.ps1`スクリプトを使用してクリーンアーキテクチャに基づいた機能を効率的に開発できます。

## アーキテクチャ概要

### クリーンアーキテクチャの4層構造

```
lib/features/{permission_level}/{feature_name}/
├── 1_domain/           # ドメイン層（ビジネスロジック）
├── 2_infrastructure/   # インフラストラクチャ層（データアクセス）
├── 3_application/      # アプリケーション層（状態管理）
└── 4_presentation/     # プレゼンテーション層（UI）
```

### 権限レベル

- **admin**: 管理者専用機能
- **user**: 一般ユーザー機能
- **shared**: 共通機能（認証、共通UIコンポーネントなど）
- **direct**: 直下配置（権限レベルを介さず `lib/features/` 直下に配置する特殊ケース）


### 3. 生成されるディレクトリ構造

```
lib/features/{permission_level}/{feature_name_snake}/
├── 1_domain/
│   ├── 1_entities/           # エンティティ（ビジネスオブジェクト）
│   ├── 2_repositories/       # リポジトリインターフェース
│   ├── 3_usecases/           # ユースケース（ビジネスロジック）
│   └── exceptions/           # ドメイン例外
├── 2_infrastructure/
│   ├── 1_models/           # データモデル
│   ├── 2_data_sources/
│   │   ├── 1_local/        # ローカルデータソース
│   │   │   └── exceptions/ # ローカルデータソース例外
│   │   └── 2_remote/       # リモートデータソース
│   │       └── exceptions/ # リモートデータソース例外
│   └── 3_repositories/     # リポジトリ実装
├── 3_application/
│   ├── 1_states/             # 状態クラス
│   ├── 2_providers/          # プロバイダー定義
│   └── 3_notifiers/          # 状態管理（Riverpod Notifier）
└── 4_presentation/
    ├── 2_pages/            # ページ（画面）
    └── 1_widgets/
        ├── 1_atoms/        # 原子コンポーネント
        ├── 2_molecules/    # 分子コンポーネント
        └── 3_organisms/    # 有機体コンポーネント
```

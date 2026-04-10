# ディレクトリ構造と命名規則

> このファイルは、プロジェクトのディレクトリ構造とファイル命名規則を一元管理します。  
> AIエージェントと開発者は、このファイルを参照することで構造と命名の全体像を即座に把握できます。

最終更新: 2026-02-11
バージョン: 1.1.0

---

## 📋 目次

1. [全体構造](#全体構造)
2. [lib/core/ の構造](#libcore-の構造)
3. [lib/features/ の構造](#libfeatures-の構造)
4. [命名規則サマリー](#命名規則サマリー)
5. [検証方法](#検証方法)

---

## 全体構造

### lib/直下

```
lib/
├── main.dart              # アプリケーションのエントリポイント
├── app.dart               # 最上位ウィジェット
├── core/                  # 共通基盤（Core層）
└── features/              # 機能単位（Features層）
```

### 許可されるファイル・ディレクトリ

- ✅ `lib/main.dart`
- ✅ `lib/app.dart`
- ✅ `lib/core/`
- ✅ `lib/features/`

---

## lib/core/ の構造

### Core層のディレクトリ

```
lib/core/
├── routing/               # ルーティング設定
│   └── path/             # パス定義
├── theme/                # テーマ設定
├── api/                  # HTTP クライアント
├── env/                  # 環境変数・アプリ設定
├── database/             # データベース
│   ├── table/           # テーブル定義
│   └── migration/       # マイグレーションファイル
└── exceptions/           # 共通例外
```

### ファイル命名規則

| ディレクトリ | ファイル命名形式 | 例 |
|------------|--------------|-----|
| `routing/` | `app_router.dart` | ルーター設定 |
| `routing/path/` | `*_paths.dart` | `feature_paths.dart` |
| `theme/` | `app_theme.dart`, `*_theme.dart` | テーマ定義 |
| `api/` | `http_client.dart`, `api_config.dart` | HTTPクライアント設定 |
| `env/` | `env.dart`, `app_config.dart` | 環境変数・設定 |
| `database/` | `database.dart` | データベース接続 |
| `database/table/` | `*_table.dart` | `users_table.dart` |
| `database/migration/` | `migration_v*.dart` | `migration_v2.dart` |
| `exceptions/` | `*_exception.dart` | `network_exception.dart` |

---

## lib/features/ の構造

### Features層の基本構造

```
lib/features/{permission_level}/{feature_name}/
├── 1_domain/              # ドメイン層
│   ├── 1_entities/       # エンティティ
│   ├── 2_repositories/  # リポジトリインターフェース
│   ├── 3_usecases/      # ユースケース
│   └── exceptions/       # ドメイン固有の例外
├── 2_infrastructure/      # インフラストラクチャ層
│   ├── 1_models/        # データモデル
│   ├── 2_data_sources/  # データソース
│   │   ├── 1_local/    # ローカルデータソース
│   │   │   └── exceptions/  # ローカルデータソース例外
│   │   └── 2_remote/   # リモートデータソース
│   │       └── exceptions/  # リモートデータソース例外
│   └── 3_repositories/  # リポジトリ実装
├── 3_application/         # アプリケーション層
│   ├── 1_states/        # 状態クラス
│   ├── 2_providers/     # プロバイダー定義
│   └── 3_notifiers/     # Notifier（状態管理）
└── 4_presentation/        # プレゼンテーション層
    ├── 1_widgets/       # ウィジェット
    │   ├── 1_atoms/    # 原子コンポーネント
    │   ├── 2_molecules/  # 分子コンポーネント
    │   └── 3_organisms/  # 有機体コンポーネント
    └── 2_pages/         # ページ（画面）
```

### 権限レベル (permission_level)

- `admin/` - 管理者専用機能
- `user/` - 一般ユーザー機能
- `shared/` - 共通機能
- `direct/` - 直下配置（特殊な場合のみ）

---

## 命名規則サマリー

### 1. Domain層（1_domain/）

#### 1_entities/ - エンティティ

- **ファイル名**: `{対象名}_entity.dart`
- **クラス名**: `{対象名}Entity`
- **例**: 
  - ファイル: `user_entity.dart`
  - クラス: `UserEntity`

#### 2_repositories/ - リポジトリインターフェース

- **ファイル名**: `{対象名}_repository.dart`
- **クラス名**: `{対象名}Repository`
- **例**: 
  - ファイル: `user_repository.dart`
  - クラス: `UserRepository`

#### 3_usecases/ - ユースケース

- **ファイル名**: `{動詞}_{対象名}_usecase.dart`
- **クラス名**: `{動詞}{対象名}Usecase`
- **例**: 
  - ファイル: `get_user_usecase.dart`
  - クラス: `GetUserUsecase`
  - ファイル: `create_order_usecase.dart`
  - クラス: `CreateOrderUsecase`

#### exceptions/ - ドメイン固有の例外

- **ファイル名**: `{対象名}_exceptions.dart` または `domain_exceptions.dart`
- **クラス名**: `{詳細}Exception`
- **例**: 
  - ファイル: `user_exceptions.dart`
  - クラス: `UserNotFoundException`, `InvalidUserException`

---

### 2. Infrastructure層（2_infrastructure/）

#### 1_models/ - データモデル

- **ファイル名**: `{対象名}_model.dart`
- **クラス名**: `{対象名}Model`
- **例**: 
  - ファイル: `user_model.dart`
  - クラス: `UserModel`

#### 2_data_sources/1_local/ - ローカルデータソース

- **ファイル名**: `{対象名}_local_data_source.dart`
- **クラス名**: `{対象名}LocalDataSource`
- **例**: 
  - ファイル: `user_local_data_source.dart`
  - クラス: `UserLocalDataSource`

#### 2_data_sources/2_remote/ - リモートデータソース

- **ファイル名**: `{対象名}_remote_data_source.dart`
- **クラス名**: `{対象名}RemoteDataSource`
- **例**: 
  - ファイル: `user_remote_data_source.dart`
  - クラス: `UserRemoteDataSource`

#### 3_repositories/ - リポジトリ実装

- **ファイル名**: `{対象名}_repository_impl.dart`
- **クラス名**: `{対象名}RepositoryImpl`
- **例**: 
  - ファイル: `user_repository_impl.dart`
  - クラス: `UserRepositoryImpl`

---

### 3. Application層（3_application/）

#### 1_states/ - 状態クラス

- **ファイル名**: `{対象名}_state.dart`
- **クラス名**: `{対象名}State`
- **例**: 
  - ファイル: `user_state.dart`
  - クラス: `UserState`

#### 2_providers/ - プロバイダー定義

- **ファイル名**: `{対象名}_providers.dart`
- **プロバイダー変数名**: `{対象名}Provider`, `{対象名}NotifierProvider`
- **例**: 
  - ファイル: `user_providers.dart`
  - 変数: `userRepositoryProvider`, `userNotifierProvider`

#### 3_notifiers/ - Notifier（状態管理）

- **ファイル名**: `{対象名}_notifier.dart`
- **クラス名**: `{対象名}Notifier`
- **例**: 
  - ファイル: `user_notifier.dart`
  - クラス: `UserNotifier`

---

### 4. Presentation層（4_presentation/）

#### 1_widgets/1_atoms/ - 原子コンポーネント

- **ファイル名**: `{コンポーネント名}_atom.dart`
- **クラス名**: `{コンポーネント名}Atom`
- **例**: 
  - ファイル: `primary_button_atom.dart`
  - クラス: `PrimaryButtonAtom`

#### 1_widgets/2_molecules/ - 分子コンポーネント

- **ファイル名**: `{コンポーネント名}_molecule.dart`
- **クラス名**: `{コンポーネント名}Molecule`
- **例**: 
  - ファイル: `user_card_molecule.dart`
  - クラス: `UserCardMolecule`

#### 1_widgets/3_organisms/ - 有機体コンポーネント

- **ファイル名**: `{コンポーネント名}_organism.dart`
- **クラス名**: `{コンポーネント名}Organism`
- **例**: 
  - ファイル: `user_list_organism.dart`
  - クラス: `UserListOrganism`

#### 2_pages/ - ページ（画面）

- **ファイル名**: `{画面名}_page.dart`
- **クラス名**: `{画面名}Page`
- **例**: 
  - ファイル: `user_detail_page.dart`
  - クラス: `UserDetailPage`
  - ファイル: `login_page.dart`
  - クラス: `LoginPage`

---

## 命名規則の基本原則

### 1. ファイル名

- **snake_case**を使用
- **サフィックス**で役割を明示（`_entity`, `_model`, `_repository` など）
- **明確で具体的**な名前を使用

### 2. クラス名

- **PascalCase**を使用
- **サフィックス**で役割を明示（`Entity`, `Model`, `Repository` など）
- ファイル名と対応させる

### 3. 変数名・メソッド名

- **camelCase**を使用
- **動詞 + 名詞**の形式（メソッド）
- **名詞**のみ（変数）

### 4. 定数名

- **lowerCamelCase**を使用（Dart の慣例）
- グローバル定数は**SCREAMING_SNAKE_CASE**も可

---

## 検証方法

### 自動検証

構造と命名規則の違反を自動検出するスクリプトを実行:

```bash
# ディレクトリ構造とファイル命名規則を検証
./AI/scripts/bash/validate_structure.sh
```

違反が見つかった場合は、`AI/logs/structure_violations.md` に記録されます。

### ワークフローから実行

```
/validate_structure
```

---

## 参考ドキュメント

### 詳細なガイドライン

各層の詳細な実装ガイドラインは、以下のinstructionsファイルを参照:

- [Domain - Entities](../architecture/lib/features/1_domain/1_entities/instructions.md)
- [Domain - Repositories](../architecture/lib/features/1_domain/2_repositories/instructions.md)
- [Domain - Usecases](../architecture/lib/features/1_domain/3_usecases/instructions.md)
- [Infrastructure - Models](../architecture/lib/features/2_infrastructure/1_models/instructions.md)
- [Infrastructure - Data Sources](../architecture/lib/features/2_infrastructure/2_data_sources/1_local/instructions.md)
- [Infrastructure - Repositories](../architecture/lib/features/2_infrastructure/3_repositories/instructions.md)
- [Application - States](../architecture/lib/features/3_application/1_states/instructions.md)
- [Application - Providers](../architecture/lib/features/3_application/2_providers/instructions.md)
- [Application - Notifiers](../architecture/lib/features/3_application/3_notifiers/instructions.md)
- [Presentation - Atoms](../architecture/lib/features/4_presentation/1_widgets/1_atoms/instructions.md)
- [Presentation - Molecules](../architecture/lib/features/4_presentation/1_widgets/2_molecules/instructions.md)
- [Presentation - Organisms](../architecture/lib/features/4_presentation/1_widgets/3_organisms/instructions.md)
- [Presentation - Pages](../architecture/lib/features/4_presentation/2_pages/instructions.md)

### 構造定義

- [Features Architecture](../architecture/lib/features/features_architecture.md)
- [Core Architecture](../architecture/lib/core/core_architecture.md)

---

## よくある違反例

### ❌ 違反例

```
lib/features/auth/
├── domain/                    # ❌ 番号プレフィックスがない
├── 1_domain/
│   └── user.dart             # ❌ サフィックス(_entity)がない
├── 1_domain/
│   └── UserEntity.dart       # ❌ PascalCaseのファイル名
└── 1_domain/
    └── services/             # ❌ 許可されていないディレクトリ
```

### ✅ 正しい例

```
lib/features/auth/
├── 1_domain/
│   ├── 1_entities/
│   │   └── user_entity.dart
│   ├── 2_repositories/
│   │   └── user_repository.dart
│   └── 3_usecases/
│       └── login_usecase.dart
├── 2_infrastructure/
│   └── 1_models/
│       └── user_model.dart
└── 3_application/
    └── 3_notifiers/
        └── auth_notifier.dart
```

---

## 更新履歴

| 日付 | バージョン | 変更内容 |
|------|----------|---------|
| 2026-02-11 | 1.1.0 | `env/`、`database/migration/` ディレクトリを追加 |
| 2025-12-27 | 1.0.0 | 初版作成 |

---

## まとめ

- ✅ **厳密な構造**: 定義されたディレクトリ構造に従う
- ✅ **一貫した命名**: 役割ごとのサフィックスを使用
- ✅ **自動検証**: `validate_structure.sh` で違反を検出
- ✅ **ドキュメント参照**: 詳細は各 instructions.md を確認

この構造と命名規則を守ることで、**AIとの協働における精度と再現性が大幅に向上**します。

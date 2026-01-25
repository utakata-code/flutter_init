# フィーチャー構造

## 4層アーキテクチャ

### 1. Domain層 (`1_domain/`)
ビジネスロジックの中心

| ディレクトリ | 責務 |
|------------|------|
| `1_entities/` | ビジネスエンティティ（Freezed使用） |
| `2_repositories/` | リポジトリインターフェース |
| `3_usecases/` | ユースケース（ビジネスロジック） |
| `exceptions/` | ドメイン固有の例外 |

### 2. Infrastructure層 (`2_infrastructure/`)
データアクセスと外部システム連携

| ディレクトリ | 責務 |
|------------|------|
| `1_models/` | データモデル（Drift用） |
| `2_data_sources/1_local/` | ローカルデータソース |
| `2_data_sources/2_remote/` | リモートデータソース |
| `3_repositories/` | リポジトリ実装 |

### 3. Application層 (`3_application/`)
状態管理とDI

| ディレクトリ | 責務 |
|------------|------|
| `1_states/` | 状態定義（Freezed使用） |
| `2_providers/` | 依存性注入プロバイダ |
| `3_notifiers/` | 状態管理（@riverpod使用） |

### 4. Presentation層 (`4_presentation/`)
UI表示

| ディレクトリ | 責務 |
|------------|------|
| `2_pages/` | 画面ページ |
| `1_widgets/1_atoms/` | 最小単位ウィジェット |
| `1_widgets/2_molecules/` | 複合ウィジェット |
| `1_widgets/3_organisms/` | 機能ウィジェット |

## 依存の方向

```
Presentation → Application → Domain ← Infrastructure
```

- Domain層は他の層に依存しない
- Infrastructure層はDomain層のインターフェースを実装

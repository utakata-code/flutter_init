# ステップ1: アーキテクチャルール

## 重要制約（必ず遵守）

```
⚠️ 厳守事項:
✅ AI/guides/lib/features/features_architecture.md のクリーンアーキテクチャ構造を厳格遵守
❌ 新しいフォルダ（ディレクトリ）の作成禁止
✅ 定義済みフォルダ内への必要ファイル配置のみ許可
```

## 4層アーキテクチャ

| 層 | ディレクトリ | 責務 |
|---|------------|------|
| Domain | `1_domain/` | ビジネスロジック、エンティティ、リポジトリIF、ユースケース |
| Infrastructure | `2_infrastructure/` | データソース実装、モデル、リポジトリ実装 |
| Application | `3_application/` | 状態管理、プロバイダ、ノティファイア |
| Presentation | `4_presentation/` | UI、ウィジェット、ページ |

## 依存の方向

```
Presentation → Application → Domain ← Infrastructure
```

- 上位層から下位層への一方向依存
- Domain層は他の層に依存しない
- Infrastructure層はDomain層のインターフェースを実装

## 権限レベル

| レベル | 説明 | 配置先 |
|-------|------|--------|
| admin | 管理者専用機能 | `lib/features/admin/` |
| user | 一般ユーザー機能 | `lib/features/user/` |
| shared | 共有機能 | `lib/features/shared/` |
| direct | 直接配置 | `lib/features/` 直下 |

## 命名規則

- ディレクトリ名: snake_case（例: `user_profile/`）
- ファイル名: snake_case.dart（例: `user_entity.dart`）
- クラス名: PascalCase（例: `UserEntity`）

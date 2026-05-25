# ステップ1: アーキテクチャルール

## 重要制約（必ず遵守）

```
⚠️ 厳守事項:
✅ MVVM 3層アーキテクチャ構造を厳格遵守
❌ 新しいフォルダ（ディレクトリ）の作成禁止
✅ 定義済みフォルダ内への必要ファイル配置のみ許可
```

## 3層アーキテクチャ

| 層 | ディレクトリ | 責務 |
|---|------------|------|
| Model | `1_model/` | エンティティ、リポジトリI/F・実装、サービス、例外 |
| ViewModel | `2_viewmodel/` | 状態定義、ノティファイア（状態遷移ロジック） |
| View | `3_view/` | UI、ウィジェット、画面 |

## 依存の方向

```
View → ViewModel → Model
```

- 上位層から下位層への一方向依存
- Model層は他の層に依存しない
- ViewModel層はModel層のServiceを通じてデータにアクセス

## 権限レベル

| レベル | 説明 | 配置先 |
|-------|------|--------|
| admin | 管理者専用機能 | `lib/features/admin/` |
| user | 一般ユーザー機能 | `lib/features/user/` |
| shared | 共有機能 | `lib/features/shared/` |
| direct | 直接配置 | `lib/features/` 直下 |

## 命名規則

- ディレクトリ名: snake_case（例: `user_profile/`）
- ファイル名: snake_case.dart（例: `memo_entity.dart`）
- クラス名: PascalCase（例: `MemoEntity`）

# MVVM (3-layer) — ディレクトリ構造と命名規則

## 全体構造

```
lib/
├── main.dart                              # エントリーポイント
├── app.dart                               # MaterialApp / ProviderScope
├── core/                                  # アプリ共通基盤
│   ├── routing/                           # ルーティング定義
│   ├── theme/                             # テーマ定義
│   ├── di/                                # 依存注入（グローバルDI設定）
│   └── api/                               # API クライアント設定
└── features/                              # フィーチャーモジュール
    ├── {permission}/                      # admin / user / shared / direct
    │   └── {feature_name}/                # フィーチャー名（snake_case）
    │       ├── 1_model/                   # Model 層
    │       │   ├── 1_entities/
    │       │   ├── 2_repositories/
    │       │   ├── 3_services/
    │       │   └── exceptions/
    │       ├── 2_viewmodel/               # ViewModel 層
    │       │   ├── 1_states/
    │       │   └── 2_notifiers/
    │       └── 3_view/                    # View 層
    │           ├── 1_widgets/
    │           └── 2_screens/
```

---

## 命名規則一覧

### Model 層 (`1_model/`)

| ディレクトリ | ファイル名パターン | 説明 |
|---|---|---|
| `1_entities/` | `{name}_entity.dart` | ビジネスエンティティ（freezed） |
| `2_repositories/` | `{name}_repository.dart` | リポジトリ抽象 I/F |
| `2_repositories/` | `{name}_repository_impl.dart` | リポジトリ実装 |
| `3_services/` | `{name}_service.dart` | ビジネスロジック |
| `exceptions/` | `{name}_exception.dart` | ドメイン例外 |

### ViewModel 層 (`2_viewmodel/`)

| ディレクトリ | ファイル名パターン | 説明 |
|---|---|---|
| `1_states/` | `{feature}_state.dart` | 不変状態定義（freezed） |
| `2_notifiers/` | `{feature}_notifier.dart` | 状態遷移ロジック（Riverpod Notifier） |

### View 層 (`3_view/`)

| ディレクトリ | ファイル名パターン | 説明 |
|---|---|---|
| `1_widgets/` | `{name}_widget.dart` | 再利用可能 UI 部品 |
| `2_screens/` | `{feature}_screen.dart` | 完全な画面レイアウト |

---

## Permission の種類

| Permission | 説明 | パス |
|---|---|---|
| `user` | 一般ユーザー向け機能 | `features/user/{feature}/` |
| `admin` | 管理者向け機能 | `features/admin/{feature}/` |
| `shared` | 全権限共有機能 | `features/shared/{feature}/` |
| `direct` | features/ 直下に配置 | `features/{feature}/` |

---

## 依存ルール（レイヤー間）

```
3_view → 2_viewmodel → 1_model
```

- **上位層は下位層に依存してよい**（View → ViewModel → Model）
- **下位層は上位層に依存してはならない**（Model が View を import するのは禁止）
- **同一層内は自由に依存可能**

### 各層の依存可否マトリクス

| 参照元 ＼ 参照先 | 1_model | 2_viewmodel | 3_view |
|---|---|---|---|
| **1_model** | ✅ | ❌ | ❌ |
| **2_viewmodel** | ✅ | ✅ | ❌ |
| **3_view** | ✅（entities のみ） | ✅ | ✅ |

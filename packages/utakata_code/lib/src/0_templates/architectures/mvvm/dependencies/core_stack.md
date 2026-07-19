# MVVM コアスタック — パッケージ解説

## 状態管理

| パッケージ | 用途 |
|---|---|
| `hooks_riverpod` | Riverpod + Flutter Hooks による宣言的状態管理 |
| `flutter_hooks` | `useState`, `useEffect` 等の React-like ライフサイクル管理 |

## データモデル

| パッケージ | 用途 |
|---|---|
| `freezed_annotation` | 不変データクラスの定義（Entity / State） |
| `json_annotation` | JSON シリアライズ対応 |

## HTTP通信

| パッケージ | 用途 |
|---|---|
| `dio` | HTTP クライアント。インターセプター対応 |

## 画面遷移

| パッケージ | 用途 |
|---|---|
| `go_router` | 宣言的ルーティング。ディープリンク対応 |

## コード生成（dev_dependencies）

| パッケージ | 用途 |
|---|---|
| `build_runner` | コード生成ランナー |
| `freezed` | `freezed_annotation` のコード生成器 |
| `json_serializable` | `json_annotation` のコード生成器 |

## Clean Architecture との違い

MVVM テンプレートは Clean Architecture に比べ、以下のパッケージを**省略**しています:

- `firebase_core` / `firebase_auth` — 必要に応じて個別追加
- `drift` / `sqlite3_flutter_libs` — MVVM はデフォルトでローカルDB非対応（必要時に追加）
- `riverpod_annotation` / `riverpod_generator` — シンプルな手書き Notifier を推奨
- `googleapis` / `googleapis_auth` — プロジェクト固有のため省略

必要に応じて `pubspec.yaml` に個別追加してください。

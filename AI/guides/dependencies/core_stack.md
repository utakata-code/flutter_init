# コアスタック: 選定理由とアーキテクチャ

このプロジェクトでは、クリーンアーキテクチャと相性が良く、保守性・型安全性を高めるためのデファクトスタンダードとなるパッケージを選定しています。

## 状態管理: Riverpod + Hooks
- **Riverpod**: 従来の Provider に代わり、コンパイルセーフで依存解決が可能な状態管理・DI（依存注入）コンテナとして採用しています。クリーンアーキテクチャの Presentation 層と Application 層の結合を疎にし、ViewModel のライフサイクル管理を容易にします。
- **flutter_hooks**: Stream や TextEditingController などのローカルな UI 状態の管理を劇的にスリム化し、Widget ツリーの肥大化を防ぐために利用します。

## データモデル・生成: Freezed
- **Freezed**: Entity のイミュータブル（不変）化と `copyWith` の自動生成、およびパターンマッチングを用いた状態遷移の安全なハンドリングを実現します。バージョン3系を使用し、Entity や State は必ず `abstract class` とします。

## 画面遷移: GoRouter
- **go_router**: URLベースの宣言的ルーティングと、Riverpod と組み合わせた直感的なリダイレクト（認証ステータスに応じた画面切り替え等）を容易にするために採用します。

## データベース: Drift (SQLite)
- **Drift**: アプリのローカル状態を永続化するための型安全な SQLite ラッパーです。Infrastructure 層での Data Source 実装において、コンパイル時に SQL と Dart 型のチェックが入るため、堅牢なデータ層の実装が可能です。

## コード解析: Lints
- **flutter_lints**: Dart の静的解析ルールを標準的なものに揃え、プロジェクト全体のコード品質を高く保ちます。（カスタムルールがある場合は別途定義します）。

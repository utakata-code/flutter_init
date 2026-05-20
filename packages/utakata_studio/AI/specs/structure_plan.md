# 構造計画書（テンプレート）

> このファイルは第二段階（構造計画）で更新する、構造計画の雛形です。定義済みアーキテクチャに厳密準拠し、必要ファイルを具体化・合意します。

## メタ情報
- プロジェクト名: 
- バージョン: 
- 最終更新日: 
- 作成者: 

## 構造ポリシー（重要制約）
- クリーンアーキテクチャの構造に厳密準拠: `AI/architecture/features/ARCHITECTURE.md`
- 新しいフォルダの作成禁止（既存定義内でのファイル配置のみ）
- 命名規則の遵守（例: `snake_case`、責務ごとのフォルダ分割）

## 目的と範囲
- 対象フィーチャー: 
- 対象レイヤー（Domain / Infrastructure / Application / Presentation）: 

## 依存・技術参照
- 技術選定: `AI/architecture/guides/common/technology_stack.md`
- 主要ライブラリ（例）: Riverpod, GoRouter, Freezed, Build Runner

## ディレクトリ構造（予定）
```
lib/
  core/
    routing/
    routing/path/
    theme/
    api/
    exceptions/
    database/
    database/table/
  features/
    <feature_name>/
      1_domain/
        1_entities/
        2_repositories/
        3_usecases/
        exceptions/
      2_infrastructure/
        1_models/
        2_data_sources/
          1_local/
            exceptions/
          2_remote/
            exceptions/
        3_repositories/
      3_application/
        1_states/
        2_providers/
        3_notifiers/
      4_presentation/
        1_widgets/
          1_atoms/
          2_molecules/
          3_organisms/
        2_pages/
```

## ファイル定義表（記入用）
- パス: `lib/features/<feature_name>/...`
- ファイル名: 
- 役割: 

例）
- パス: `lib/features/auth/3_application/3_notifiers/user_notifier.dart`
- 役割: ユーザー状態の生成・更新（@riverpod使用）

## ルーティング計画
- ルート一覧: 
- パス設計（`lib/core/routing/path/`）: 
- 画面ページ対応（Presentation層）: 

## 状態管理計画（Riverpod）
- Provider（依存性注入）: `3_application/2_providers/`
- Notifier（状態・副作用管理、@riverpod）: `3_application/3_notifiers/`
- UIからのアクセス: 生成された Provider 経由のみ

## データソース計画
- Local: `2_infrastructure/2_data_sources/1_local/`
- Remote: `2_infrastructure/2_data_sources/2_remote/`
- 例外: 各 data source 配下の `exceptions/`

## モデル・リポジトリ計画
- Models: `2_infrastructure/1_models/`
- Repositories: `2_infrastructure/3_repositories/`（Domainのインターフェースに準拠）

## コード生成・ビルド
- Riverpod / Freezed 等のコード生成方針: 
- 実行: `dart run build_runner build --delete-conflicting-outputs`

## 実装順序（構造計画ベース）
- ドメイン → インフラ → アプリケーション → プレゼンテーション
- 詳細: `flutter-stage3-implementation` スキル（各層の `*_guide.md` を参照）

## 検証・合意
- レビュー観点（網羅性／分割の妥当性／役割の過不足／解像度）
- 合意文言: 「構造計画に合意し、第三段階（実装）へ進む」

## 更新履歴
- YYYY-MM-DD: 初期テンプレート作成
- YYYY-MM-DD: 構造計画草案追記
- YYYY-MM-DD: 合意版更新

## 参考・関連
- プロセス詳細（第二段階）: `flutter-stage2-structure` スキル
- アーキテクチャ規約: `AI/architecture/features/ARCHITECTURE.md`
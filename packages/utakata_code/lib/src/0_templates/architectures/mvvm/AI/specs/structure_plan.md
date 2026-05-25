# 構造計画書（テンプレート）

> このファイルは第二段階（構造計画）で更新する、構造計画の雛形です。定義済みアーキテクチャに厳密準拠し、必要ファイルを具体化・合意します。

## メタ情報
- プロジェクト名: 
- バージョン: 
- 最終更新日: 
- 作成者: 

## 構造ポリシー（重要制約）
- MVVM アーキテクチャの構造に厳密準拠: `AI/architecture/guides/README.md`
- 新しいフォルダの作成禁止（既存定義内でのファイル配置のみ）
- 命名規則の遵守（例: `snake_case`、責務ごとのフォルダ分割）

## 目的と範囲
- 対象フィーチャー: 
- 対象レイヤー（Model / ViewModel / View）: 

## 依存・技術参照
- 技術選定: `AI/architecture/guides/dependencies/core_stack.md`
- 主要ライブラリ（例）: hooks_riverpod, GoRouter, Freezed, Dio

## ディレクトリ構造（予定）
```
lib/
  core/
    routing/
    theme/
    di/
    api/
  features/
    {permission}/
      {feature_name}/
        1_model/
          1_entities/
          2_repositories/
          3_services/
          exceptions/
        2_viewmodel/
          1_states/
          2_notifiers/
        3_view/
          1_widgets/
          2_screens/
```

## ファイル定義表（記入用）
- パス: `lib/features/{permission}/{feature_name}/...`
- ファイル名: 
- 役割: 

例）
- パス: `lib/features/user/memo/2_viewmodel/2_notifiers/memo_notifier.dart`
- 役割: メモ状態の生成・更新（Riverpod Notifier 使用）

## ルーティング計画
- ルート一覧: 
- パス設計（`lib/core/routing/`）: 
- 画面スクリーン対応（View層）: 

## 状態管理計画（Riverpod）
- DI（依存性注入）: `core/di/providers.dart`
- Notifier（状態・副作用管理）: `2_viewmodel/2_notifiers/`
- UIからのアクセス: Notifier Provider 経由のみ

## サービス計画
- Service: `1_model/3_services/`（ビジネスロジックの集約）
- Repository: `1_model/2_repositories/`（データアクセスの抽象化）
- Repository実装: `1_model/2_repositories/`（同ディレクトリに配置）

## コード生成・ビルド
- Freezed 等のコード生成方針: 
- 実行: `dart run build_runner build --delete-conflicting-outputs`

## 実装順序（構造計画ベース）
- Model → ViewModel → View
- 詳細: 各層の `GUIDE.md` を参照

## 検証・合意
- レビュー観点（網羅性／分割の妥当性／役割の過不足／解像度）
- 合意文言: 「構造計画に合意し、第三段階（実装）へ進む」

## 更新履歴
- YYYY-MM-DD: 初期テンプレート作成
- YYYY-MM-DD: 構造計画草案追記
- YYYY-MM-DD: 合意版更新

## 参考・関連
- プロセス詳細（第二段階）: `flutter-stage2-structure` スキル
- アーキテクチャ規約: `AI/architecture/guides/README.md`

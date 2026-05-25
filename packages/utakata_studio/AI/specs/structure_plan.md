# 構造計画書

> このファイルは第二段階（構造計画）で更新する構造計画書です。定義済みアーキテクチャに厳密準拠し、必要ファイルを具体化・合意します。

## メタ情報
- プロジェクト名: utakata studio
- バージョン: 0.2.0
- 最終更新日: 2026-05-22
- 作成者: AI + haruma

## 構造ポリシー（重要制約）
- クリーンアーキテクチャの構造に厳密準拠: `AI/architecture/features/ARCHITECTURE.md`
- 新しいフォルダの作成禁止（既存定義内でのファイル配置のみ）
- 命名規則の遵守: `snake_case`、責務ごとのフォルダ分割
- 権限レベル: `direct`（権限管理不要のデスクトップアプリのため直下配置）

## 目的と範囲
- 対象フィーチャー:
  - `arch_viewer` — アーキテクチャ定義のビジュアルビューア + サイドバー（メイン画面）
  - `validation` — YAML パース・バリデーション + ファイル変更検知
  - `layer_visualizer` — レイヤー構造のグラフィカル描画
  - `settings` — utakata CLI パス設定等のアプリ設定
  - `command_runner` — **[v0.2.0]** utakata CLI コマンドの GUI 実行 + 結果表示
  - `feature_viewer` — **[v0.2.0 NEW]** feature_request.yaml のビジュアルビューア
  - `dashboard` — **[v0.2.0 NEW]** utakata status のダッシュボード表示
- 対象レイヤー: Domain / Infrastructure / Application / Presentation（4 層すべて）

## 依存・技術参照
- 技術選定: `AI/architecture/guides/common/technology_stack.md`
- 主要ライブラリ:
  - hooks_riverpod（状態管理）
  - flutter_hooks（UI フック）
  - freezed（データモデル）
  - yaml（YAML パース）
  - go_router（ルーティング）
  - file_picker（フォルダ選択）
  - window_manager（デスクトップウィンドウ制御）
  - utakata_code（ドメインモデル共有、path 依存）

## ディレクトリ構造（予定）

```
lib/
  main.dart
  core/
    theme/
      studio_theme.dart           # ダークテーマ定義（カラー、フォント、グラデーション）
    config/
      app_config.dart             # アプリ設定（utakata CLI パス等）
    cli_bridge/
      cli_bridge.dart             # CLI 実行基盤（Process.run / Process.start）
      cli_result.dart             # CLI 実行結果モデル
      cli_bridge_provider.dart    # CliBridge の Riverpod Provider
    routing/
      app_router.dart             # go_router ルーティング定義（ShellRoute）
      path/
        app_paths.dart            # ルートパス定数
  features/
    arch_viewer/                  # → 既存
    validation/                   # → 既存
    layer_visualizer/             # → 既存
    settings/                     # → 既存
    command_runner/               # → v0.2.0
    feature_viewer/               # → v0.2.0 NEW
      4_presentation/
        2_pages/
          features_page.dart      # feature_request.yaml ビジュアルビューア
    dashboard/                    # → v0.2.0 NEW
      4_presentation/
        2_pages/
          dashboard_page.dart     # utakata status ダッシュボード
      1_domain/
        1_entities/
          arch_definition_entity.dart   # arch_definition.yaml 全体を表すエンティティ
        2_repositories/
          arch_definition_repository.dart  # ファイル読み込みのインターフェース
        3_usecases/
          load_arch_definition_usecase.dart  # YAML ロード＋パースのユースケース
        exceptions/
          arch_viewer_exceptions.dart
      2_infrastructure/
        1_models/
          arch_definition_model.dart     # YAML → エンティティ変換
        2_data_sources/
          1_local/
            arch_definition_local_data_source.dart  # ファイルシステムからの読み込み
            exceptions/
          2_remote/
            exceptions/
        3_repositories/
          arch_definition_repository_impl.dart
      3_application/
        1_states/
          arch_viewer_state.dart         # ビューア全体の状態（ロード中/成功/エラー）
        2_providers/
          arch_viewer_providers.dart     # DI プロバイダ定義
        3_notifiers/
          arch_viewer_notifier.dart      # ビューアの状態管理
      4_presentation/
        1_widgets/
          1_atoms/
            section_header_atom.dart       # セクションヘッダー（LAYERS, NAMING_RULES 等）
            status_badge_atom.dart         # ステータスバッジ（有効/エラー）
          2_molecules/
            layer_summary_card_molecule.dart   # レイヤーのサマリーカード
            naming_rule_card_molecule.dart     # 命名規則のカード
            core_module_card_molecule.dart     # コアモジュールのカード
            guide_card_molecule.dart           # ガイドのカード
          3_organisms/
            sidebar_organism.dart              # 左ペイン: サイドバー全体
            arch_definition_viewer_organism.dart  # 中央ペイン: セクション別ビューア
        2_pages/
          studio_home_page.dart               # メインページ（3ペイン統合）
    validation/
      1_domain/
        1_entities/
          validation_result_entity.dart       # バリデーション結果エンティティ
        2_repositories/
          validation_repository.dart
        3_usecases/
          validate_yaml_usecase.dart           # YAML バリデーションのユースケース
        exceptions/
          validation_exceptions.dart
      2_infrastructure/
        1_models/
          validation_result_model.dart
        2_data_sources/
          1_local/
            yaml_file_watcher_data_source.dart  # ファイル変更検知（FileSystemEntity.watch）
            exceptions/
          2_remote/
            exceptions/
        3_repositories/
          validation_repository_impl.dart
      3_application/
        1_states/
          validation_state.dart
        2_providers/
          validation_providers.dart
        3_notifiers/
          validation_notifier.dart
      4_presentation/
        1_widgets/
          1_atoms/
          2_molecules/
            validation_status_molecule.dart    # バリデーション結果のステータス表示
          3_organisms/
        2_pages/
    layer_visualizer/
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
          layer_visualizer_state.dart
        2_providers/
          layer_visualizer_providers.dart
        3_notifiers/
          layer_visualizer_notifier.dart
      4_presentation/
        1_widgets/
          1_atoms/
            dependency_arrow_atom.dart         # レイヤー間の依存矢印
          2_molecules/
            layer_card_molecule.dart            # 個別レイヤーのグラデーションカード
          3_organisms/
            layer_tree_visualizer_organism.dart # 右ペイン: レイヤー構造全体描画
        2_pages/
    settings/
      1_domain/
        1_entities/
          app_settings_entity.dart             # アプリ設定（CLI パス等）
        2_repositories/
          settings_repository.dart
        3_usecases/
        exceptions/
      2_infrastructure/
        1_models/
        2_data_sources/
          1_local/
            settings_local_data_source.dart    # shared_preferences での永続化
            exceptions/
          2_remote/
            exceptions/
        3_repositories/
          settings_repository_impl.dart
      3_application/
        1_states/
          settings_state.dart
        2_providers/
          settings_providers.dart
        3_notifiers/
          settings_notifier.dart
      4_presentation/
        1_widgets/
          1_atoms/
          2_molecules/
          3_organisms/
        2_pages/
           settings_page.dart
    command_runner/
      1_domain/
        1_entities/
          command_result_entity.dart        # CLI 実行結果エンティティ
        2_repositories/
          command_runner_repository.dart
        3_usecases/
          run_command_usecase.dart           # CLI コマンド実行ユースケース
        exceptions/
          command_runner_exception.dart
      2_infrastructure/
        1_models/
          command_runner_model.dart          # CliResult → Entity 変換
        2_data_sources/
          1_local/
            command_runner_local_data_source.dart  # CliBridge ラッパー
            exceptions/
          2_remote/
            exceptions/
        3_repositories/
          command_runner_repository_impl.dart
      3_application/
        1_states/
          command_runner_state.dart          # idle/running/completed/error
        2_providers/
          command_runner_providers.dart
        3_notifiers/
          command_runner_notifier.dart
      4_presentation/
        1_widgets/
          1_atoms/
            command_button_atom.dart          # CLI コマンドボタン
          2_molecules/
            command_output_molecule.dart      # 出力のリアルタイム表示
          3_organisms/
            command_panel_organism.dart       # コマンドボタン + 出力パネル統合
        2_pages/
          command_runner_page.dart            # Health タブページ
```

## ファイル定義表

### arch_viewer フィーチャー

| パス | ファイル名 | 役割 |
|---|---|---|
| `1_domain/1_entities/` | `arch_definition_entity.dart` | arch_definition.yaml 全体を表す不変エンティティ。utakata_code のドメインモデルを集約 |
| `1_domain/2_repositories/` | `arch_definition_repository.dart` | ファイル読み込みの抽象インターフェース |
| `1_domain/3_usecases/` | `load_arch_definition_usecase.dart` | YAML ロード → パース → エンティティ変換 |
| `2_infrastructure/1_models/` | `arch_definition_model.dart` | YAML Map → ArchDefinitionEntity への変換ロジック |
| `2_infrastructure/2_data_sources/1_local/` | `arch_definition_local_data_source.dart` | dart:io でファイル読み込み |
| `2_infrastructure/3_repositories/` | `arch_definition_repository_impl.dart` | リポジトリ実装（DataSource → Entity） |
| `3_application/1_states/` | `arch_viewer_state.dart` | ビューアの状態（loading / loaded / error） |
| `3_application/2_providers/` | `arch_viewer_providers.dart` | Riverpod DI 定義 |
| `3_application/3_notifiers/` | `arch_viewer_notifier.dart` | ビューア状態の管理 |
| `4_presentation/2_pages/` | `studio_home_page.dart` | 3ペイン統合のメインページ |
| `4_presentation/1_widgets/3_organisms/` | `sidebar_organism.dart` | 左ペイン: プロジェクト情報・ナビ・ステータス |
| `4_presentation/1_widgets/3_organisms/` | `arch_definition_viewer_organism.dart` | 中央ペイン: セクション別ビューア |

### validation フィーチャー

| パス | ファイル名 | 役割 |
|---|---|---|
| `1_domain/1_entities/` | `validation_result_entity.dart` | バリデーション結果（isValid, errorMessage, 統計） |
| `1_domain/3_usecases/` | `validate_yaml_usecase.dart` | YAML パース → 構文チェック → 結果返却 |
| `2_infrastructure/2_data_sources/1_local/` | `yaml_file_watcher_data_source.dart` | ファイル監視（FileSystemEntity.watch） |
| `3_application/3_notifiers/` | `validation_notifier.dart` | バリデーション状態管理 + ファイル変更時の自動再検証 |
| `4_presentation/1_widgets/2_molecules/` | `validation_status_molecule.dart` | バリデーション結果のステータスカード |

### layer_visualizer フィーチャー

| パス | ファイル名 | 役割 |
|---|---|---|
| `3_application/3_notifiers/` | `layer_visualizer_notifier.dart` | ビジュアライザ状態管理 |
| `4_presentation/1_widgets/1_atoms/` | `dependency_arrow_atom.dart` | レイヤー間の依存方向を示す矢印 |
| `4_presentation/1_widgets/2_molecules/` | `layer_card_molecule.dart` | 個別レイヤーのグラデーションカード |
| `4_presentation/1_widgets/3_organisms/` | `layer_tree_visualizer_organism.dart` | 右ペイン: レイヤーツリー全体描画 |

### settings フィーチャー

| パス | ファイル名 | 役割 |
|---|---|---|
| `1_domain/1_entities/` | `app_settings_entity.dart` | アプリ設定（utakata CLI パス等） |
| `2_infrastructure/2_data_sources/1_local/` | `settings_local_data_source.dart` | shared_preferences での永続化 |
| `3_application/3_notifiers/` | `settings_notifier.dart` | 設定の読み込み・保存 |
| `4_presentation/2_pages/` | `settings_page.dart` | 設定画面（CLI パスのオーバーライド等） |

### command_runner フィーチャー（v0.2.0）

| パス | ファイル名 | 役割 |
|---|---|---|
| `1_domain/1_entities/` | `command_result_entity.dart` | CLI 実行結果（command, exitCode, stdout, stderr, duration） |
| `1_domain/2_repositories/` | `command_runner_repository.dart` | CLI 実行の抽象インターフェース |
| `1_domain/3_usecases/` | `run_command_usecase.dart` | CLI コマンド実行ユースケース（callable） |
| `2_infrastructure/1_models/` | `command_runner_model.dart` | CliResult → CommandResultEntity 変換 |
| `2_infrastructure/2_data_sources/1_local/` | `command_runner_local_data_source.dart` | CliBridge ラッパー |
| `2_infrastructure/3_repositories/` | `command_runner_repository_impl.dart` | Repository 実装 |
| `3_application/1_states/` | `command_runner_state.dart` | idle / running / completed / error |
| `3_application/2_providers/` | `command_runner_providers.dart` | DI Provider |
| `3_application/3_notifiers/` | `command_runner_notifier.dart` | コマンド実行 + 状態管理 |
| `4_presentation/1_widgets/1_atoms/` | `command_button_atom.dart` | CLI コマンドボタン |
| `4_presentation/1_widgets/2_molecules/` | `command_output_molecule.dart` | 出力のリアルタイム表示 |
| `4_presentation/1_widgets/3_organisms/` | `command_panel_organism.dart` | ボタン群 + 出力パネル統合 |
| `4_presentation/2_pages/` | `command_runner_page.dart` | Health タブページ |

## ルーティング計画
- v0.1.0: `home` (/) + `settings` (/settings) — go_router 使用
- v0.2.0: ShellRoute でサイドバー常時表示 + 以下のルート追加:
  - `health` (/health) — CLI コマンド実行画面（command_runner）
  - `features` (/features) — feature_request.yaml ビューア（feature_viewer）
  - `dashboard` (/dashboard) — utakata status ダッシュボード（dashboard）

## 状態管理計画（Riverpod）

### Provider（依存性注入）
- `arch_viewer_providers.dart`: Repository, UseCase, DataSource の DI
- `validation_providers.dart`: ValidateYamlUsecase, FileWatcher の DI
- `layer_visualizer_providers.dart`: ビジュアライザの DI
- `settings_providers.dart`: Settings Repository の DI

### Notifier（状態・副作用管理）
- `arch_viewer_notifier.dart`: YAML ロード → パース → 状態更新
- `validation_notifier.dart`: バリデーション実行 + ファイル監視ストリームの購読
- `layer_visualizer_notifier.dart`: レイヤーデータの変換・フィルタ
- `settings_notifier.dart`: 設定の読み込み・保存

### UI からのアクセス
- `HookConsumerWidget` で Provider を watch
- 状態変更は Notifier のメソッド経由のみ

## データソース計画
- **Local**:
  - `arch_definition_local_data_source.dart`: dart:io の File で YAML 読み込み
  - `yaml_file_watcher_data_source.dart`: FileSystemEntity.watch でファイル変更監視
  - `settings_local_data_source.dart`: shared_preferences でアプリ設定を永続化
- **Remote**: v0.1.0 では不使用（ローカル専用）
- **例外**: 各 data source 配下の `exceptions/` に DataSource 固有の例外を定義

## モデル・リポジトリ計画
- **Models**:
  - `arch_definition_model.dart`: YAML Map → ArchDefinitionEntity への変換。utakata_code のドメインモデル（LayerDefinitionEntity 等）を直接利用
  - `validation_result_model.dart`: パース結果の統計情報をまとめる変換
- **Repositories**: Domain のインターフェースに準拠し、Infrastructure で実装

## コード生成・ビルド
- freezed: エンティティ・状態クラスに使用（ArchDefinitionEntity, ValidationResultEntity, AppSettingsEntity 等）
- riverpod_generator: 必要に応じて @riverpod アノテーションを使用（v0.1.0 では手動 Provider でも可）
- 実行: `dart run build_runner build`

## 実装順序（構造計画ベース）

### Phase 1: 基盤
1. `core/theme/studio_theme.dart` — ダークテーマ定義
2. `core/config/app_config.dart` — アプリ設定定義
3. `main.dart` — エントリポイント + ProviderScope + window_manager 初期化

### Phase 2: settings フィーチャー（先に作る: 他フィーチャーが CLI パスを参照する）
1. Domain: `app_settings_entity.dart` → `settings_repository.dart`
2. Infrastructure: `settings_local_data_source.dart` → `settings_repository_impl.dart`
3. Application: `settings_state.dart` → `settings_providers.dart` → `settings_notifier.dart`
4. Presentation: `settings_page.dart`

### Phase 3: validation フィーチャー
1. Domain: `validation_result_entity.dart` → `validation_repository.dart` → `validate_yaml_usecase.dart`
2. Infrastructure: `yaml_file_watcher_data_source.dart` → `validation_repository_impl.dart`
3. Application: `validation_state.dart` → `validation_providers.dart` → `validation_notifier.dart`
4. Presentation: `validation_status_molecule.dart`

### Phase 4: arch_viewer フィーチャー
1. Domain: `arch_definition_entity.dart` → `arch_definition_repository.dart` → `load_arch_definition_usecase.dart`
2. Infrastructure: `arch_definition_local_data_source.dart` → `arch_definition_model.dart` → `arch_definition_repository_impl.dart`
3. Application: `arch_viewer_state.dart` → `arch_viewer_providers.dart` → `arch_viewer_notifier.dart`
4. Presentation: atoms → molecules → `arch_definition_viewer_organism.dart` → `sidebar_organism.dart`

### Phase 5: layer_visualizer フィーチャー
1. Application: `layer_visualizer_state.dart` → `layer_visualizer_providers.dart` → `layer_visualizer_notifier.dart`
2. Presentation: `dependency_arrow_atom.dart` → `layer_card_molecule.dart` → `layer_tree_visualizer_organism.dart`

### Phase 6: 統合
1. `studio_home_page.dart` — 全フィーチャーを 3 ペインに統合
2. build_runner 実行
3. Desktop + Web ビルド検証

## 検証・合意
- レビュー観点:
  - 4 フィーチャーの分割は適切か
  - 各レイヤーの責務は明確か
  - ファイル名は命名規則に準拠しているか
  - 実装順序に依存関係の矛盾はないか
- 合意文言: 「構造計画に合意し、第三段階（実装）へ進む」

## 更新履歴
- 2026-05-22: 構造計画 v1 作成
- 2026-05-22: v2 更新 — command_runner feature 追加、cli_bridge / go_router / file_picker を反映

## 参考・関連
- 仕様書: `AI/specs/application_specification.md`
- プロセス詳細（第二段階）: `flutter-stage2-structure` スキル
- アーキテクチャ規約: `AI/architecture/features/ARCHITECTURE.md`
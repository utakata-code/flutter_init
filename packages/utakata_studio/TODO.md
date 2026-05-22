# utakata studio — 計画

> utakata モノレポの第2パッケージ。
> utakata_code (CLI) がプロジェクト生成を担うのに対し、
> utakata_studio はアーキテクチャ定義・ガイドの管理 GUI（またはリッチ CLI）を目指す。

---

## ビジョン

**utakata_code** = 「プロジェクトを作る」CLI
**utakata_studio** = 「アーキテクチャを作る・カスタマイズする」ツール

### なぜ分離するか

- `utakata create` はアーキテクチャを**使う**側 → シンプルでいい
- アーキテクチャの定義（層構造・命名規則・ガイド・テンプレート）を**作る・編集する**のは別の関心事
- 将来的に Web UI / Flutter Desktop で視覚的にアーキテクチャを設計できるようにしたい

---

## 背景: v0.4.0 で解決した問題と残課題

### ✅ v0.4.0 で解決済み

| 問題 | 解決策 |
|---|---|
| features/ と guides/ が別ディレクトリで重複 | `AI/architecture/features/` に GUIDE.md + .tmpl を統合 |
| arch_definition.yaml の配置が不適切 | `AI/architecture/arch_definition.yaml` に移動 |
| ガイドのネストが深すぎた | `guides/architectures/clean_architecture/` → `architecture/guides/` にフラット化 |
| flutter create のボイラープレート | `--empty` フラグ追加 |
| テンプレート・定義のカスタマイズ手段がない | プロジェクトローカル (`AI/architecture/`) の定義やテンプレートの優先読み込みを先行実装 (v0.4.1) |

### 🔲 残課題（utakata_studio で解決）

| 問題 | 対応方針 |
|---|---|
| `project_status.yaml` の `core:` セクションがアーキテクチャ依存 | arch_definition.yaml からステータス項目を動的生成 |
| GUIDE.md が268行の静的ファイル | Dart コード駆動でガイドをレンダリング |
| アーキテクチャの追加が手動コピー＆編集のみ | `utakata arch create` コマンドで対話的に生成 |
| テンプレートのUIでの編集手段がない | studio でのビジュアル編集 UI の提供 |

---

## Phase 1: `utakata arch` コマンド (CLI のみ)

`utakata_code` 側に `arch` サブコマンドを追加。studio の前段階。

```
utakata arch list                    # 利用可能なアーキテクチャ一覧
utakata arch show <id>               # アーキテクチャの詳細表示
utakata arch create <id>             # 新しいアーキテクチャを対話的に作成
utakata arch export <id> <path>      # アーキテクチャ定義をエクスポート
```

### やること

- [x] `ArchCommand` の実装（list / show / export / create）
- [x] arch_definition.yaml からの層構造・命名規則の可視化
- [x] 既存テンプレート・定義の管理機能（エクスポート、ボイラープレート作成）

---

## Phase 2: Dart コード駆動のガイド生成

### 設計構想

```dart
/// ガイドの構造を定義するエンティティ
abstract class GuideEntity {
  String get title;           // "エンティティ"
  String get layerPath;       // "1_domain/1_entities"
  String get templateRef;     // "entity.dart.tmpl"
  List<String> get rules;     // 規約リスト
  List<String> get allowedImports;
  List<String> get forbiddenImports;
  String get namingPattern;   // "{name}_entity.dart"
}

/// アーキテクチャごとにガイドセットを定義
abstract class ArchitectureGuideSet {
  String get architectureId;
  List<GuideEntity> get guides;
  
  /// GUIDE.md をレンダリング
  String renderGuide(GuideEntity guide);
}

/// インフラ層でクリーンアーキテクチャ版を実装
class CleanArchitectureGuideSet implements ArchitectureGuideSet {
  @override
  String get architectureId => 'clean_architecture';
  
  @override
  List<GuideEntity> get guides => [
    EntityGuide(),
    RepositoryGuide(),
    UsecaseGuide(),
    // ...
  ];
}
```

### メリット

- アーキテクチャ追加時に Dart コードで型安全に定義できる
- ガイドの内容を動的に生成（プロジェクトの tech stack に応じて変化）
- テストで構造の整合性を保証

### やること

- [x] `GuideEntity` の設計 (`guide_entity.dart` にて実装)
- [x] `GUIDE.md` 動的レンダラーの実装 (`GuideEntity.render`)
- [x] `arch_definition.yaml` との統合（YAML駆動の動的ガイド生成システムの完成）
- [x] 静的な GuideSet クラス群を廃止し、柔軟で汎用的な YAML 駆動設計へ昇華・全面移行

---

## Phase 3: project_status.yaml の汎用化

### 現状の問題

```yaml
core:
  routing: false       # ← clean_architecture 固有
  theme: false         # ← clean_architecture 固有
  database: false      # ← clean_architecture 固有
```

### 解決策

```yaml
# 汎用ヘッダー
project:
  name: "my_app"
  architecture: "clean_architecture"

# arch_definition.yaml の core_modules から動的生成
core_modules:
  - id: routing
    status: false
  - id: theme
    status: false
  # ... arch_definition.yaml で定義されたモジュールのみ
```

### やること

- [x] `arch_definition.yaml` に `core_modules:` セクション追加
- [x] `update_status.sh` をモジュールリストから動的生成に変更
- [x] `project_status.yaml` テンプレートの汎用化
- [x] `utakata create` 時にアーキテクチャ定義の依存関係 (`dependencies`/`dev_dependencies`) を `pubspec.yaml` に自動マージするロジックの実装
- [x] テンプレート・プロジェクト生成完了後に `build_runner` を自動実行する仕組みの統合

---

## Phase 4: ローカル優先読み込み (✅ v0.4.1 で完了)

### 概要

生成後のプロジェクトで `AI/architecture/` を直接編集してカスタマイズできるようにする。

```
読み込み優先順位:
  1. プロジェクトの AI/architecture/features/*.tmpl（あれば）
  2. パッケージの 0_templates/architectures/{id}/AI/architecture/features/*.tmpl
```

### やること

- [x] `TemplateRepository` にローカル優先ロジック追加
- [x] `ArchitectureRepository` にローカル優先ロジック追加
- [x] `utakata feature add` 時のテンプレート解決
- [x] `utakata validate` 時のルール解決

---

## Phase 5: utakata_studio (GUI)

### 形態の選択肢

1. **Flutter Web** — ブラウザで動くアーキテクチャエディタ
2. **Flutter Desktop** — ネイティブアプリ
3. **TUI (Terminal UI)** — リッチな CLI（brick パッケージ等）

### 機能構想

- アーキテクチャの層構造をビジュアルに定義
- 命名規則エディタ
- ガイドのプレビュー・編集
- テンプレートのライブプレビュー
- pub.dev へのアーキテクチャパッケージ公開

### やること (立ち上げ期)

- [ ] GUIのプラットフォーム形態 (Flutter Web / Flutter Desktop / TUI) の最終決定
- [ ] プロジェクトの初期化 (`packages/utakata_studio` 内でのプロジェクト立ち上げ)
- [ ] `utakata_code` (またはコアロジック) のAPI/パッケージ依存整理
- [ ] アーキテクチャ定義 (YAML) をビジュアル編集するための状態管理およびデータフロー設計
- [ ] UIプロトタイプ/モックアップの作成 (画面設計)

---

## 優先順位

| 優先度 | Phase | 見積もり |
|---|---|---|
| ✅ 完了 | Phase 1: `utakata arch` コマンド | v0.5.0 |
| ✅ 完了 | Phase 2: YAML/コード駆動ガイド動的生成 | v0.6.0 |
| ✅ 完了 | Phase 3: project_status 汎用化 ＆ 依存関係自動マージ・自動ビルド実行 | v0.6.0 |
| ✅ 完了 | Phase 4: ローカル優先読み込み | v0.4.1 (先行実装) |
| 🔵 将来 | Phase 5: GUI (utakata_studio) | v1.0.0 |

---

## 保留: `utakata feature init` が `plan_architecture.yaml` の `__files__` を尊重する改善

### 現状の問題

- `utakata feature init` は `plan_architecture.yaml` に記載されたファイル名（`__files__`）を**無視**し、固定テンプレート（`entity.dart`, `repository.dart`, `usecase.dart` 等の汎用名）を常に生成する
- `plan_architecture.yaml` に `section_header_atom.dart`, `sidebar_organism.dart` 等の具体的なファイル名を定義しても反映されない

### あるべき姿

- `plan_architecture.yaml` の `__files__` に記載されたファイル名でスケルトンを生成する
- ファイル名が未指定のディレクトリは、従来通り汎用テンプレート（`entity.dart` 等）を生成する（後方互換）
- atoms / molecules / organisms 等のウィジェットファイルも `plan_architecture.yaml` に定義した名前で生成する

### 対象ファイル（utakata_code 側）

- `lib/src/1_domain/3_usecases/init_features_usecase.dart` — ファイル生成ロジック
- `plan_architecture.yaml` の `__files__` を読み取り、テンプレートの出力ファイル名を動的に変更する

### ステータス

- [ ] 保留（utakata_studio の実装を優先）


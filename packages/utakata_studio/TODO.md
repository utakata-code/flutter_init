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

### 🔲 残課題（utakata_studio で解決）

| 問題 | 対応方針 |
|---|---|
| `project_status.yaml` の `core:` セクションがアーキテクチャ依存 | arch_definition.yaml からステータス項目を動的生成 |
| GUIDE.md が268行の静的ファイル | Dart コード駆動でガイドをレンダリング |
| アーキテクチャの追加が手動コピー＆編集のみ | `utakata arch create` コマンドで対話的に生成 |
| テンプレートのカスタマイズ手段がない | ローカル優先読み込み + studio での編集 UI |

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

- [ ] `ArchCommand` の実装（list / show）
- [ ] arch_definition.yaml からの層構造・命名規則の可視化
- [ ] 既存テンプレートの一覧表示

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

- [ ] `GuideEntity` の設計
- [ ] `ArchitectureGuideSet` インターフェース
- [ ] `CleanArchitectureGuideSet` の実装
- [ ] `GUIDE.md` レンダラー
- [ ] `arch_definition.yaml` との統合

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

- [ ] `arch_definition.yaml` に `core_modules:` セクション追加
- [ ] `update_status.sh` をモジュールリストから動的生成に変更
- [ ] `project_status.yaml` テンプレートの汎用化

---

## Phase 4: ローカル優先読み込み

### 概要

生成後のプロジェクトで `AI/architecture/` を直接編集してカスタマイズできるようにする。

```
読み込み優先順位:
  1. プロジェクトの AI/architecture/features/*.tmpl（あれば）
  2. パッケージの 0_templates/architectures/{id}/AI/architecture/features/*.tmpl
```

### やること

- [ ] `TemplateRepository` にローカル優先ロジック追加
- [ ] `ArchitectureRepository` にローカル優先ロジック追加
- [ ] `utakata feature add` 時のテンプレート解決
- [ ] `utakata validate` 時のルール解決

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

---

## 優先順位

| 優先度 | Phase | 見積もり |
|---|---|---|
| 🔴 高 | Phase 1: `utakata arch` コマンド | v0.5.0 |
| 🟡 中 | Phase 2: コード駆動ガイド生成 | v0.6.0 |
| 🟡 中 | Phase 3: project_status 汎用化 | v0.6.0 |
| 🟢 低 | Phase 4: ローカル優先読み込み | v0.7.0 |
| 🔵 将来 | Phase 5: GUI (utakata_studio) | v1.0.0 |

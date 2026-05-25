# Clean Architecture ガイド — アーキテクチャリファレンス

このディレクトリは **Clean Architecture 4層** のガイドです。
AIエージェントと人間開発者の両方が参照する仕様書として機能します。

---

## このガイドの使い方

### AIエージェント向け

- `arch_summary.md` — **常時参照**（`trigger: always_on`）。実装前に必ず確認
- `../features/**/GUIDE.md` — 各層の実装ガイド（テンプレートと同居）

### 人間向け

- `directory_structure_and_naming_rules.md` — ディレクトリ構造と命名規則の全体像
- `dependencies/` — 推奨パッケージの一覧
- `common/` — 協作ルール・推奨パッケージ

---

## ディレクトリ構造

```
AI/architecture/
├── arch_definition.yaml                    # アーキテクチャ定義（CLI が参照）
├── entry_point_guide.md                    # main.dart / app.dart ガイド
├── guides/                                 # このディレクトリ
│   ├── README.md                           # このファイル（入口）
│   ├── arch_summary.md                     # AI常時参照・最小仕様
│   ├── directory_structure_and_naming_rules.md  # 命名規則の完全版
│   ├── dependencies/                       # 推奨パッケージ定義
│   │   ├── core_stack.yaml
│   │   └── recommended.yaml
│   └── common/                             # 共通ガイド
│       ├── collaboration.md                # 複数人/複数AI 協作ルール
│       ├── recommended_packages.md
│       └── technology_stack.md
├── features/                               # ★ ガイドとテンプレートの統合
│   ├── ARCHITECTURE.md                     # フィーチャー全体構造の説明
│   ├── 1_domain/
│   │   ├── 1_entities/
│   │   │   ├── GUIDE.md                    # 実装ガイド
│   │   │   └── entity.dart.tmpl            # コードテンプレート
│   │   ├── 2_repositories/
│   │   │   ├── GUIDE.md
│   │   │   └── repository.dart.tmpl
│   │   ├── 3_usecases/
│   │   │   ├── GUIDE.md
│   │   │   └── usecase.dart.tmpl
│   │   └── exceptions/
│   │       ├── GUIDE.md
│   │       └── exceptions.dart.tmpl
│   ├── 2_infrastructure/
│   │   ├── 1_models/          GUIDE.md + model.dart.tmpl
│   │   ├── 2_data_sources/
│   │   │   ├── 1_local/       GUIDE.md + local_data_source.dart.tmpl
│   │   │   └── 2_remote/      GUIDE.md + remote_data_source.dart.tmpl
│   │   └── 3_repositories/    GUIDE.md + repository_impl.dart.tmpl
│   ├── 3_application/
│   │   ├── 1_states/          GUIDE.md + state.dart.tmpl
│   │   ├── 2_providers/       GUIDE.md + providers.dart.tmpl
│   │   └── 3_notifiers/       GUIDE.md + notifier.dart.tmpl
│   └── 4_presentation/
│       ├── 1_widgets/
│       │   ├── 1_atoms/       GUIDE.md
│       │   ├── 2_molecules/   GUIDE.md
│       │   └── 3_organisms/   GUIDE.md
│       └── 2_pages/           GUIDE.md + page.dart.tmpl
└── core/                                   # Core 層ガイド
    ├── core_architecture.md
    ├── api/
    ├── database/
    ├── env/
    ├── exceptions/
    ├── routing/
    └── theme/
```

---

## utakata CLI との連携

このガイドは `arch_definition.yaml` の `guides_path:` フィールドで参照されます。

```yaml
# AI/architecture/arch_definition.yaml
id: clean_architecture
guides_path: "AI/architecture/guides"
```

`utakata validate` が命名規則違反を検出した際、このガイドのパスを案内します。

---

## 別アーキテクチャを追加する場合

`utakata arch create` コマンド（将来実装予定）で新しいアーキテクチャを作成できます。
手動で追加する場合は、パッケージの `0_templates/architectures/` 配下に同じ構成で追加してください。

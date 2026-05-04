# Clean Architecture ガイド — 公式推奨アーキテクチャ

このディレクトリはプロジェクトの **公式推奨アーキテクチャ（Clean Architecture 4層）** のガイドです。  
AIエージェントと人間開発者の両方が参照する仕様書として機能します。

---

## このガイドの使い方

### AIエージェント向け

- `arch_summary.md` — **常時参照**（`trigger: always_on`）。実装前に必ず確認
- `lib/**/*_guide.md` — 各ファイルを編集する際に**自動注入**（`applyTo:` frontmatter）

### 人間向け

- `directory_structure_and_naming_rules.md` — ディレクトリ構造と命名規則の全体像
- `lib/` 配下の各ガイド — 各層の実装ルール・サンプルコード
- `dependencies/` — 推奨パッケージの一覧

---

## ディレクトリ構造

```
clean_architecture/
├── README.md                              # このファイル（入口）
├── arch_summary.md                        # AI常時参照・最小仕様（trigger: always_on）
├── directory_structure_and_naming_rules.md # 命名規則・構造の完全版（人間向け）
├── lib/
│   ├── entry_point_guide.md               # main.dart / app.dart
│   ├── core/                              # Core 層ガイド
│   │   ├── core_architecture.md
│   │   ├── api/
│   │   ├── database/
│   │   ├── env/
│   │   ├── exceptions/
│   │   ├── routing/
│   │   └── theme/
│   └── features/                          # Feature 別ガイド（applyTo: で自動注入）
│       ├── features_architecture.md
│       ├── 1_domain/
│       │   ├── 1_entities/entity_guide.md
│       │   ├── 2_repositories/repository_guide.md
│       │   ├── 3_usecases/usecase_guide.md
│       │   └── exceptions/domain_exception_guide.md
│       ├── 2_infrastructure/
│       │   ├── 1_models/model_guide.md
│       │   ├── 2_data_sources/1_local/local_data_source_guide.md
│       │   ├── 2_data_sources/2_remote/remote_data_source_guide.md
│       │   └── 3_repositories/repository_impl_guide.md
│       ├── 3_application/
│       │   ├── 1_states/state_guide.md
│       │   ├── 2_providers/provider_guide.md
│       │   └── 3_notifiers/notifier_guide.md
│       └── 4_presentation/
│           ├── 1_widgets/
│           └── 2_pages/page_guide.md
└── dependencies/
    ├── core_stack.md
    ├── core_stack.yaml
    ├── recommended.md
    └── recommended.yaml
```

---

## utakata CLI との連携

このガイドは `arch_definition.yaml` の `guides_path:` フィールドで参照されます。

```yaml
# arch_definition.yaml
id: clean_architecture
guides_path: "AI/guides/architectures/clean_architecture"
```

`utakata validate` が命名規則違反を検出した際、このガイドのパスを案内します。

---

## 別アーキテクチャを追加する場合

`AI/guides/architectures/` 直下に新しいディレクトリを作成し、
同じ構成（`README.md` + `arch_summary.md`）で追加してください。

```bash
AI/guides/architectures/
├── clean_architecture/  ← 公式推奨
└── mvvm/               ← ユーザー追加例
    ├── README.md
    ├── arch_summary.md  # trigger: always_on
    └── lib/
```

# MVVM (3-layer) アーキテクチャガイド — リファレンス

このディレクトリは **MVVM 3層** のガイドです。
AIエージェントと人間開発者の両方が参照する仕様書として機能します。

---

## このガイドの使い方

### AIエージェント向け

- `arch_summary.md` — **常時参照**（`trigger: always_on`）。実装前に必ず確認
- `../features/**/GUIDE.md` — 各層の実装ガイド（テンプレートと同居）

### 人間向け

- `directory_structure_and_naming_rules.md` — ディレクトリ構造と命名規則の全体像
- `dependencies/` — 推奨パッケージの一覧
- `common/` — 協作ルール

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
│   │   └── core_stack.md
│   └── common/                             # 共通ガイド
│       └── collaboration.md                # 複数人/複数AI 協作ルール
├── features/                               # ★ ガイドとテンプレートの統合
│   ├── 1_model/
│   │   ├── 1_entities/     GUIDE.md
│   │   ├── 2_repositories/ GUIDE.md
│   │   ├── 3_services/     GUIDE.md
│   │   └── exceptions/     GUIDE.md
│   ├── 2_viewmodel/
│   │   ├── 1_states/       GUIDE.md
│   │   └── 2_notifiers/    GUIDE.md
│   └── 3_view/
│       ├── 1_widgets/      GUIDE.md
│       └── 2_screens/      GUIDE.md
└── core/                                   # Core 層ガイド
    ├── core_architecture.md
    ├── routing/    routing_guide.md
    ├── theme/      theme_guide.md
    ├── di/         di_guide.md
    └── api/        api_guide.md
```

---

## utakata CLI との連携

このガイドは `arch_definition.yaml` の `guides_path:` フィールドで参照されます。

```yaml
# AI/architecture/arch_definition.yaml
id: mvvm
guides_path: "AI/architecture/guides"
```

`utakata validate` が命名規則違反を検出した際、このガイドのパスを案内します。

---

## Clean Architecture との違い

| 項目 | Clean Architecture (4層) | MVVM (3層) |
|---|---|---|
| 層の数 | 4層（Domain / Infrastructure / Application / Presentation） | 3層（Model / ViewModel / View） |
| ビジネスロジック | UseCase で 1操作1クラス | Service でまとめて管理 |
| データアクセス | DataSource → RepositoryImpl → Repository I/F | Repository I/F → Repository Impl |
| 状態管理 | Notifier + Provider + State | Notifier + State |
| 推奨規模 | 中〜大規模 | 小〜中規模 |

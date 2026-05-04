---
trigger: always_on
---

# 協作ルール — 複数人/複数AI 共同作業

> このファイルはAIエージェントと人間開発者の**全員が従う**協作ルールです。
> 複数人・複数AIが同じプロジェクトで作業する際のブレを防ぐために定義されています。

---

## Single Source of Truth — ディレクトリの役割分担

| ディレクトリ | 性質 | 更新者 | 説明 |
|---|---|---|---|
| `AI/guides/` | **変わりにくい** | 全員の合意が必要 | アーキテクチャルール・命名規則の定義 |
| `AI/specs/` | **変わる** | 人間開発者 | アプリ要件・フィーチャー定義 |
| `AI/snapshots/` | **自動更新** | utakata CLI | 現在の実装状態のスナップショット |
| `AI/logs/` | **記録** | AI/人間 | 会話ログ・変更履歴 |

---

## 変更プロセス（必ず守ること）

### 仕様変更時
```
1. AI/specs/application_specification.md を更新
2. 影響するフィーチャーを AI/specs/feature_request.yaml に反映
3. utakata plan で計画書を再生成
4. 実装を進める
5. utakata scan + utakata validate でゼロ違反を確認
```

### 新機能追加時
```
1. AI/specs/feature_request.yaml に追記
2. utakata plan
3. utakata feature add <name>
4. 実装
5. utakata validate
```

### アーキテクチャルール変更時
```
1. チーム全員（+ 全AI）に変更を共有
2. AI/guides/architectures/{arch}/arch_summary.md を更新
3. arch_definition.yaml の naming_rules を更新
4. utakata validate で既存コードへの影響を確認
```

---

## AIエージェント向け注意事項

### コード変更前に必ず確認
- `AI/specs/application_specification.md` — 何を作るのか
- `AI/guides/architectures/*/arch_summary.md` — どのルールで作るのか
- `AI/snapshots/current_structure.yaml` — 現在の状態

### コード変更後に必ず実行
```bash
utakata validate   # 命名規則・構造違反がゼロであること
```

### やってはいけないこと
- `AI/guides/` を個人の判断だけで変更する（合意なしの変更禁止）
- 命名規則に従わないファイルを作成する
- `AI/specs/` の更新なしにコードだけ変更する

---

## 人間開発者向けのヒント

### AIに依頼する前に
- 現在のフェーズ（仕様策定/構造計画/実装）を宣言する
- 関連する仕様書ファイルを共有する（`@[AI/specs/application_specification.md]` など）

### AIの出力を受け取ったら
- `utakata validate` を実行して命名規則・構造を確認する
- `AI/specs/` が更新されているか確認する

---

## 参考: プロジェクトのミッション

> **仕様駆動開発 + AIと人間の境なき共作 + 複数人/複数AIでのプロジェクト進行をスムーズにする**

このミッションを実現するために、以下を守り続けることが重要です：
- **ドリフト防止**: コードと仕様書は常に同期させる
- **透明性**: `AI/snapshots/` で現在の状態を誰でも確認できる状態を維持する
- **規則の一元化**: 命名規則・構造定義は `arch_definition.yaml` に一元化する

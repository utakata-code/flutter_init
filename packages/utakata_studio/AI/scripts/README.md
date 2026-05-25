# AI/scripts — utakata CLI への移行ガイド

> このディレクトリのシェルスクリプトは **非推奨** です。
> 代わりに `utakata` CLI を使用してください。

---

## スクリプト → utakata コマンド 対照表

| 旧スクリプト | 新コマンド | 説明 |
|---|---|---|
| `generate/generate_feature.sh` | `utakata feature add <name>` | フィーチャーを追加 |
| `generate/generate_plan.sh` | `utakata plan` | 計画書を生成 |
| `generate/generate_core.sh` | `utakata create` に統合 | Core 層を生成 |
| `status/snapshot.sh` | `utakata scan` | 現在の構造をスキャン |
| `status/check_status.sh` | `utakata status` | 総合ステータスを表示 |
| `status/detect_changes.sh` | `utakata diff` | 計画との差分を確認 |
| `validate/validate_structure.sh` | `utakata validate` | 命名規則・構造を検証 |
| `generate/diff_architecture.sh` | `utakata diff` | アーキテクチャ差分を確認 |
| `build/build_native_ios.sh` | （維持）| iOS ビルド（CLI 非対応） |

---

## utakata のインストール

```bash
# pub.dev からインストール
dart pub global activate utakata

# またはリポジトリからインストール（開発中）
dart pub global activate --source path path/to/utakata_cli
```

## 典型的なワークフロー

```bash
# フィーチャーを追加
utakata feature add memo --permission user

# 計画書を生成
utakata plan

# 全フィーチャーを一括生成
utakata feature init

# 現在の構造をスキャン
utakata scan

# 命名規則・構造を検証（CI前に必ず実行）
utakata validate

# 計画との差分を確認
utakata diff

# 総合ステータスを確認
utakata status
```

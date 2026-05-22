# 実装ステップ概要

## 事前準備チェックリスト

- [ ] プロジェクト初期化: `./AI/scripts/setup/init_project.sh --yes`
- [ ] 依存追加: `./AI/scripts/setup/add_dependencies.sh --yes`
- [ ] Core生成: `./AI/scripts/generate/generate_core.sh --yes`
- [ ] 例外クラス生成: `./AI/scripts/generate/init_core_exceptions.sh --yes`
- [ ] フィーチャー構造生成: `./AI/scripts/generate/generate_feature.sh -n Name -p user -y`

## 実装順序

```
1. Domain層
   └── entities → repositories → usecases → exceptions

2. Infrastructure層
   └── models → data_sources(local) → data_sources(remote) → repositories

3. Application層
   └── states → providers → notifiers

4. Presentation層
   └── pages → widgets(atoms → molecules → organisms)
```

## 各ステップで実行するコマンド

| ステップ | コマンド |
|---------|---------|
| 開始前 | `/status check`, `/validate_structure` |
| 各レイヤー完了後 | `/validate_structure`, `/status update`, `/flutter_analyze` |
| 全体完了後 | `/status report`, `/detect_changes` |

## コード生成後の処理

```bash
# Freezed/Riverpod等のコード生成
dart run build_runner build --delete-conflicting-outputs
```

## レビュー観点

```
✅ 仕様との整合性
✅ ロジックの改善点
✅ コード品質
✅ 命名規則準拠
```

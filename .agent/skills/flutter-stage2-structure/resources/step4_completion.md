# ステップ4: 構造計画書完成

## 完了チェックリスト

### 計画書の完成度確認
- [ ] メタ情報が最新に更新されている
- [ ] ディレクトリ構造が正確に記載されている
- [ ] ファイル定義表がすべて記入されている
- [ ] ルーティング計画が完成している
- [ ] 状態管理計画が明確である
- [ ] データソース計画が定義されている
- [ ] 実装順序が決定されている

### アーキテクチャ準拠確認
- [ ] 新規ディレクトリが作成されていない
- [ ] 4層構造に準拠している
- [ ] 命名規則に従っている
- [ ] 依存方向が正しい

### ドキュメント更新
- [ ] `AI/document/structure_plan.md` を最終版に更新
- [ ] バージョン番号を更新（例: v1.0）
- [ ] 最終更新日を更新
- [ ] 更新履歴セクションに記録

## フェーズ完了宣言テンプレート

```markdown
## 🎉 第二段階（構造計画）完了

以下の構造計画書が完成しました：
- ファイル: `AI/document/structure_plan.md`
- バージョン: v1.0
- 最終更新: [日付]

### 次のステップ
「以上で第二段階の構造計画を完了します。
この計画書を基に、次の第三段階（実装フェーズ）に進みますか？」

### 実行するコマンド
- `/status report` - 包括的なステータス更新
- `/detect_changes` - 変更履歴を記録
```

## 次のフェーズへの引き継ぎ

第三段階（実装）では以下を参照：
- 仕様書: `AI/document/application_specification.md`
- 構造計画書: `AI/document/structure_plan.md`
- 技術スタック: `AI/architecture/technology_stack.md`

### 実装前の準備コマンド
```bash
./AI/scripts/bash/init_project.sh --yes
./AI/scripts/bash/add_dependencies.sh --yes
./AI/scripts/bash/generate_core.sh --yes
./AI/scripts/bash/init_core_exceptions.sh --yes
./AI/scripts/bash/generate_feature.sh -n FeatureName -p user -y
```

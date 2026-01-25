# ステータスファイル形式

## project_status.md

```markdown
# プロジェクトステータス

## 基本情報
- プロジェクト名: [名前]
- 現在のステージ: Stage 1 / 2 / 3
- 最終更新: [日時]

## 進捗状況

### Stage 1: 仕様策定
- [x] ステップ1: ヒアリング
- [x] ステップ2: 草案作成
- [ ] ステップ3: 深掘り
- [ ] ステップ4: 完成

### Stage 2: 構造計画
- [ ] ステップ1: ルール確認
- [ ] ステップ2: 草案作成
- [ ] ステップ3: レビュー
- [ ] ステップ4: 完成

### Stage 3: 実装
- [ ] Domain層
- [ ] Infrastructure層
- [ ] Application層
- [ ] Presentation層

## 実装済みファイル
- `lib/features/user/xxx/1_domain/1_entities/xxx_entity.dart`
- ...

## 問題点・課題
- [課題1]
- [課題2]

## 次のアクション
- [次にやること]
```

## current_structure.md

```markdown
# 現在のプロジェクト構造

生成日時: [日時]

## lib/ 配下
```
lib/
├── core/
│   ├── routing/
│   └── ...
└── features/
    └── ...
```
```

## change_history.md

```markdown
# 変更履歴

## [日付] [時刻]
- 追加: `lib/features/user/xxx/xxx_entity.dart`
- 変更: `lib/core/routing/app_router.dart`
- 削除: `lib/temp/old_file.dart`
```

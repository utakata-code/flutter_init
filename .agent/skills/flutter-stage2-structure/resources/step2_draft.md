# ステップ2: 構造計画書草案作成

## 草案作成の手順

### 1. 仕様書の分析
- `AI/document/application_specification.md` を確認
- 機能要件から必要なファイルを洗い出し
- データ要件からエンティティを特定

### 2. ファイル定義表の作成

#### 記入対象ファイル
`AI/document/structure_plan.md`

#### ファイル定義項目
| 項目 | 説明 |
|-----|------|
| 配置パス | `lib/features/<permission>/<feature>/...` |
| ファイル名 | `xxx_entity.dart` など |
| 役割 | そのファイルの責務を説明 |

### 3. 各セクションへの記入

#### ディレクトリ構造
```
lib/features/user/<feature_name>/
  1_domain/
    1_entities/
      <name>_entity.dart
    2_repositories/
      <name>_repository.dart
    3_usecases/
      get_<name>_usecase.dart
  ...
```

#### ルーティング計画
| ルート | パス | ページ |
|-------|-----|--------|
| ホーム | `/` | `HomePage` |
| 詳細 | `/detail/:id` | `DetailPage` |

#### 状態管理計画
- Provider: 依存性注入
- Notifier: 状態管理（@riverpod使用）

#### データソース計画
- Local: Drift使用
- Remote: HTTP API（必要な場合）

### 4. generate_feature.sh の使用

```bash
# フィーチャー構造の自動生成
./AI/scripts/bash/generate_feature.sh -n FeatureName -p user -y
```

## 草案提示テンプレート

```markdown
## 構造計画書草案（v0.1）

### 概要
- 対象フィーチャー: [名前]
- 対象レイヤー: Domain / Infrastructure / Application / Presentation

### ファイル一覧
| パス | ファイル名 | 役割 |
|-----|----------|------|
| `lib/features/user/xxx/1_domain/1_entities/` | `xxx_entity.dart` | xxxエンティティ定義 |
| ... | ... | ... |

### 確認事項
- [ ] ファイル分割は適切ですか？
- [ ] 不足しているファイルはありますか？
```

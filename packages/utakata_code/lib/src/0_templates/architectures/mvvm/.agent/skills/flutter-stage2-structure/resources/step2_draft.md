# ステップ2: 構造計画書草案作成

## 草案作成の手順

### 1. 仕様書の分析
- `AI/specs/application_specification.md` を確認
- 機能要件から必要なファイルを洗い出し
- データ要件からエンティティを特定

### 2. ファイル定義表の作成

#### 記入対象ファイル
`AI/specs/structure_plan.md`

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
  1_model/
    1_entities/
      <name>_entity.dart
    2_repositories/
      <name>_repository.dart
      <name>_repository_impl.dart
    3_services/
      <name>_service.dart
  2_viewmodel/
    1_states/
      <name>_state.dart
    2_notifiers/
      <name>_notifier.dart
  3_view/
    1_widgets/
      <name>_widget.dart
    2_screens/
      <name>_screen.dart
```

#### ルーティング計画
| ルート | パス | スクリーン |
|-------|-----|-----------|
| ホーム | `/` | `HomeScreen` |
| 詳細 | `/detail/:id` | `DetailScreen` |

#### 状態管理計画
- DI: `core/di/providers.dart` でバインディング
- Notifier: 状態管理（Riverpod Notifier 使用）

#### サービス計画
- Service: ビジネスロジックの集約
- Repository: データアクセスの抽象化 + 実装

### 4. generate_feature.sh の使用

```bash
# フィーチャー構造の自動生成
./AI/scripts/generate/generate_feature.sh -n FeatureName -p user -y
```

## 草案提示テンプレート

```markdown
## 構造計画書草案（v0.1）

### 概要
- 対象フィーチャー: [名前]
- 対象レイヤー: Model / ViewModel / View

### ファイル一覧
| パス | ファイル名 | 役割 |
|-----|----------|------|
| `lib/features/user/xxx/1_model/1_entities/` | `xxx_entity.dart` | xxxエンティティ定義 |
| ... | ... | ... |

### 確認事項
- [ ] ファイル分割は適切ですか？
- [ ] 不足しているファイルはありますか？
```

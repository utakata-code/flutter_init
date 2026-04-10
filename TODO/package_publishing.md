# TODO: フィーチャー生成のパッケージ化検討

> pub.dev に公開する Dart パッケージとして、フィーチャー生成を自動化する方法の検討。

---

## コンセプト

**Entity を書くだけで、残り全層のボイラープレートが自動生成される世界。**

```
開発者が書くもの:
  memo_entity.dart（@FeatureEntity アノテーション付き Freezed クラス）

build_runner が自動生成するもの:
  ├── 1_domain/2_repositories/memo_repository.dart      ← リポジトリI/F
  ├── 2_infrastructure/1_models/memo_model.dart          ← Drift モデル
  ├── 2_infrastructure/2_data_sources/1_local/memo_local_data_source.dart
  ├── 2_infrastructure/3_repositories/memo_repository_impl.dart
  ├── 3_application/1_states/memo_state.dart             ← Freezed 状態クラス
  ├── 3_application/2_providers/memo_providers.dart       ← DI プロバイダ
  ├── 3_application/3_notifiers/memo_notifier.dart        ← @riverpod Notifier
  └── 4_presentation/2_pages/memo_page.dart              ← HookConsumerWidget
```

**前回の結論から大きく変わった点:**
- 「ゼロからの足場作り」ではなく「Entity → 残り全層の変換」と捉えると、build_runner の設計思想に合致する
- Entity のフィールド情報（型・名前）を読み取って、各層に反映できる（CRUD メソッド、テーブル定義等）
- Freezed / Riverpod と同じ `annotation + generator` パターンを踏襲できる

---

## パッケージ構成

pub.dev には **2つのパッケージ** を公開する（Freezedと同じ分離パターン）。

```
flutter_init_annotation/    ← dependencies に追加（軽量・ランタイム用）
  lib/
    src/
      feature_entity.dart     # @FeatureEntity アノテーション
      feature_config.dart     # 設定用クラス（Permission enum 等）
    flutter_init_annotation.dart  # barrel export

flutter_init_gen/            ← dev_dependencies に追加（ジェネレーター本体）
  lib/
    src/
      builders/
        feature_builder.dart        # カスタム Builder（全層のファイル生成を統括）
        generators/
          repository_generator.dart   # Domain: リポジトリI/F生成
          model_generator.dart        # Infra: Drift モデル生成
          data_source_generator.dart  # Infra: DataSource 生成
          repo_impl_generator.dart    # Infra: リポジトリ実装 生成
          state_generator.dart        # App: State 生成
          provider_generator.dart     # App: Provider 生成
          notifier_generator.dart     # App: Notifier 生成
          page_generator.dart         # Pres: Page 生成
      utils/
        naming.dart            # 命名規則ヘルパー
        field_analyzer.dart    # Entity のフィールド解析
    flutter_init_gen.dart
  build.yaml                  # build_runner 設定
```

---

## ユーザー体験（Developer Experience）

### Step 1: インストール

```yaml
# pubspec.yaml
dependencies:
  flutter_init_annotation: ^1.0.0

dev_dependencies:
  flutter_init_gen: ^1.0.0
  build_runner: ^2.4.0
```

### Step 2: Entity を書く

```dart
// lib/features/user/memo/1_domain/1_entities/memo_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_init_annotation/flutter_init_annotation.dart';

part 'memo_entity.freezed.dart';

/// メモ エンティティ
@FeatureEntity(
  permission: Permission.user,   // 権限レベル
  generateRemote: false,         // リモートDS不要
  generatePage: true,            // ページ生成する
)
@freezed
class MemoEntity with _$MemoEntity {
  const factory MemoEntity({
    required String id,
    required String title,
    required String content,
    @Default(false) bool isArchived,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MemoEntity;
}
```

### Step 3: build_runner 実行

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 4: 生成結果を確認

自動で8ファイルが生成される（+ Freezed の `.freezed.dart` と Riverpod の `.g.dart`）。

---

## 技術的な実装方針

### アノテーション定義

```dart
// flutter_init_annotation/lib/src/feature_entity.dart

/// フィーチャーの権限レベル
enum Permission { admin, user, shared, direct }

/// Entity に付与するアノテーション
/// build_runner がこれを検知して全層のファイルを生成する
class FeatureEntity {
  /// 権限レベル（admin / user / shared / direct）
  final Permission permission;

  /// リモートデータソースを生成するか
  final bool generateRemote;

  /// ページ（Presentation）を生成するか
  final bool generatePage;

  /// ユースケースの動詞リスト（例: ['get', 'create', 'update', 'delete']）
  /// 指定しない場合は CRUD のデフォルトを生成
  final List<String>? usecaseVerbs;

  const FeatureEntity({
    this.permission = Permission.user,
    this.generateRemote = false,
    this.generatePage = true,
    this.usecaseVerbs,
  });
}
```

### Builder の仕組み

```
入力: memo_entity.dart（@FeatureEntity アノテーション付き）
         ↓
    [FieldAnalyzer]  Entity のフィールドを解析
         ↓ fields: [{name: id, type: String}, {name: title, type: String}, ...]
         ↓
    [FeatureBuilder]  各 Generator に振り分け
         ↓
    ┌────────────────────────────────────┐
    │  RepositoryGenerator              │ → memo_repository.dart
    │  ModelGenerator                   │ → memo_model.dart
    │  DataSourceGenerator              │ → memo_local_data_source.dart
    │  RepoImplGenerator                │ → memo_repository_impl.dart
    │  StateGenerator                   │ → memo_state.dart
    │  ProviderGenerator                │ → memo_providers.dart
    │  NotifierGenerator                │ → memo_notifier.dart
    │  PageGenerator (optional)         │ → memo_page.dart
    └────────────────────────────────────┘
```

### build.yaml（重要: クロスディレクトリ出力）

```yaml
# flutter_init_gen/build.yaml
builders:
  feature_builder:
    import: "package:flutter_init_gen/builder.dart"
    builder_factories: ["featureBuilder"]
    build_extensions:
      # Entity の位置から各層のパスへマッピング
      # 入力:  lib/features/{perm}/{feat}/1_domain/1_entities/{name}_entity.dart
      # 出力:  同一フィーチャー内の各層へ
      "lib/features/{{dir}}/1_domain/1_entities/{{name}}_entity.dart":
        - "lib/features/{{dir}}/1_domain/2_repositories/{{name}}_repository.dart"
        - "lib/features/{{dir}}/2_infrastructure/1_models/{{name}}_model.dart"
        - "lib/features/{{dir}}/2_infrastructure/2_data_sources/1_local/{{name}}_local_data_source.dart"
        - "lib/features/{{dir}}/2_infrastructure/3_repositories/{{name}}_repository_impl.dart"
        - "lib/features/{{dir}}/3_application/1_states/{{name}}_state.dart"
        - "lib/features/{{dir}}/3_application/2_providers/{{name}}_providers.dart"
        - "lib/features/{{dir}}/3_application/3_notifiers/{{name}}_notifier.dart"
        - "lib/features/{{dir}}/4_presentation/2_pages/{{name}}_page.dart"
    auto_apply: dependents
    build_to: source     # ← キャッシュではなくソースに直接書き出す
    runs_before: ["freezed", "riverpod_generator"]  # Freezed/Riverpod の前に実行
```

### 生成内容の具体例

Entity のフィールドを読み取って、各ファイルの中身を動的に生成する：

#### Repository（Domain層）
```dart
// 自動生成: memo_repository.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// flutter_init_gen により自動生成

import '../1_entities/memo_entity.dart';

/// MemoEntity のリポジトリインターフェース
abstract class MemoRepository {
  /// 全件取得
  Future<List<MemoEntity>> getAll();

  /// ID で取得
  Future<MemoEntity?> getById(String id);

  /// 作成
  Future<void> create(MemoEntity entity);

  /// 更新
  Future<void> update(MemoEntity entity);

  /// 削除
  Future<void> delete(String id);

  /// 変更を監視
  Stream<List<MemoEntity>> watchAll();
}
```

#### Model（Infrastructure層）
```dart
// 自動生成: memo_model.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:drift/drift.dart';
import '../../1_domain/1_entities/memo_entity.dart';

/// MemoEntity に対応する Drift テーブル定義
class MemoModels extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// MemoModel ↔ MemoEntity の変換拡張
extension MemoModelMapper on MemoModel {
  MemoEntity toEntity() => MemoEntity(
    id: id,
    title: title,
    content: content,
    isArchived: isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
```

#### Notifier（Application層）
```dart
// 自動生成: memo_notifier.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../1_states/memo_state.dart';
import '../../1_domain/1_entities/memo_entity.dart';
import '../2_providers/memo_providers.dart';

part 'memo_notifier.g.dart';

/// Memo Notifier — 状態管理
@riverpod
class MemoNotifier extends _$MemoNotifier {
  @override
  MemoState build() {
    _loadAll();
    return const MemoState.loading();
  }

  Future<void> _loadAll() async {
    final repo = ref.read(memoRepositoryProvider);
    try {
      final items = await repo.getAll();
      state = MemoState.loaded(items: items);
    } on Exception catch (e) {
      state = MemoState.error(message: e.toString());
    }
  }

  // TODO: create / update / delete メソッドを必要に応じて実装
}
```

---

## 生成ファイルの扱い方 — 2つの戦略

### 課題

build_runner の生成ファイルは通常「手動編集禁止」（`.g.dart` / `.freezed.dart`）。
しかしフィーチャーのファイル（特に Notifier / Page）は手動で書き足す必要がある。

### 戦略A: `.init.dart` パターン（初回生成のみ）

```dart
// Builder の挙動:
// 1. memo_notifier.dart が存在しない → 生成する
// 2. memo_notifier.dart が既に存在する → スキップする（上書きしない）
```

- ✅ 開発者が自由に編集できる
- ✅ 既存コードが壊れない
- ❌ Entity のフィールド変更が自動反映されない

### 戦略B: ベースクラス + 拡張パターン（推奨）

```dart
// 自動生成（常に再生成されるファイル）:
//   memo_repository.dart        ← I/F、常に Entity と同期
//   memo_state.dart             ← 状態定義、常に Entity と同期
//   memo_providers.dart         ← DI wiring、常に同期
//   memo_model.dart             ← Drift テーブル、常に同期

// 自動生成 → 初回のみ（開発者が編集する想定）:
//   memo_repository_impl.dart   ← 初回のみ生成、その後は手動管理
//   memo_notifier.dart          ← 初回のみ生成、その後は手動管理
//   memo_page.dart              ← 初回のみ生成、その後は手動管理
//   memo_local_data_source.dart ← 初回のみ生成、その後は手動管理
```

**分類の考え方:**

| ファイル | 性質 | 再生成 | 理由 |
|---------|------|--------|------|
| Repository I/F | Entity のフィールドから CRUD を導出 | ✅ 常に | フィールド変更に追従すべき |
| Model | Entity のフィールド → Drift カラム | ✅ 常に | フィールド変更に追従すべき |
| State | Entity リストの Freezed ラッパー | ✅ 常に | 型が変われば自動追従 |
| Providers | 型情報による DI wiring | ✅ 常に | 型が変われば自動追従 |
| RepositoryImpl | ビジネスロジック含む | 🔒 初回のみ | 開発者がカスタマイズ |
| DataSource | DB操作の実装 | 🔒 初回のみ | 開発者がカスタマイズ |
| Notifier | 状態管理ロジック | 🔒 初回のみ | 開発者がカスタマイズ |
| Page | UIレイアウト | 🔒 初回のみ | 開発者がカスタマイズ |

---

## 初期ディレクトリ構造の問題

### 問題

build_runner は**ファイルを生成する**が、**空ディレクトリは作れない**。
Entity を配置するための最低限のディレクトリ構造は事前に必要。

### 解決策: Mason との組み合わせ

```
Phase 1: Mason で骨格作成（1回きり）
  mason make feature → ディレクトリ構造 + Entity の雛形ファイルを生成

Phase 2: build_runner で全層生成（継続的）
  Entity を編集 → build_runner build → 残り全ファイルが自動生成/更新
```

つまり **Mason + build_runner のハイブリッド** が最終解。

```bash
# 1. フィーチャーの骨格を作成（Mason — 1回きり）
mason make feature --feature_name memo --permission user

# 2. 生成された Entity 雛形を編集（開発者が書く唯一の場所）
# lib/features/user/memo/1_domain/1_entities/memo_entity.dart を編集

# 3. build_runner で全層のファイルを生成
dart run build_runner build --delete-conflicting-outputs

# 結果: Entity を書いただけで全層のファイルが揃う
```

---

## pub.dev 公開計画

### 公開パッケージ

| パッケージ名 | 種別 | 説明 |
|------------|------|------|
| `flutter_init_annotation` | dependency | `@FeatureEntity` アノテーション + `Permission` enum |
| `flutter_init_gen` | dev_dependency | build_runner ジェネレーター本体 |

### オプション（将来）

| パッケージ名 | 種別 | 説明 |
|------------|------|------|
| `flutter_init_cli` | global activate | Mason Brick 統合 + validate + status |
| `flutter_init_bricks` | Mason Brick | 骨格生成テンプレート集（Git配布 or brickhub） |

### ネーミングの検討

- `flutter_init_*` — 現リポ名と一致、分かりやすい
- `clean_gen` / `clean_feature_gen` — 用途が明確
- `feature_forge` — キャッチーだがFlutter色が薄い

→ **`flutter_init_annotation` / `flutter_init_gen` を第一候補**とする

---

## 開発ロードマップ

### Phase 1: MVPリリース（v0.1.0）
- [ ] `flutter_init_annotation` パッケージ作成
  - [ ] `@FeatureEntity` アノテーション定義
  - [ ] `Permission` enum 定義
- [ ] `flutter_init_gen` パッケージ作成
  - [ ] Entity のフィールド解析（`FieldAnalyzer`）
  - [ ] `RepositoryGenerator` — Repository I/F 生成
  - [ ] `StateGenerator` — State 生成
  - [ ] `ProviderGenerator` — Provider 生成
  - [ ] `build.yaml` 設定（クロスディレクトリ出力）
- [ ] テスト（`build_test` パッケージ使用）
- [ ] サンプルプロジェクト（example/）

### Phase 2: 全層対応（v0.2.0）
- [ ] `ModelGenerator` — Drift モデル生成
- [ ] `DataSourceGenerator` — LocalDataSource 生成
- [ ] `RepoImplGenerator` — RepositoryImpl 生成（初回のみ）
- [ ] `NotifierGenerator` — Notifier 生成（初回のみ）
- [ ] `PageGenerator` — Page 生成（初回のみ）
- [ ] 「初回のみ生成」ロジックの実装（既存ファイル検出でスキップ）

### Phase 3: Mason 統合（v0.3.0）
- [ ] Mason Brick（`feature` / `core`）作成
- [ ] `flutter_init_cli` の基本実装
- [ ] README / ドキュメント整備
- [ ] pub.dev 公開

### Phase 4: 高度な機能（v1.0.0）
- [ ] カスタム CRUD 動詞のサポート（`usecaseVerbs`）
- [ ] Remote DataSource 生成（`generateRemote: true` 時）
- [ ] Drift マイグレーション支援
- [ ] E2E テスト
- [ ] CI/CD パイプライン

---

## 技術的な懸念事項と対策

### 1. build_extensions のキャプチャグループの検証

**懸念**: `{{dir}}` がネストしたパス（`user/memo`）を正しくキャプチャできるか
**対策**: 早期にプロトタイプで検証する。ダメなら `build_to: cache` + post-build hookで対応

### 2. 他ジェネレーターとの実行順序

**懸念**: `flutter_init_gen` → `freezed` → `riverpod_generator` の順で走る必要がある
**対策**: `build.yaml` の `runs_before` / `required_inputs` で順序を制御

### 3. 生成ファイルの `part` / `import` パスの正確性

**懸念**: 生成ファイルから Entity や他の生成ファイルへの相対パスが正しいか
**対策**: `build_extensions` のマッピングからパスを動的に計算するユーティリティを作成

### 4. 既存ファイルの上書き防止

**懸念**: 開発者が編集した Notifier / Page を build_runner が上書きしないか
**対策**: Builder 内で `buildStep.canRead()` 等を使いファイル存在をチェック、存在する場合はスキップ

### 5. Freezed との共存

**懸念**: Entity は Freezed が処理し、生成ファイル内の State も Freezed が処理する
**対策**: `runs_before: ["freezed"]` で flutter_init_gen を先に実行させ、State ファイルを先に生成

---

## 競合・類似パッケージの調査

### 現時点で同等のパッケージは見当たらない

| パッケージ | 内容 | 差異 |
|-----------|------|------|
| `mason_cli` | テンプレートスキャフォールディング | ファイル内容の動的生成なし |
| `very_good_cli` | VGV テンプレート | クリーンアーキ4層ではない |
| `stacked_generator` | Stacked アーキ用生成 | Riverpod/Freezed ベースではない |
| `clean_architecture_generator` | CA ボイラープレート | pub.dev に存在するが保守されていない |

**→ 「Entity を入力にした全層自動生成」は pub.dev にニッチが存在する**

---

## 結論

| 方針 | 内容 |
|------|------|
| **パッケージ形態** | `flutter_init_annotation` + `flutter_init_gen` の2パッケージ |
| **配布先** | pub.dev |
| **コア技術** | build_runner + source_gen（`GeneratorForAnnotation`） |
| **入力** | `@FeatureEntity` アノテーション付き Freezed Entity |
| **出力** | Repository I/F, Model, DataSource, State, Provider, Notifier, Page |
| **補助ツール** | Mason Brick で初期ディレクトリ + Entity 雛形作成 |
| **初回のみ生成** | 開発者が編集するファイル（Impl, Notifier, Page）は既存時スキップ |

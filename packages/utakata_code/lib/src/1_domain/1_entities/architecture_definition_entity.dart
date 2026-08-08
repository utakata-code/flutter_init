import 'core_module_entity.dart';
import 'guide_entity.dart';

/// アーキテクチャ定義エンティティ
///
/// arch_definition.yaml から読み込まれるアーキテクチャ構造の定義。
/// ハードコードを避け、テンプレート追加時にコード変更が不要になる。
class ArchitectureDefinitionEntity {
  /// アーキテクチャの識別子（例: 'clean_architecture', 'mvvm'）
  final String id;

  /// 表示名（例: 'Clean Architecture (4-layer)'）
  final String displayName;

  /// 層ごとのディレクトリ定義リスト
  final List<LayerDefinitionEntity> layers;

  /// 命名規則リスト（arch_definition.yaml の naming_rules セクション）
  final List<NamingRuleEntity> namingRules;

  /// ガイド定義リスト
  final List<GuideEntity> guides;

  /// 推奨される依存関係のマップ (パッケージ名 -> バージョン指定またはMap)
  final Map<String, dynamic> dependencies;

  /// 推奨される開発時依存関係のマップ (パッケージ名 -> バージョン指定またはMap)
  final Map<String, dynamic> devDependencies;

  /// コアモジュールの追跡定義リスト
  final List<CoreModuleEntity> coreModules;

  /// import 監査規則(`import_rules` セクション。Issue #20)。
  /// 未定義なら null(`utakata imports` は監査せず案内のみ表示する)。
  final ImportRuleSet? importRules;

  const ArchitectureDefinitionEntity({
    required this.id,
    required this.displayName,
    required this.layers,
    this.namingRules = const [],
    this.guides = const [],
    this.dependencies = const {},
    this.devDependencies = const {},
    this.coreModules = const [],
    this.importRules,
  });

  @override
  String toString() =>
      'ArchitectureDefinitionEntity(id: $id, layers: ${layers.length}, '
      'namingRules: ${namingRules.length}, guides: ${guides.length}, '
      'dependencies: ${dependencies.length}, devDependencies: ${devDependencies.length}, '
      'coreModules: ${coreModules.length})';
}

/// 各層のディレクトリ定義エンティティ
class LayerDefinitionEntity {
  /// 層ディレクトリ名（例: '1_domain', '2_infrastructure'）
  final String name;

  /// 層直下に作成するサブディレクトリのリスト
  final List<String> dirs;

  const LayerDefinitionEntity({
    required this.name,
    required this.dirs,
  });
}

/// 命名規則エンティティ
///
/// arch_definition.yaml の naming_rules エントリに対応する。
/// dir_pattern に部分一致するディレクトリ内の .dart ファイルを
/// file_pattern（正規表現）で検証する。
class NamingRuleEntity {
  /// ディレクトリパスの部分一致パターン（例: "1_domain/1_entities"）
  final String dirPattern;

  /// ファイル名に適用する正規表現文字列（例: "^.+_entity\\.dart$"）
  final String filePattern;

  /// エラー表示用の期待パターン説明（例: "{name}_entity.dart"）
  final String description;

  const NamingRuleEntity({
    required this.dirPattern,
    required this.filePattern,
    required this.description,
  });

  /// filePattern をコンパイル済み RegExp として返す
  RegExp get regex => RegExp(filePattern);

  /// 指定されたディレクトリパスに対してこのルールが適用されるか
  bool matches(String dirPath) => dirPath.contains(dirPattern);
}

/// import 監査規則(Issue #20)。
///
/// arch_definition.yaml の `import_rules` セクションに対応する。
/// `utakata imports` が決定論的に検証する。
///
/// **v2 書式**(推奨): [layerGraph](`layers:`)で層間依存の一意なグラフを
/// 宣言し、層既定より絞りたいディレクトリだけ [internalRules](`dirs:`)で
/// 上書きする。外部依存は deny リストではなく `dependencies/*.yaml` の
/// 配置宣言([PackagePlacement])で管理する。
///
/// **v1 書式**(後方互換): `internal:`(フラットなホワイトリスト)+
/// `external:`(deny ブラックリスト)。既存の eject 済みローカル定義を
/// 壊さないため引き続き読める。
final class ImportRuleSet {
  /// 層間依存グラフ(v2 の `layers:`)。キー = 層名、値 = import してよい層名。
  /// 自層は常に許可。[internalRules] に該当しないファイルはこのグラフで判定する。
  final Map<String, List<String>> layerGraph;

  /// ディレクトリ単位の内部依存ホワイトリスト(v2 の `dirs:` / v1 の `internal:`)。
  /// 該当するファイルには層グラフより優先して適用される。
  final List<InternalImportRule> internalRules;

  /// 外部依存の deny ブラックリスト(v1 の `external:`。後方互換)。
  final List<ExternalImportRule> externalRules;

  /// 監査対象外にするファイルパスの glob(例: `**.g.dart`)。
  final List<String> excludePatterns;

  const ImportRuleSet({
    this.layerGraph = const {},
    this.internalRules = const [],
    this.externalRules = const [],
    this.excludePatterns = const [],
  });

  bool get isEmpty =>
      layerGraph.isEmpty && internalRules.isEmpty && externalRules.isEmpty;
}

/// 「この層ディレクトリのファイルは、どの層を import してよいか」の宣言。
///
/// [dirPattern] は [NamingRuleEntity.dirPattern] と同じ流儀の層パス
/// (パスセグメント単位で照合)。自層(同じ [dirPattern] に属するパス)への
/// import は常に許可される。層ディレクトリの外(`core/` や `main.dart` 等、
/// どの層にも属さないパス)への import は監査対象外。
final class InternalImportRule {
  final String dirPattern;

  /// import してよい層パスのリスト(ホワイトリスト)。
  final List<String> allow;

  const InternalImportRule({required this.dirPattern, this.allow = const []});
}

/// 「この層ディレクトリのファイルは、どのパッケージを import してはならないか」の宣言。
///
/// [deny] はパッケージ名の glob(`*` 使用可。例: `flutter`, `*riverpod*`,
/// `firebase_*`, `dart:io`)。同じパスに複数ルールが該当する場合はすべて適用される
/// (層全体の禁止 + サブディレクトリ固有の禁止を重ねられる)。
final class ExternalImportRule {
  final String dirPattern;

  /// import を禁止するパッケージ名 glob のリスト(ブラックリスト)。
  final List<String> deny;

  const ExternalImportRule({required this.dirPattern, this.deny = const []});
}

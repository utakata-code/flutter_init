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

  const ArchitectureDefinitionEntity({
    required this.id,
    required this.displayName,
    required this.layers,
    this.namingRules = const [],
  });

  @override
  String toString() =>
      'ArchitectureDefinitionEntity(id: $id, layers: ${layers.length}, '
      'namingRules: ${namingRules.length})';
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

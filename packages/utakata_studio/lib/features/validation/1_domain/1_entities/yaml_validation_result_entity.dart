import 'package:utakata/utakata.dart';

/// YAML バリデーション結果を保持する不変エンティティ
class YamlValidationResult {
  final String yamlContent;
  final bool isValid;
  final String? errorMessage;
  final List<LayerDefinitionEntity> layers;
  final List<NamingRuleEntity> namingRules;
  final List<CoreModuleEntity> coreModules;
  final List<GuideEntity> guides;

  const YamlValidationResult({
    required this.yamlContent,
    required this.isValid,
    this.errorMessage,
    this.layers = const [],
    this.namingRules = const [],
    this.coreModules = const [],
    this.guides = const [],
  });

  /// レイヤーの総ディレクトリ数
  int get totalDirs =>
      layers.fold<int>(0, (sum, layer) => sum + layer.dirs.length);
}

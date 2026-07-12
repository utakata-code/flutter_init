import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/plan/plan_intent.dart';
import '../1_entities/structure/expected_structure.dart';
import 'name_rule_matcher.dart';

/// [PlanIntent] とアーキテクチャ定義から [ExpectedStructure] を導出する純関数サービス。
///
/// 旧 `PlanArchitectureUsecase._buildFeaturePlan` 相当のロジックを、
/// I/O を含まない形に抽出したもの。1 feature につき複数 entity を
/// 宣言できる(plan.yaml の `entities: [...]`)ため、`{name}` を含む
/// 命名規則は entity ごとに1ファイルを要求する。
abstract final class ExpectedStructureBuilder {
  /// [architecturesById]: feature が参照しうる全アーキテクチャ ID の定義を
  /// 事前に解決したもの(この関数自体は I/O を行わない)。
  static ExpectedStructure build(
    PlanIntent plan,
    Map<String, ArchitectureDefinitionEntity> architecturesById,
  ) {
    final topLevel = <String, ExpectedDir>{};

    for (final feature in plan.features) {
      final archId = feature.architectureId ?? plan.defaultArchitectureId;
      final arch = architecturesById[archId];
      if (arch == null) {
        throw StateError(
          'ExpectedStructureBuilder: architecture "$archId" was not resolved '
          'for feature "${feature.name}". Caller must pre-resolve all '
          'referenced architecture IDs.',
        );
      }

      final featureDir = _buildFeatureDir(feature, arch);

      if (feature.permission == 'direct') {
        topLevel[feature.name] = featureDir;
      } else {
        final existingGroup = topLevel[feature.permission];
        final mergedChildren = <String, ExpectedDir>{
          ...(existingGroup?.children ?? const {}),
          feature.name: featureDir,
        };
        topLevel[feature.permission] =
            ExpectedDir(name: feature.permission, children: mergedChildren);
      }
    }

    return ExpectedStructure(topLevel);
  }

  static ExpectedDir _buildFeatureDir(
    PlanFeatureIntent feature,
    ArchitectureDefinitionEntity arch,
  ) {
    final layerChildren = <String, ExpectedDir>{};
    for (final layer in arch.layers) {
      final children = <String, ExpectedDir>{};
      for (final dir in layer.dirs) {
        _setNestedDir(
          children,
          dir.split('/'),
          layer.name,
          feature,
          arch.namingRules,
        );
      }
      layerChildren[layer.name] = ExpectedDir(name: layer.name, children: children);
    }
    return ExpectedDir(name: feature.name, children: layerChildren);
  }

  /// `dir`(例: `"2_data_sources/1_local"`)をネストした [ExpectedDir] ツリーに変換する。
  /// 途中経路も含めて毎階層 [NameRuleMatcher] で規則解決するため、
  /// 中間ディレクトリにも将来ルールを定義すれば正しく適用される。
  static void _setNestedDir(
    Map<String, ExpectedDir> parent,
    List<String> remainingParts,
    String pathSoFar,
    PlanFeatureIntent feature,
    List<NamingRuleEntity> namingRules,
  ) {
    final segment = remainingParts.first;
    final fullPath = pathSoFar.isEmpty ? segment : '$pathSoFar/$segment';
    final isLeaf = remainingParts.length == 1;
    final rule = NameRuleMatcher.findFor(fullPath, namingRules);
    final requiredFiles = isLeaf ? _resolveFileNames(rule, feature) : <String>{};

    final existing = parent[segment];
    final children = <String, ExpectedDir>{...(existing?.children ?? const {})};
    if (!isLeaf) {
      _setNestedDir(children, remainingParts.sublist(1), fullPath, feature, namingRules);
    }

    parent[segment] = ExpectedDir(
      name: segment,
      children: children,
      requiredFiles: {...(existing?.requiredFiles ?? const {}), ...requiredFiles},
      allowRule: rule,
    );
  }

  /// naming rule の description からファイル名を解決する。
  ///
  /// `{verb}`・`|`・自然言語の「A or B」(例: "{name}_exceptions.dart or
  /// domain_exceptions.dart")のいずれかを含む(命名が複数パターン許容・
  /// 非決定的な)場合は空集合を返す — その場合はディレクトリの allowRule
  /// のみでファイルの妥当性を判定する(「後からの変更に弱い」問題の解消:
  /// フルパス列挙が不要になる)。
  static final RegExp _alternationPattern = RegExp(r'\bor\b');

  static Set<String> _resolveFileNames(
    NamingRuleEntity? rule,
    PlanFeatureIntent feature,
  ) {
    if (rule == null) return const {};
    final description = rule.description;
    if (description.contains('{verb}') ||
        description.contains('|') ||
        _alternationPattern.hasMatch(description)) {
      return const {};
    }
    if (description.contains('{name}')) {
      final entities = feature.entities.isNotEmpty ? feature.entities : [feature.name];
      return entities
          .map((e) => description.replaceAll('{name}', e).replaceAll('{feature}', feature.name))
          .toSet();
    }
    return {description.replaceAll('{feature}', feature.name)};
  }
}

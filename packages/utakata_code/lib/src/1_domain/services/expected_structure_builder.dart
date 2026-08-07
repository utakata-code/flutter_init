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
      layerChildren[layer.name] = ExpectedDir(
        name: layer.name,
        children: children,
        // 層まるごとの不要宣言(例: `4_presentation: []`)に対応する
        required: !feature.isOptedOut(layer.name),
      );
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

    // plan.yaml の `layers` 宣言(Issue #12)。宣言があればそれが優先され、
    // 無ければ従来どおり entities から導出する。
    final optedOut = feature.isOptedOut(fullPath);
    final declaration = feature.declarationFor(fullPath);
    final Set<String> requiredFiles;
    if (optedOut) {
      requiredFiles = const {};
    } else if (declaration != null && declaration.isNotEmpty) {
      // パス区切りを含む項目は不正として無視する(サブディレクトリは layers の
      // キー側で宣言する)。check は requiredFiles を「ディレクトリ直下の
      // ファイル名」として照合するため、通すと apply だけが入れ子を生成して
      // check が永遠に missing 報告する食い違いになる。
      requiredFiles = declaration
          .where((item) => !item.contains('/') && !item.contains(r'\'))
          .map((item) => _fileNameFor(rule, item))
          .toSet();
    } else if (isLeaf) {
      requiredFiles = resolveFileNames(rule, feature);
    } else {
      requiredFiles = const {};
    }

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
      // 空リスト宣言された層(とその配下)は存在しなくてもよい。
      // 既に必須と決まっている場合は必須のまま(同一パスへの複数宣言時の安全側)。
      required: (existing?.required ?? false) || !optedOut,
    );
  }

  /// 項目名(例: `save_purchase_record`)を、その層の命名規則に沿った
  /// ファイル名に変換する。
  ///
  /// 規則の description からプレースホルダ部分を除いた接尾辞を取り出し、
  /// 項目名に連結する:
  ///   `{name}_entity.dart`        + `todo`               → `todo_entity.dart`
  ///   `{verb}_{name}_usecase.dart`+ `save_purchase`      → `save_purchase_usecase.dart`
  ///   `{name}_exceptions.dart or domain_exceptions.dart` → 先頭の候補を採用
  ///
  /// 項目名が `.dart` で終わる場合はファイル名そのものとして扱う(逃げ道)。
  static String _fileNameFor(NamingRuleEntity? rule, String item) {
    if (item.endsWith('.dart')) return item;
    if (rule == null) return '$item.dart';

    // "A or B" / "A|B" は先頭の候補を正とする
    var pattern = rule.description.split(_alternationPattern).first.split('|').first.trim();
    final lastPlaceholder = pattern.lastIndexOf('}');
    if (lastPlaceholder < 0) {
      // プレースホルダを持たない固定名の規則(例: router.dart)はそのまま使う
      return pattern;
    }
    final suffix = pattern.substring(lastPlaceholder + 1);
    return '$item$suffix';
  }

  /// naming rule の description からファイル名を解決する。
  ///
  /// `{verb}`・`|`・自然言語の「A or B」(例: "{name}_exceptions.dart or
  /// domain_exceptions.dart")のいずれかを含む(命名が複数パターン許容・
  /// 非決定的な)場合は空集合を返す — その場合はディレクトリの allowRule
  /// のみでファイルの妥当性を判定する(「後からの変更に弱い」問題の解消:
  /// フルパス列挙が不要になる)。
  ///
  /// `plan expand`(Issue #16)もこの解決を共有し、plan.yaml へ
  /// 拡張子込みの完全ファイル名を書き出す(check/apply と同一の導出)。
  static final RegExp _alternationPattern = RegExp(r'\bor\b');

  static Set<String> resolveFileNames(
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
    final Set<String> names;
    if (description.contains('{name}')) {
      final entities = feature.entities.isNotEmpty ? feature.entities : [feature.name];
      names = entities
          .map((e) => description.replaceAll('{name}', e).replaceAll('{feature}', feature.name))
          .toSet();
    } else {
      names = {description.replaceAll('{feature}', feature.name)};
    }
    // description は本来「エラー表示用の説明」なので、自由記述(prose)の
    // 可能性がある。導出結果が規則自身の file_pattern を満たさない場合は
    // 決定的なファイル名とみなさない(allowRule のみで判定する)。
    return names.where(rule.regex.hasMatch).toSet();
  }
}

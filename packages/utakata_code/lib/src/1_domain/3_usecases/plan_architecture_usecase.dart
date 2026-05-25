import '../1_entities/architecture_definition_entity.dart';
import '../2_repositories/architecture_repository.dart';
import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';

/// feature_request.yaml からアーキテクチャ計画を生成するユースケース
///
/// 入力: AI/specs/feature_request.yaml
/// 出力: AI/specs/plan_architecture.yaml
///
/// アーキテクチャ定義（arch_definition.yaml）の layers + naming_rules から
/// plan を動的に生成する。Clean Architecture / MVVM 等、任意のアーキテクチャに対応。
class PlanArchitectureUsecase {
  final ProjectRepository _projectRepo;
  final ArchitectureRepository _archRepo;
  final CliMessages _msg;

  const PlanArchitectureUsecase({
    required ProjectRepository projectRepo,
    required ArchitectureRepository archRepo,
    required CliMessages msg,
  })  : _projectRepo = projectRepo,
        _archRepo = archRepo,
        _msg = msg;

  /// 計画を生成する
  ///
  /// [projectDir]: プロジェクトルートパス
  Future<Map<String, dynamic>> execute(String projectDir) async {
    final request = await _projectRepo.readFeatureRequest(projectDir);

    final featuresNode = request['features'];
    if (featuresNode is! Map) {
      throw Exception(_msg.planMissingFeaturesKey);
    }

    // プロジェクトデフォルトのアーキテクチャ ID を取得
    final projectNode = request['project'];
    final defaultArchId = (projectNode is Map)
        ? (projectNode['architecture'] as String?) ?? 'clean_architecture'
        : 'clean_architecture';

    final plan = <String, dynamic>{'features': <String, dynamic>{}};

    for (final featureEntry in featuresNode.entries) {
      final featureName = featureEntry.key as String;
      final details = featureEntry.value;

      String entity = featureName;
      String archId = defaultArchId;

      if (details is Map) {
        entity = (details['entity'] as String?) ?? featureName;
        // フィーチャー単位でアーキテクチャをオーバーライド可能
        archId = (details['architecture'] as String?) ?? defaultArchId;
      }

      // アーキテクチャ定義を取得して動的に plan を生成
      final arch = await _archRepo.getById(archId);
      final features = plan['features'] as Map<String, dynamic>;
      features[featureName] = _buildFeaturePlan(arch, featureName, entity);
    }

    // 計画を保存
    await _projectRepo.writePlanArchitecture(projectDir, plan);

    return plan;
  }

  /// アーキテクチャ定義の layers + naming_rules からフィーチャーの plan を動的生成
  Map<String, dynamic> _buildFeaturePlan(
    ArchitectureDefinitionEntity arch,
    String featureName,
    String entityName,
  ) {
    final plan = <String, dynamic>{};

    for (final layer in arch.layers) {
      final layerPlan = <String, dynamic>{};

      for (final dir in layer.dirs) {
        // naming_rules からファイル名テンプレートを検索
        final fullDirPattern = '${layer.name}/$dir';
        final rule = _findMatchingRule(arch.namingRules, fullDirPattern);

        final dirNode = <String, dynamic>{};
        if (rule != null) {
          final fileName = _resolveFileName(rule.description, featureName, entityName);
          if (fileName != null) {
            dirNode['__files__'] = [fileName];
          }
        }

        // ネストパス（例: 2_data_sources/1_local）をツリーに変換
        _setNestedDir(layerPlan, dir, dirNode);
      }

      plan[layer.name] = layerPlan;
    }

    return plan;
  }

  /// naming_rules からマッチするルールを検索
  NamingRuleEntity? _findMatchingRule(
    List<NamingRuleEntity> rules,
    String dirPattern,
  ) {
    for (final rule in rules) {
      if (dirPattern.endsWith(rule.dirPattern)) {
        return rule;
      }
    }
    return null;
  }

  /// description テンプレートからファイル名を生成
  ///
  /// description に {verb} や "|" が含まれる場合はファイル名が確定しないので
  /// null を返す（usecases / exceptions 等）
  String? _resolveFileName(
    String description,
    String featureName,
    String entityName,
  ) {
    // {verb} や "|" があるパターンはファイル名が確定しない
    if (description.contains('{verb}') || description.contains('|')) {
      return null;
    }
    return description
        .replaceAll('{name}', entityName)
        .replaceAll('{feature}', featureName);
  }

  /// ネストパス（例: "2_data_sources/1_local"）を Map ツリーに変換
  void _setNestedDir(
    Map<String, dynamic> parent,
    String path,
    Map<String, dynamic> value,
  ) {
    final parts = path.split('/');
    var current = parent;

    for (var i = 0; i < parts.length - 1; i++) {
      current.putIfAbsent(parts[i], () => <String, dynamic>{});
      final child = current[parts[i]];
      if (child is Map<String, dynamic>) {
        current = child;
      } else {
        // null or non-Map の場合は新しい Map に置き換え
        final newMap = <String, dynamic>{};
        current[parts[i]] = newMap;
        current = newMap;
      }
    }

    final leafKey = parts.last;
    final existing = current[leafKey];
    if (existing is Map<String, dynamic>) {
      existing.addAll(value);
    } else {
      current[leafKey] = value;
    }
  }
}

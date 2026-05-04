import '../1_entities/feature_spec_entity.dart';
import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';
import 'add_feature_usecase.dart';

/// plan_architecture.yaml に定義された全フィーチャーを一括生成するユースケース
class InitFeaturesUsecase {
  final ProjectRepository _projectRepo;
  final AddFeatureUsecase _addFeatureUsecase;
  final CliMessages _msg;

  const InitFeaturesUsecase({
    required ProjectRepository projectRepo,
    required AddFeatureUsecase addFeatureUsecase,
    required CliMessages msg,
  })  : _projectRepo = projectRepo,
        _addFeatureUsecase = addFeatureUsecase,
        _msg = msg;

  /// 全フィーチャーを一括生成する
  ///
  /// [projectDir]: プロジェクトルートパス
  /// [dryRun]: true の場合はファイルを生成せず対象のみ返す
  Future<List<FeatureSpecEntity>> execute(
    String projectDir, {
    bool dryRun = false,
  }) async {
    final plan = await _projectRepo.readPlanArchitecture(projectDir);
    if (plan == null) {
      throw Exception(_msg.planNotFound('AI/specs/plan_architecture.yaml'));
    }

    final tasks = <FeatureSpecEntity>[];
    final featuresNode = plan['features'];
    if (featuresNode is! Map) return tasks;

    // features.{perm}.{feature_name} を走査
    for (final permEntry in featuresNode.entries) {
      final perm = permEntry.key as String;
      final permNode = permEntry.value;
      if (permNode is! Map) continue;

      for (final featureEntry in permNode.entries) {
        final featureName = featureEntry.key as String;
        final entityName = _detectEntityName(featureName, featureEntry.value);
        tasks.add(FeatureSpecEntity(
          featureName: featureName,
          entityName: entityName,
          permission: perm,
        ));
      }
    }

    if (!dryRun) {
      for (final spec in tasks) {
        await _addFeatureUsecase.execute(projectDir, spec);
      }
    }

    return tasks;
  }

  /// plan_architecture.yaml のフィーチャーノードから entity 名を推定する
  String _detectEntityName(String featureName, dynamic featureNode) {
    try {
      if (featureNode is Map) {
        final domain = featureNode['1_domain'];
        if (domain is Map) {
          final entities = domain['1_entities'];
          if (entities is Map) {
            final files = entities['__files__'];
            if (files is List && files.isNotEmpty) {
              final fileName = files.first as String;
              return fileName.replaceAll('_entity.dart', '');
            }
          }
        }
      }
    } catch (_) {}
    return featureName;
  }
}

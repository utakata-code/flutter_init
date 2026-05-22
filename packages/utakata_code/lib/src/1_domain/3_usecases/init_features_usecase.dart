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

    // feature_request.yaml から permission を取得
    Map<String, dynamic>? featureRequest;
    try {
      featureRequest = await _projectRepo.readFeatureRequest(projectDir);
    } catch (_) {
      // feature_request.yaml がない場合は permission = 'direct' をデフォルトに
    }

    final tasks = <FeatureSpecEntity>[];
    final featuresNode = plan['features'];
    if (featuresNode is! Map) return tasks;

    // フラット形式: features.{feature_name} を走査
    for (final featureEntry in featuresNode.entries) {
      final featureName = featureEntry.key as String;
      final featureNode = featureEntry.value;

      // feature_request.yaml から permission と architecture を取得
      String perm = 'direct';
      String archId = 'clean_architecture';
      if (featureRequest != null) {
        // プロジェクトデフォルトの architecture
        final projectNode = featureRequest['project'];
        if (projectNode is Map) {
          archId = (projectNode['architecture'] as String?) ?? archId;
        }

        final reqFeatures = featureRequest['features'];
        if (reqFeatures is Map && reqFeatures.containsKey(featureName)) {
          final reqDetails = reqFeatures[featureName];
          if (reqDetails is Map) {
            perm = (reqDetails['permission'] as String?) ?? 'direct';
            // フィーチャー単位でオーバーライド
            archId = (reqDetails['architecture'] as String?) ?? archId;
          }
        }
      }

      final entityName = _detectEntityName(featureName, featureNode);
      tasks.add(FeatureSpecEntity(
        featureName: featureName,
        entityName: entityName,
        permission: perm,
        architectureId: archId,
      ));
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

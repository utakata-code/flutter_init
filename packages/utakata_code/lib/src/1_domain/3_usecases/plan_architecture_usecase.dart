import '../2_repositories/project_repository.dart';
import '../messages/cli_messages.dart';

/// feature_request.yaml からアーキテクチャ計画を生成するユースケース
///
/// 入力: AI/specs/feature_request.yaml
/// 出力: AI/specs/plan_architecture.yaml + plan_architecture.md
class PlanArchitectureUsecase {
  final ProjectRepository _projectRepo;
  final CliMessages _msg;

  const PlanArchitectureUsecase({
    required ProjectRepository projectRepo,
    required CliMessages msg,
  })  : _projectRepo = projectRepo,
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

    final plan = <String, dynamic>{'features': <String, dynamic>{}};

    for (final featureEntry in featuresNode.entries) {
      final featureName = featureEntry.key as String;
      final details = featureEntry.value;

      String entity = featureName;

      if (details is Map) {
        entity = (details['entity'] as String?) ?? featureName;
      }

      // フラット形式: features.{featureName} に直接配置
      final features = plan['features'] as Map<String, dynamic>;
      features[featureName] = _buildFeaturePlan(featureName, entity);
    }

    // 計画を保存
    await _projectRepo.writePlanArchitecture(projectDir, plan);

    return plan;
  }

  /// フィーチャーの計画構造を生成する（Clean Architecture 4層）
  Map<String, dynamic> _buildFeaturePlan(String featureName, String entityName) {
    return {
      '1_domain': {
        '1_entities': {'__files__': ['${entityName}_entity.dart']},
        '2_repositories': {'__files__': ['${entityName}_repository.dart']},
        '3_usecases': <String, dynamic>{},
        'exceptions': <String, dynamic>{},
      },
      '2_infrastructure': {
        '1_models': {'__files__': ['${entityName}_model.dart']},
        '2_data_sources': {
          '1_local': {
            '__files__': ['${entityName}_local_data_source.dart'],
            'exceptions': <String, dynamic>{},
          },
          '2_remote': {'exceptions': <String, dynamic>{}},
        },
        '3_repositories': {'__files__': ['${entityName}_repository_impl.dart']},
      },
      '3_application': {
        '1_states': {'__files__': ['${featureName}_state.dart']},
        '2_providers': {'__files__': ['${featureName}_providers.dart']},
        '3_notifiers': {'__files__': ['${featureName}_notifier.dart']},
      },
      '4_presentation': {
        '1_widgets': {
          '1_atoms': <String, dynamic>{},
          '2_molecules': <String, dynamic>{},
          '3_organisms': <String, dynamic>{},
        },
        '2_pages': {'__files__': ['${featureName}_page.dart']},
      },
    };
  }
}

import '../1_entities/feature_spec_entity.dart';
import '../2_repositories/plan_repository.dart';
import 'add_feature_usecase.dart';
import 'generate_core_usecase.dart';

/// `utakata apply` — plan.yaml から未生成の feature/core を作成するユースケース。
///
/// 旧 `feature init`(InitFeaturesUsecase)+ `core`(GenerateCoreUsecase)を
/// 統合する。check と同じ「plan.yaml の意図」を入力にするため、
/// 生成すべき内容が check の期待値と食い違うことがなくなる
/// (旧 `feature init` が plan_architecture.yaml の `__files__` を無視する
/// バグのクラスを構造的に解消する)。
class ApplyUsecase {
  final PlanRepository _planRepo;
  final AddFeatureUsecase _addFeatureUsecase;
  final GenerateCoreUsecase _generateCoreUsecase;

  const ApplyUsecase({
    required PlanRepository planRepo,
    required AddFeatureUsecase addFeatureUsecase,
    required GenerateCoreUsecase generateCoreUsecase,
  })  : _planRepo = planRepo,
        _addFeatureUsecase = addFeatureUsecase,
        _generateCoreUsecase = generateCoreUsecase;

  /// [scope]: 'all' | 'feature' | 'core'
  Future<ApplyResult> execute(
    String projectDir, {
    String scope = 'all',
    bool dryRun = false,
  }) async {
    final plan = await _planRepo.read(projectDir);

    final features = <FeatureSpecEntity>[];
    if ((scope == 'all' || scope == 'feature') && plan != null) {
      for (final feature in plan.features) {
        final spec = FeatureSpecEntity(
          featureName: feature.name,
          entityName: feature.entities.isNotEmpty ? feature.entities.first : feature.name,
          permission: feature.permission,
          architectureId: feature.architectureId ?? plan.defaultArchitectureId,
        );
        features.add(spec);
        if (!dryRun) {
          await _addFeatureUsecase.execute(projectDir, spec);
        }
      }
    }

    var coreModulePaths = const <String>[];
    if ((scope == 'all' || scope == 'core') && plan != null && !dryRun) {
      coreModulePaths =
          await _generateCoreUsecase.execute(projectDir, plan.defaultArchitectureId);
    }

    return ApplyResult(features: features, coreModulePaths: coreModulePaths);
  }
}

class ApplyResult {
  final List<FeatureSpecEntity> features;
  final List<String> coreModulePaths;

  const ApplyResult({required this.features, required this.coreModulePaths});
}

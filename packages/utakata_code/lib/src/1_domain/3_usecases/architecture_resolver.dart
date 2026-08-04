import '../2_repositories/config_repository.dart';
import '../2_repositories/plan_repository.dart';

/// プロジェクトで使うアーキテクチャ ID の解決を一元化する(Issue #11)。
///
/// 解決順:
///   1. 明示指定(`--arch` / MCP の `architecture_id`)
///   2. `utakata.yaml` の `project.architecture`(マスター設定)
///   3. `doc/specs/plan.yaml` の `project.architecture`
///   4. 既定値 `clean_architecture`
///
/// この順序を各コマンドが個別に実装すると取りこぼしが起きる(実際に
/// guide list/show/eject と MCP guide_get が静的既定値のまま残っていた)ため、
/// 解決が必要な箇所は必ずこのサービスを経由する。
class ArchitectureResolver {
  static const fallbackArchitectureId = 'clean_architecture';

  final ConfigRepository _configRepo;
  final PlanRepository? _planRepo;

  const ArchitectureResolver({
    required ConfigRepository configRepo,
    PlanRepository? planRepo,
  })  : _configRepo = configRepo,
        _planRepo = planRepo;

  /// [explicit] が非 null かつ空でなければそれを返す(明示指定が最優先)。
  Future<String> resolve(String projectDir, {String? explicit}) async {
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromConfig = (await _configRepo.read(projectDir))?.architecture;
    if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;

    final fromPlan = (await _planRepo?.read(projectDir))?.defaultArchitectureId;
    if (fromPlan != null && fromPlan.isNotEmpty) return fromPlan;

    return fallbackArchitectureId;
  }
}

import '../1_entities/plan/plan_intent.dart';
import '../1_entities/structure/structure_node.dart';
import '../2_repositories/plan_repository.dart';
import '../2_repositories/structure_repository.dart';

/// `utakata plan adopt` — スキャンで見つかった未計画 feature を検出し、
/// 確認のうえ plan.yaml へ意図レベルで追記するユースケース。
///
/// 自動書き込みはしない片方向の設計(仕様書 §6): fs → plan は
/// 「明示的採択」のみで、plan → fs は [ApplyUsecase] のみが担う。
class AdoptPlanUsecase {
  final PlanRepository _planRepo;
  final StructureRepository _structureRepo;

  const AdoptPlanUsecase({
    required PlanRepository planRepo,
    required StructureRepository structureRepo,
  })  : _planRepo = planRepo,
        _structureRepo = structureRepo;

  /// 未計画の feature 候補を検出する(書き込みは行わない)。
  Future<List<PlanFeatureIntent>> detect(String projectDir) async {
    final plan = await _planRepo.read(projectDir);
    final planned = <String>{
      for (final f in (plan?.features ?? const <PlanFeatureIntent>[]))
        _key(f.permission, f.name),
    };

    final snapshot = await _structureRepo.scan(projectDir);
    final candidates = <PlanFeatureIntent>[];

    for (final entry in snapshot.root.children.entries) {
      final name = entry.key;
      final node = entry.value;
      if (node is! StructureDirNode) continue;

      // 権限フォルダ(admin/user/shared)の場合はその下の feature を、
      // それ以外は direct feature として扱う。
      if (const ['admin', 'user', 'shared'].contains(name)) {
        for (final featureEntry in node.children.entries) {
          if (featureEntry.value is! StructureDirNode) continue;
          final featureName = featureEntry.key;
          if (planned.contains(_key(name, featureName))) continue;
          candidates.add(PlanFeatureIntent(name: featureName, permission: name));
        }
      } else {
        if (planned.contains(_key('direct', name))) continue;
        candidates.add(PlanFeatureIntent(name: name, permission: 'direct'));
      }
    }

    return candidates;
  }

  /// 検出済みの feature を plan.yaml へ確認後に追記する。
  Future<void> adopt(String projectDir, PlanFeatureIntent feature) async {
    await _planRepo.adoptFeature(projectDir, feature);
  }

  String _key(String permission, String name) => '$permission/$name';
}

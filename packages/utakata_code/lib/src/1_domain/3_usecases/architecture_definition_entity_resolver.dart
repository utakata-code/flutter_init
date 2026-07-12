import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/plan/plan_intent.dart';
import '../2_repositories/architecture_repository.dart';

/// [PlanIntent] が参照する全アーキテクチャ ID を解決し、
/// [ExpectedStructureBuilder](純関数)に渡せる形にまとめる。
///
/// I/O(リポジトリ呼び出し)はここに閉じ込め、ビルダー自体は
/// 純関数のまま保つ。
Future<Map<String, ArchitectureDefinitionEntity>> resolveArchitectures(
  PlanIntent plan,
  ArchitectureRepository archRepo,
) async {
  final ids = <String>{
    plan.defaultArchitectureId,
    for (final feature in plan.features)
      feature.architectureId ?? plan.defaultArchitectureId,
  };

  final result = <String, ArchitectureDefinitionEntity>{};
  for (final id in ids) {
    result[id] = await archRepo.getById(id);
  }
  return result;
}

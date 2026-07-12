import '../1_entities/structure/check_report.dart';
import '../2_repositories/architecture_repository.dart';
import '../2_repositories/plan_repository.dart';
import '../2_repositories/structure_repository.dart';
import '../messages/cli_messages.dart';
import '../services/expected_structure_builder.dart';
import '../services/structure_checker.dart';
import 'architecture_definition_entity_resolver.dart';

/// `utakata check` — 構造差分 + 命名規則違反を1回の走査で検出するユースケース。
///
/// 旧 `DiffArchitectureUsecase`(構造差分)と `ValidateUsecase`(命名検証)を
/// 正準構造モデル(仕様書 §5)の上に統合する。
class CheckUsecase {
  final PlanRepository _planRepo;
  final ArchitectureRepository _archRepo;
  final StructureRepository _structureRepo;
  final CliMessages _msg;

  const CheckUsecase({
    required PlanRepository planRepo,
    required ArchitectureRepository archRepo,
    required StructureRepository structureRepo,
    required CliMessages msg,
  })  : _planRepo = planRepo,
        _archRepo = archRepo,
        _structureRepo = structureRepo,
        _msg = msg;

  Future<CheckReport> execute(String projectDir) async {
    final plan = await _planRepo.read(projectDir);
    if (plan == null) {
      throw Exception(_msg.planNotFound('doc/specs/plan.yaml'));
    }

    final architecturesById = await resolveArchitectures(plan, _archRepo);
    final expected = ExpectedStructureBuilder.build(plan, architecturesById);
    final snapshot = await _structureRepo.scan(projectDir);

    return StructureChecker.check(expected, snapshot);
  }
}

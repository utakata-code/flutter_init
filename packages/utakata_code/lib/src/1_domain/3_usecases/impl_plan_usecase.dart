import '../1_entities/record/impl_plan_meta.dart';
import '../2_repositories/impl_plan_repository.dart';

/// `utakata impl new/list/done/archive` — feature 実装計画のライフサイクル管理
/// (仕様書 §8)。
class ImplPlanUsecase {
  final ImplPlanRepository _repo;

  const ImplPlanUsecase({required ImplPlanRepository repo}) : _repo = repo;

  Future<String> create(
    String projectDir, {
    required String feature,
    String backlog = '',
    List<String> agreements = const [],
    List<String> specs = const [],
    List<String> messages = const [],
    ImplPlanBasis? basis,
    required DateTime now,
    required String bodyTemplate,
  }) async {
    final id = await _repo.nextId(projectDir);
    final meta = ImplPlanMeta(
      id: id,
      feature: feature,
      backlog: backlog,
      status: ImplPlanStatus.draft,
      created: now,
      origin: ImplPlanOrigin(agreements: agreements, specs: specs, messages: messages),
      basis: basis,
    );
    await _repo.create(projectDir, meta, bodyTemplate);
    return id;
  }

  Future<List<ImplPlanMeta>> list(String projectDir) => _repo.listAll(projectDir);

  Future<void> markInProgress(String projectDir, String id) =>
      _repo.updateStatus(projectDir, id, ImplPlanStatus.inProgress);

  Future<void> markDone(String projectDir, String id, {required DateTime now}) =>
      _repo.updateStatus(projectDir, id, ImplPlanStatus.done, completedOn: now);

  Future<void> archive(String projectDir, String id) async {
    await _repo.updateStatus(projectDir, id, ImplPlanStatus.archived);
    await _repo.archive(projectDir, id);
  }
}

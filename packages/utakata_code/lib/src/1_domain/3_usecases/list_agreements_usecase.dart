import '../1_entities/record/agreement.dart';
import '../2_repositories/agreement_repository.dart';

class ListAgreementsUsecase {
  final AgreementRepository _repo;

  const ListAgreementsUsecase({required AgreementRepository repo}) : _repo = repo;

  Future<List<Agreement>> execute(String projectDir, {bool unreflectedOnly = false}) async {
    final all = await _repo.listAll(projectDir);
    if (!unreflectedOnly) return all;
    return all.where((a) => !a.isReflected).toList();
  }
}

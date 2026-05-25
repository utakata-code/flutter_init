import '../1_entities/architecture_definition_entity.dart';
import '../2_repositories/architecture_repository.dart';

/// 利用可能なアーキテクチャ定義の一覧を取得するユースケース
class ListArchitecturesUsecase {
  final ArchitectureRepository _archRepo;

  const ListArchitecturesUsecase({
    required ArchitectureRepository archRepo,
  }) : _archRepo = archRepo;

  /// アーキテクチャ定義の一覧を取得する
  Future<List<ArchitectureDefinitionEntity>> execute() async {
    return _archRepo.getAll();
  }
}

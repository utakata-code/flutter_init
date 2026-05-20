import '../1_entities/architecture_definition_entity.dart';
import '../2_repositories/architecture_repository.dart';

/// 指定されたIDのアーキテクチャ定義を取得するユースケース
class ShowArchitectureUsecase {
  final ArchitectureRepository _archRepo;

  const ShowArchitectureUsecase({
    required ArchitectureRepository archRepo,
  }) : _archRepo = archRepo;

  /// 指定した ID のアーキテクチャ定義を取得する
  Future<ArchitectureDefinitionEntity> execute(String architectureId) async {
    return _archRepo.getById(architectureId);
  }
}

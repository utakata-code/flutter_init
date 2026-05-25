import '../../1_domain/2_repositories/arch_definition_repository.dart';
import '../2_data_sources/1_local/arch_definition_local_data_source.dart';

/// アーキテクチャ定義リポジトリの実装
class ArchDefinitionRepositoryImpl implements ArchDefinitionRepository {
  final ArchDefinitionLocalDataSource _localDataSource;
  const ArchDefinitionRepositoryImpl(this._localDataSource);

  @override
  Future<String> readArchDefinitionYaml(String projectRoot) =>
      _localDataSource.readYaml(projectRoot);
}

import '../2_repositories/arch_definition_repository.dart';
import '../../../validation/1_domain/1_entities/validation_result_entity.dart';
import '../../../validation/1_domain/3_usecases/validate_yaml_usecase.dart';

/// arch_definition.yaml をロード → バリデーションするユースケース
///
/// プロジェクトルートを受け取り、
/// YAML 読み込み → パース → バリデーション結果を返す。
class LoadArchDefinitionUsecase {
  final ArchDefinitionRepository _repository;
  final ValidateYamlUsecase _validateUsecase;

  const LoadArchDefinitionUsecase(this._repository, this._validateUsecase);

  /// arch_definition.yaml をロードしてバリデーション結果を返す
  ///
  /// [projectRoot] プロジェクトルートパス
  ///
  /// Throws:
  /// - [FileSystemException] YAML ファイルが見つからない場合
  Future<ValidationResultEntity> call(String projectRoot) async {
    final yaml = await _repository.readArchDefinitionYaml(projectRoot);
    return _validateUsecase(yaml);
  }
}

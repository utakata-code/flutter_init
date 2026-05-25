import '../1_entities/validation_result_entity.dart';
import '../2_repositories/yaml_parser_repository.dart';

/// YAML バリデーションのユースケース
///
/// YAML 文字列を受け取り、パースしてバリデーション結果を返す。
/// パース処理自体は [YamlParserRepository] に委譲する（ドメイン層は外部ライブラリに依存しない）。
class ValidateYamlUsecase {
  final YamlParserRepository _parserRepository;

  const ValidateYamlUsecase(this._parserRepository);

  /// YAML 文字列をバリデーションする
  ///
  /// [yamlStr] バリデーション対象の YAML 文字列
  ///
  /// Returns: バリデーション結果
  ValidationResultEntity call(String yamlStr) {
    if (yamlStr.trim().isEmpty) {
      return const ValidationResultEntity(
        yamlContent: '',
        isValid: false,
        errorMessage: 'YAML が空です。',
      );
    }
    return _parserRepository.parse(yamlStr);
  }
}

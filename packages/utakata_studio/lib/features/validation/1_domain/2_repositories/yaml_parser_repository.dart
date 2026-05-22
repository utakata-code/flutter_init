import '../1_entities/validation_result_entity.dart';

/// YAML バリデーション結果を返すリポジトリインターフェース
///
/// YAML 文字列のパースは Infrastructure 層で実装する。
abstract interface class YamlParserRepository {
  /// YAML 文字列をパースしてバリデーション結果を返す
  ///
  /// [yamlStr] パース対象の YAML 文字列
  ValidationResultEntity parse(String yamlStr);
}

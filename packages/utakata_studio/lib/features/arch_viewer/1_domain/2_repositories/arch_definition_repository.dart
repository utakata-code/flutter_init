/// アーキテクチャ定義リポジトリのインターフェース
///
/// arch_definition.yaml の読み込みを抽象化する。
/// 具体的なファイルアクセスは Infrastructure 層で実装する。
abstract interface class ArchDefinitionRepository {
  /// YAML ファイルを読み込んで文字列として返す
  ///
  /// [projectRoot] プロジェクトルートパス
  ///
  /// Throws:
  /// - [FileSystemException] ファイルが見つからない場合
  Future<String> readArchDefinitionYaml(String projectRoot);
}

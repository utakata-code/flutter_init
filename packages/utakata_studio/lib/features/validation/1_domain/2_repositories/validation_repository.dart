/// バリデーションリポジトリのインターフェース
///
/// YAML ファイルの読み込みと変更監視を抽象化する。
abstract interface class ValidationRepository {
  /// YAML ファイルを読み込んで文字列として返す
  ///
  /// [filePath] 読み込むファイルパス
  ///
  /// Throws:
  /// - [FileSystemException] ファイルが見つからない場合
  Future<String> readYamlFile(String filePath);

  /// ファイルの変更を監視するストリームを返す
  ///
  /// [filePath] 監視するファイルパス
  Stream<void> watchFile(String filePath);
}

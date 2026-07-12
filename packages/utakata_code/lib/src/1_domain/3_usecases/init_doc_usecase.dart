/// `utakata doc init` — Flutter プロジェクト作成前に `doc/` ワークスペースを
/// 先行作成するユースケース(契約前フェーズの一級市民化。仕様書 §4)。
class InitDocUsecase {
  final Future<void> Function(String path) _ensureDir;
  final Future<void> Function(String path, String content) _writeFile;
  final bool Function(String path) _fileExists;

  const InitDocUsecase({
    required Future<void> Function(String path) ensureDir,
    required Future<void> Function(String path, String content) writeFile,
    required bool Function(String path) fileExists,
  })  : _ensureDir = ensureDir,
        _writeFile = writeFile,
        _fileExists = fileExists;

  /// 既に存在していれば false、新規作成したら true を返す。
  Future<bool> execute(String projectDir) async {
    final utakataYamlPath = '$projectDir/utakata.yaml';
    if (_fileExists(utakataYamlPath)) {
      return false;
    }

    for (final dir in [
      '$projectDir/doc/specs',
      '$projectDir/doc/records/log',
      '$projectDir/doc/preview',
      '$projectDir/doc/impl/archive',
      '$projectDir/doc/knowledge',
      '$projectDir/doc/archive',
    ]) {
      await _ensureDir(dir);
    }

    await _writeFile(utakataYamlPath, _defaultUtakataYaml());
    await _writeFile('$projectDir/doc/summary.md', _defaultSummaryMd());

    return true;
  }

  String _defaultUtakataYaml() => '''
# utakata プロジェクト設定
project:
  architecture: clean_architecture
enforcement:
  impl_plan: "on"
records:
  git: commit
lang: ja
''';

  String _defaultSummaryMd() => '''
# 案件整理サマリー

<!-- utakata:begin agreements -->
<!-- utakata:end -->
''';
}

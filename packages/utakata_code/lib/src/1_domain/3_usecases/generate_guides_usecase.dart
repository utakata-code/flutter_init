import 'package:path/path.dart' as p;

import '../1_entities/architecture_definition_entity.dart';

/// 各レイヤーのガイドを動的生成するユースケース
class GenerateGuidesUsecase {
  final Future<String?> Function(String path) _readFile;
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;
  final Future<String> Function(String relativePath) _resolvePackageTemplatePath;

  const GenerateGuidesUsecase({
    required Future<String?> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    required Future<String> Function(String relativePath) resolvePackageTemplatePath,
  })  : _readFile = readFile,
        _writeFile = writeFile,
        _ensureDir = ensureDir,
        _resolvePackageTemplatePath = resolvePackageTemplatePath;

  /// ガイド群を生成して指定レイヤー配下に配置する
  Future<void> execute({
    required String projectDir,
    required String featureRelativePath,
    required ArchitectureDefinitionEntity archDefinition,
  }) async {
    for (final guide in archDefinition.guides) {
      // 1. 詳細説明アセットの読み込み (ローカル優先、なければパッケージテンプレートから)
      String? detailContent;

      // guide.detailContentPath から "architectures/{architectureId}/" 部分を除去してローカルパスを計算
      final prefix = 'architectures/${archDefinition.id}/';
      String localRelativePath = guide.detailContentPath;
      if (localRelativePath.startsWith(prefix)) {
        localRelativePath = localRelativePath.substring(prefix.length);
      }

      final localAssetPath = p.join(projectDir, localRelativePath);
      detailContent = await _readFile(localAssetPath);

      if (detailContent == null) {
        // ローカルに存在しない場合はパッケージ同梱アセットから解決
        final packageAssetPath = await _resolvePackageTemplatePath(guide.detailContentPath);
        detailContent = await _readFile(packageAssetPath);
      }

      // 2. メタデータと詳細説明をマージして Markdown レンダリング
      final renderedMarkdown = guide.render(detailContent);

      // 3. 出力先ディレクトリを確保し、ファイルを書き出す
      final targetFilePath = p.join(
        projectDir,
        featureRelativePath,
        guide.layerPath,
        'GUIDE.md',
      );

      await _ensureDir(p.dirname(targetFilePath));
      await _writeFile(targetFilePath, renderedMarkdown);
    }
  }
}


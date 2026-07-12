import 'package:path/path.dart' as p;

import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/guide_entity.dart';
import '../2_repositories/architecture_repository.dart';

/// `utakata guide list/show/eject` — 参照型ナレッジ(GUIDE 等)の閲覧・
/// ローカルへの書き出し(仕様書 §9)。
///
/// 「配布しない=参照化」が最良の保護であるという方針に基づき、
/// eject は元 id・version を先頭コメントに残す単純コピーに留める
/// (hash 照合・manifest 台帳は作らない。棚上げリスト参照)。
class GuideUsecase {
  final ArchitectureRepository _archRepo;
  final Future<String?> Function(String path) _readFile;
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;
  final Future<String> Function(String relativePath) _resolvePackageTemplatePath;

  const GuideUsecase({
    required ArchitectureRepository archRepo,
    required Future<String?> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
    required Future<String> Function(String relativePath) resolvePackageTemplatePath,
  })  : _archRepo = archRepo,
        _readFile = readFile,
        _writeFile = writeFile,
        _ensureDir = ensureDir,
        _resolvePackageTemplatePath = resolvePackageTemplatePath;

  Future<List<GuideEntity>> list(String architectureId) async {
    final arch = await _archRepo.getById(architectureId);
    return arch.guides;
  }

  Future<String> show(String architectureId, String layerPath) async {
    final arch = await _archRepo.getById(architectureId);
    final guide = arch.guides.firstWhere(
      (g) => g.layerPath == layerPath,
      orElse: () => throw StateError('Guide "$layerPath" not found in "$architectureId"'),
    );
    final detail = await _resolveDetail(arch, guide);
    return guide.render(detail);
  }

  /// [outputDir] 配下(既定 doc/knowledge/)へ書き出す。
  Future<String> eject(
    String projectDir,
    String architectureId,
    String layerPath, {
    String outputDir = 'doc/knowledge',
  }) async {
    final arch = await _archRepo.getById(architectureId);
    final guide = arch.guides.firstWhere(
      (g) => g.layerPath == layerPath,
      orElse: () => throw StateError('Guide "$layerPath" not found in "$architectureId"'),
    );
    final detail = await _resolveDetail(arch, guide);
    final rendered = guide.render(detail);

    final slug = layerPath.replaceAll('/', '_');
    final targetPath = p.join(projectDir, outputDir, '$slug.md');
    final header = '<!-- utakata:ejected from=$architectureId/$layerPath -->\n';
    await _ensureDir(p.dirname(targetPath));
    await _writeFile(targetPath, header + rendered);
    return targetPath;
  }

  Future<String?> _resolveDetail(ArchitectureDefinitionEntity arch, GuideEntity guide) async {
    final prefix = 'architectures/${arch.id}/';
    var localRelativePath = guide.detailContentPath;
    if (localRelativePath.startsWith(prefix)) {
      localRelativePath = localRelativePath.substring(prefix.length);
    }
    final localContent = await _readFile(localRelativePath);
    if (localContent != null) return localContent;

    final packageAssetPath = await _resolvePackageTemplatePath(guide.detailContentPath);
    return _readFile(packageAssetPath);
  }
}

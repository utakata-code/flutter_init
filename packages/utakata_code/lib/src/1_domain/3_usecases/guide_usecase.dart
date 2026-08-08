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
    return guide.render(detail,
        importConstraints: await _constraintsFor(arch, layerPath));
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
    final rendered = guide.render(detail,
        importConstraints: await _constraintsFor(arch, layerPath));

    final slug = layerPath.replaceAll('/', '_');
    final targetPath = p.join(projectDir, outputDir, '$slug.md');
    final header = '<!-- utakata:ejected from=$architectureId/$layerPath -->\n';
    await _ensureDir(p.dirname(targetPath));
    await _writeFile(targetPath, header + rendered);
    return targetPath;
  }

  /// `import_rules`/配置宣言から、その層の依存制約 Markdown を生成する。
  /// どちらの情報も無ければ null(手書きの allowed/forbidden 表示に委ねる)。
  Future<String?> _constraintsFor(
    ArchitectureDefinitionEntity arch,
    String layerPath,
  ) async {
    final rules = arch.importRules;
    if (rules == null || rules.isEmpty) return null;

    final buffer = StringBuffer();

    // 内部依存: dirs 細則(最長一致)が正。無ければ層グラフ
    final segments =
        layerPath.split('/').where((s) => s.isNotEmpty).toList();
    InternalImportRule? dirRule;
    var best = -1;
    for (final rule in rules.internalRules) {
      final pattern =
          rule.dirPattern.split('/').where((s) => s.isNotEmpty).toList();
      if (pattern.length > segments.length || pattern.length <= best) continue;
      var matched = false;
      for (var start = 0; start <= segments.length - pattern.length; start++) {
        matched = true;
        for (var i = 0; i < pattern.length; i++) {
          if (segments[start + i] != pattern[i]) {
            matched = false;
            break;
          }
        }
        if (matched) break;
      }
      if (matched) {
        dirRule = rule;
        best = pattern.length;
      }
    }

    buffer.writeln('### import してよい内部依存(`utakata imports` が検証)');
    if (dirRule != null) {
      final allow = ['自層(${dirRule.dirPattern})', ...dirRule.allow];
      for (final entry in allow) {
        buffer.writeln('- $entry');
      }
    } else if (segments.isNotEmpty &&
        rules.layerGraph.containsKey(segments.first)) {
      final layer = segments.first;
      final allowed = rules.layerGraph[layer]!;
      buffer.writeln('- 自層($layer)');
      for (final entry in allowed) {
        buffer.writeln('- $entry');
      }
    } else {
      buffer.writeln('- (この層への個別規則なし)');
    }

    // 外部依存: 配置宣言からこの層で使えるパッケージを列挙
    final placements =
        (await _archRepo.getDependencyStack(arch.id)).placements;
    final usable = <String>[];
    for (final placement in placements) {
      final layers = placement.layers;
      if (layers == null) continue;
      final applies = layers.any((pattern) {
        final patternSegments =
            pattern.split('/').where((s) => s.isNotEmpty).toList();
        if (patternSegments.isEmpty || patternSegments.length > segments.length) {
          return false;
        }
        for (var start = 0;
            start <= segments.length - patternSegments.length;
            start++) {
          var matched = true;
          for (var i = 0; i < patternSegments.length; i++) {
            if (segments[start + i] != patternSegments[i]) {
              matched = false;
              break;
            }
          }
          if (matched) return true;
        }
        return false;
      });
      if (applies) usable.add(placement.package);
    }
    if (placements.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### この層での使用が宣言されている外部パッケージ');
      if (usable.isEmpty) {
        buffer.writeln('- (なし)');
      } else {
        for (final pkg in usable..sort()) {
          buffer.writeln('- $pkg');
        }
      }
      buffer.writeln();
      buffer.writeln('※ 配置制約の無いパッケージ(`layers` 未指定)と'
          '宣言外のパッケージは制限されません。');
    }

    return buffer.toString();
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

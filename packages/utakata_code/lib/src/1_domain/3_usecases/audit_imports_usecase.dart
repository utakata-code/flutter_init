import 'package:path/path.dart' as p;

import '../1_entities/architecture_definition_entity.dart';
import '../1_entities/imports/import_audit_report.dart';
import '../2_repositories/architecture_repository.dart';
import '../services/import_auditor.dart';
import 'architecture_resolver.dart';

/// `utakata imports` — lib/ 配下の import 健全性を決定論的に監査する
/// ユースケース(Issue #20)。
///
/// アーキテクチャ定義の `import_rules`(内部依存ホワイトリスト +
/// 外部依存ブラックリスト)に照らして、全 Dart ファイルの import/export
/// ディレクティブを検証する。規則が未定義のアーキテクチャでは監査せず、
/// [AuditImportsResult.hasRules] = false を返す。
class AuditImportsUsecase {
  final ArchitectureResolver _archResolver;
  final ArchitectureRepository _archRepo;

  /// [dirPath] 配下の [suffix] で終わるファイルを再帰列挙する(dirPath 相対)。
  final List<String> Function(String dirPath, String suffix) _listFilesWithSuffix;
  final Future<String?> Function(String path) _readFile;

  const AuditImportsUsecase({
    required ArchitectureResolver archResolver,
    required ArchitectureRepository archRepo,
    required List<String> Function(String dirPath, String suffix)
        listFilesWithSuffix,
    required Future<String?> Function(String path) readFile,
  })  : _archResolver = archResolver,
        _archRepo = archRepo,
        _listFilesWithSuffix = listFilesWithSuffix,
        _readFile = readFile;

  Future<AuditImportsResult> execute(
    String projectDir, {
    String? explicitArch,
  }) async {
    final archId =
        await _archResolver.resolve(projectDir, explicit: explicitArch);
    final arch = await _archRepo.getById(archId);
    final rules = arch.importRules ?? const ImportRuleSet();
    final placements = (await _archRepo.getDependencyStack(archId)).placements;
    if (rules.isEmpty && placements.isEmpty) {
      return AuditImportsResult(architectureId: archId, report: null);
    }

    final selfPackage = await _readPackageName(projectDir);

    final libDir = p.join(projectDir, 'lib');
    final files = <DartSourceFile>[];
    for (final relative in _listFilesWithSuffix(libDir, '.dart')) {
      final content = await _readFile(p.join(libDir, relative));
      if (content == null) continue;
      files.add(DartSourceFile(
        path: 'lib/${relative.replaceAll('\\', '/')}',
        imports: ImportAuditor.extractDirectives(content),
      ));
    }

    // 「層に属する」と判定するスコープ: 層名 + 全ルールの dir_pattern。
    // これに属さないパス(core/、main.dart 等)への内部 import は監査対象外。
    final knownScopes = <String>{
      for (final layer in arch.layers) layer.name,
      for (final rule in rules.internalRules) rule.dirPattern,
      for (final rule in rules.externalRules) rule.dirPattern,
    };

    return AuditImportsResult(
      architectureId: archId,
      report: ImportAuditor.audit(
        rules: rules,
        selfPackage: selfPackage,
        files: files,
        knownScopes: knownScopes,
        placements: placements,
        layerNames: [for (final layer in arch.layers) layer.name],
      ),
    );
  }

  /// pubspec.yaml の `name:` を読む(`package:<name>/` を内部依存として
  /// 解決するため)。読めなければ空文字(= package: import はすべて外部扱い)。
  /// `name: "myapp"` のようにクォートされていても正しく取り出す。
  Future<String> _readPackageName(String projectDir) async {
    final content = await _readFile(p.join(projectDir, 'pubspec.yaml'));
    if (content == null) return '';
    final match = RegExp(r'''^name:\s*['"]?([A-Za-z0-9_]+)['"]?\s*$''',
            multiLine: true)
        .firstMatch(content);
    return match?.group(1) ?? '';
  }
}

/// [AuditImportsUsecase] の実行結果。
final class AuditImportsResult {
  final String architectureId;

  /// 監査レポート。アーキテクチャ定義に `import_rules` が無ければ null。
  final ImportAuditReport? report;

  const AuditImportsResult({required this.architectureId, this.report});

  bool get hasRules => report != null;
}

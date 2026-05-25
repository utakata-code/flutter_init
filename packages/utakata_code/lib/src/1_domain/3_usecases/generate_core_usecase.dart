import 'package:path/path.dart' as p;

import '../2_repositories/architecture_repository.dart';

/// Core ディレクトリを生成するユースケース
///
/// `arch_definition.yaml` の `core_modules` に定義されたディレクトリを
/// プロジェクト内に作成する。シェルスクリプト `generate_core.sh` の Dart 版。
class GenerateCoreUsecase {
  final ArchitectureRepository _archRepo;

  /// ディレクトリ作成関数（Infrastructure から注入）
  final Future<void> Function(String path) _ensureDir;

  /// ファイル読み込み関数
  final Future<String?> Function(String path) _readFile;

  const GenerateCoreUsecase({
    required ArchitectureRepository archRepo,
    required Future<void> Function(String path) ensureDir,
    required Future<String?> Function(String path) readFile,
  })  : _archRepo = archRepo,
        _ensureDir = ensureDir,
        _readFile = readFile;

  /// Core ディレクトリを生成して、作成されたパスのリストを返す
  ///
  /// [projectDir]: プロジェクトルートパス
  /// [archId]: アーキテクチャID（null の場合は feature_request.yaml から自動検出）
  Future<List<String>> execute(String projectDir, String? archId) async {
    // アーキテクチャ ID を決定
    final resolvedArchId = archId ?? await _detectArchitectureId(projectDir);

    final arch = await _archRepo.getById(resolvedArchId);
    final created = <String>[];

    for (final module in arch.coreModules) {
      final fullPath = p.join(projectDir, module.path);
      await _ensureDir(fullPath);
      created.add(module.path);
    }

    return created;
  }

  /// feature_request.yaml から architectureId を検出する
  Future<String> _detectArchitectureId(String projectDir) async {
    final path = p.join(projectDir, 'AI', 'specs', 'feature_request.yaml');
    final content = await _readFile(path);
    if (content != null) {
      final pattern = RegExp(r'^architecture:\s*(.+)', multiLine: true);
      final match = pattern.firstMatch(content);
      if (match != null) {
        final value = match.group(1)?.trim().replaceAll(RegExp(r'''["']'''), '');
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return 'clean_architecture';
  }
}

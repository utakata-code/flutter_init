import 'package:path/path.dart' as p;

import '../1_entities/project_status_entity.dart';
import '../2_repositories/architecture_repository.dart';
import '../exceptions/domain_exceptions.dart';

/// プロジェクト状態をディスクスキャンで収集するユースケース
///
/// pubspec.yaml、lib/、core/、AI/specs/ 等を走査して
/// [ProjectStatusEntity] を生成する。
class ScanProjectStatusUsecase {
  final ArchitectureRepository _archRepo;

  /// ファイル読み込み関数（Infrastructure から注入）
  final Future<String?> Function(String path) _readFile;

  /// ファイル存在確認関数
  final bool Function(String path) _fileExists;

  /// ディレクトリ存在確認関数
  final bool Function(String path) _dirExists;

  /// lib/features/ 配下のディレクトリ構造をスキャンする関数
  final Map<String, dynamic> Function(String dirPath) _scanDartFiles;

  const ScanProjectStatusUsecase({
    required ArchitectureRepository archRepo,
    required Future<String?> Function(String path) readFile,
    required bool Function(String path) fileExists,
    required bool Function(String path) dirExists,
    required Map<String, dynamic> Function(String dirPath) scanDartFiles,
  })  : _archRepo = archRepo,
        _readFile = readFile,
        _fileExists = fileExists,
        _dirExists = dirExists,
        _scanDartFiles = scanDartFiles;

  /// プロジェクト状態を収集して返す
  Future<ProjectStatusEntity> execute(String projectDir) async {
    // pubspec.yaml から name / version を取得
    final pubspecPath = p.join(projectDir, 'pubspec.yaml');
    final pubspecExists = _fileExists(pubspecPath);
    var projectName = '';
    var projectVersion = '';
    if (pubspecExists) {
      final content = await _readFile(pubspecPath);
      if (content != null) {
        projectName = _extractYamlValue(content, 'name') ?? '';
        projectVersion = _extractYamlValue(content, 'version') ?? '';
      }
    }

    // lib/ の存在確認
    final libExists = _dirExists(p.join(projectDir, 'lib'));
    final initialized = pubspecExists && libExists;

    // entry_points
    final mainDartExists = _fileExists(p.join(projectDir, 'lib', 'main.dart'));
    final appDartExists = _fileExists(p.join(projectDir, 'lib', 'app.dart'));

    // core modules — arch_definition.yaml から動的取得
    final coreModules = <String, bool>{};
    try {
      final archId = await _detectArchitectureId(projectDir);
      final arch = await _archRepo.getById(archId);
      for (final module in arch.coreModules) {
        final modulePath = p.join(projectDir, module.path);
        coreModules[module.id] = _dirExists(modulePath) &&
            _hasDartFiles(modulePath);
      }
    } on UtakataDomainException {
      // arch_definition.yaml がない/壊れている場合はスキップ
    }

    // documents — テンプレートのみか編集済みか
    // 現行レイアウトは doc/。旧 AI/specs/ は後方互換のフォールバック。
    final specStatus = await _checkDocumentStatus(
      p.join(projectDir, 'doc', 'specs', 'application_specification.md'),
      fallbackPath:
          p.join(projectDir, 'AI', 'specs', 'application_specification.md'),
    );
    final planStatus = await _checkDocumentStatus(
      p.join(projectDir, 'doc', 'specs', 'plan.yaml'),
      fallbackPath: p.join(projectDir, 'AI', 'specs', 'structure_plan.md'),
    );

    // features count
    final featureCount = _countFeatures(
      p.join(projectDir, 'lib', 'features'),
    );

    return ProjectStatusEntity(
      projectName: projectName,
      projectVersion: projectVersion,
      pubspecExists: pubspecExists,
      libExists: libExists,
      initialized: initialized,
      coreModules: coreModules,
      mainDartExists: mainDartExists,
      appDartExists: appDartExists,
      specificationStatus: specStatus,
      structurePlanStatus: planStatus,
      featureCount: featureCount,
      updatedAt: DateTime.now(),
    );
  }

  /// architectureId を検出する(utakata.yaml → plan.yaml → 旧 feature_request)
  Future<String> _detectArchitectureId(String projectDir) async {
    for (final path in [
      p.join(projectDir, 'utakata.yaml'),
      p.join(projectDir, 'doc', 'specs', 'plan.yaml'),
      p.join(projectDir, 'AI', 'specs', 'feature_request.yaml'),
    ]) {
      final content = await _readFile(path);
      if (content == null) continue;
      final archId = _extractYamlValue(content, 'architecture');
      if (archId != null && archId.isNotEmpty) return archId;
    }
    // デフォルト
    return 'clean_architecture';
  }

  /// ドキュメントがテンプレートのままか編集済みかを判定する。
  /// [fallbackPath] は旧レイアウト用(現行パスが無い場合のみ見る)。
  Future<String> _checkDocumentStatus(String path,
      {String? fallbackPath}) async {
    if (!_fileExists(path) && fallbackPath != null) {
      path = fallbackPath;
    }
    if (!_fileExists(path)) return 'not_found';
    final content = await _readFile(path);
    if (content == null) return 'not_found';
    // テンプレートは主要フィールドが空欄のまま
    // "プロジェクト名: " の後が空ならテンプレートのまま
    if (content.contains('プロジェクト名: \n') ||
        content.contains('プロジェクト名: \r\n')) {
      return 'template_only';
    }
    return 'edited';
  }

  /// ディレクトリ内に .dart ファイルが存在するか
  bool _hasDartFiles(String dirPath) {
    final scan = _scanDartFiles(dirPath);
    return scan.containsKey('__files__') ||
        scan.keys.any((k) => k != '__files__');
  }

  /// lib/features/ 配下のフィーチャー数を数える
  ///
  /// permission フォルダ（admin/user/shared）配下のフィーチャーも含める
  int _countFeatures(String featuresDir) {
    if (!_dirExists(featuresDir)) return 0;
    final scan = _scanDartFiles(featuresDir);
    var count = 0;
    for (final entry in scan.entries) {
      if (entry.key == '__files__') continue;
      final child = entry.value;
      if (child is Map) {
        // permission フォルダ（admin/user/shared）の場合、その子がフィーチャー
        if (_isPermissionFolder(entry.key)) {
          count += child.keys.where((k) => k != '__files__').length;
        } else {
          // direct フィーチャー
          count++;
        }
      }
    }
    return count;
  }

  bool _isPermissionFolder(String name) {
    return name == 'admin' || name == 'user' || name == 'shared';
  }

  /// YAML テキストからトップレベルの値を簡易抽出する
  String? _extractYamlValue(String yamlContent, String key) {
    final pattern = RegExp('^$key:\\s*(.+)', multiLine: true);
    final match = pattern.firstMatch(yamlContent);
    if (match == null) return null;
    return match.group(1)?.trim().replaceAll(RegExp(r'''["']'''), '');
  }
}

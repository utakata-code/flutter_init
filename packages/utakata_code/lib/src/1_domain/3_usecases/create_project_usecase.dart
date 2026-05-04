import '../1_entities/project_spec_entity.dart';
import '../2_repositories/architecture_repository.dart';
import '../2_repositories/template_repository.dart';
import '../messages/cli_messages.dart';

/// Flutter プロジェクトを作成するユースケース
///
/// 以下の手順で実行される:
/// 1. flutter create コマンドを実行
/// 2. アーキテクチャ定義に基づく lib/core/ 基盤を生成
/// 3. プロジェクトテンプレート（.agent/, AI/）を展開
class CreateProjectUsecase {
  final ArchitectureRepository _archRepo;
  final TemplateRepository _templateRepo;
  final CliMessages _msg;

  /// flutter create を実行する関数（Infrastructure から注入）
  final Future<bool> Function({
    required String appName,
    required String projectName,
    required String org,
    required String platforms,
    required String description,
  }) _runFlutterCreate;

  /// ファイル書き込み関数（Infrastructure から注入）
  final Future<void> Function(String path, String content) _writeFile;
  final Future<void> Function(String path) _ensureDir;

  const CreateProjectUsecase({
    required ArchitectureRepository archRepo,
    required TemplateRepository templateRepo,
    required CliMessages msg,
    required Future<bool> Function({
      required String appName,
      required String projectName,
      required String org,
      required String platforms,
      required String description,
    }) runFlutterCreate,
    required Future<void> Function(String path, String content) writeFile,
    required Future<void> Function(String path) ensureDir,
  })  : _archRepo = archRepo,
        _templateRepo = templateRepo,
        _msg = msg,
        _runFlutterCreate = runFlutterCreate,
        _writeFile = writeFile,
        _ensureDir = ensureDir;

  /// プロジェクトを作成する
  Future<void> execute(ProjectSpecEntity spec) async {
    // 1. flutter create を実行
    final success = await _runFlutterCreate(
      appName: spec.appName,
      projectName: spec.projectName,
      org: spec.org,
      platforms: spec.platforms,
      description: spec.description,
    );
    if (!success) {
      throw Exception(_msg.flutterCreateFailed);
    }

    // 2. アーキテクチャ定義を取得
    await _archRepo.getById(spec.architectureId);

    // 3. プロジェクトテンプレートを展開（.agent/, AI/ 等）
    final templates = await _templateRepo.getProjectTemplates(spec.architectureId);
    final variables = {'project_name': spec.projectName, 'ProjectName': spec.projectName};

    for (final template in templates) {
      final resolvedPath = template.resolvedPath(variables);
      final targetPath = '${spec.appName}/$resolvedPath';
      await _ensureDir(targetPath.substring(0, targetPath.lastIndexOf('/')));
      await _writeFile(targetPath, template.resolvedContent(variables));
    }
  }
}
